// Keep cached plugin copies writable without changing Nix inputs or symlink targets.
const fs = require("node:fs");
const path = require("node:path");

const branch = /if\("win32"!==(?<os>(?:[\w$]+\(\)|process))\.platform\)return void await (?<fs>[\w$]+)\(\)\.cp\((?<source>[\w$]+),(?<destination>[\w$]+),\{recursive:!0,verbatimSymlinks:!0\}\);/g;

function findCopyBranch(source) {
  const matches = [...source.matchAll(branch)];
  if (matches.length !== 1) {
    throw new Error(`Expected one bundled plugin copy branch, found ${matches.length}`);
  }
  const match = matches[0];
  if (!source.slice(match.index + match[0].length, match.index + match[0].length + 350)
    .includes("copyDirectoryAllowDecryptedDestinationOnEncryptionFailure")) {
    throw new Error("Copy branch is not the expected bundled marketplace helper");
  }
  return match;
}

function patch(source) {
  const match = findCopyBranch(source);
  const api = `${match.groups.fs}()`;
  const replacement = `if("win32"!==${match.groups.os}.platform){
    await ${api}.cp(${match.groups.source},${match.groups.destination},{recursive:true,verbatimSymlinks:true});
    await (async function nixWritablePluginCopy(root){
      const stat=await ${api}.lstat(root);
      if(stat.isSymbolicLink()||(!stat.isDirectory()&&!stat.isFile()))return;
      await ${api}.chmod(root,(stat.mode&0o7777)|0o200);
      if(stat.isDirectory())for(const name of await ${api}.readdir(root))
        await nixWritablePluginCopy(require("node:path").join(root,name));
    })(${match.groups.destination});
    return;
  }`;
  return source.slice(0, match.index) + replacement + source.slice(match.index + match[0].length);
}

function patchDirectory(directory) {
  const candidates = fs.readdirSync(directory)
    .filter(name => name.endsWith(".js"))
    .map(name => path.join(directory, name))
    .filter(file => fs.readFileSync(file, "utf8").includes("plugin_marketplace_folder_write_failed"));
  if (candidates.length !== 2) {
    throw new Error(`Expected two marketplace bundles, found ${candidates.length}`);
  }
  // Validate both before changing either one.
  const patched = candidates.map(file => [file, patch(fs.readFileSync(file, "utf8"))]);
  for (const [file, source] of patched) {
    fs.writeFileSync(file, source);
    console.log(`Patched bundled plugin copy permissions in ${file}`);
  }
}

module.exports = { findCopyBranch, patch, patchDirectory };
if (require.main === module) {
  if (process.argv.length !== 3) throw new Error("Usage: patch-plugin-permissions.cjs BUILD_DIRECTORY");
  patchDirectory(process.argv[2]);
}
