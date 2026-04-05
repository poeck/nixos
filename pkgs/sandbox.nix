{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
}:

buildNpmPackage rec {
  pname = "anthropic-sandbox-runtime";
  version = "0.0.35";

  src = fetchFromGitHub {
    owner = "anthropic-experimental";
    repo = "sandbox-runtime";
    rev = "4fad8fa35db3f09958db1df401b30bd00402b611";
    hash = "sha256-wUxzU4+5YUK4MGn8UPrSVkjAzZGdzIG+TOjcFWPuU/E=";
  };

  npmDepsHash = "sha256-1BoVEFm7wxIYgM6wS5Pl1wam17eB4eJWobJHDkvGCa4=";

  npmBuildScript = "build";

  meta = {
    description = "Anthropic sandbox runtime for Claude Code";
    homepage = "https://github.com/anthropic-experimental/sandbox-runtime";
    license = lib.licenses.asl20;
    mainProgram = "srt";
  };
}
