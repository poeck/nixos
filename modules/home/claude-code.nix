{
  pkgs,
  ...
}:
let
  sandboxRuntimePkg = pkgs.sandbox;
  seccompPath = "${sandboxRuntimePkg}/lib/node_modules/@anthropic-ai/sandbox-runtime/vendor/seccomp/x64";
in
{
  home.file = {
    # Symlinks for direct path configuration
    ".local/share/claude-seccomp/apply-seccomp".source = "${seccompPath}/apply-seccomp";
    ".local/share/claude-seccomp/unix-block.bpf".source = "${seccompPath}/unix-block.bpf";

    # Symlink the entire package to ~/.npm-global where sandbox-runtime looks for global installs
    ".npm-global/lib/node_modules/@anthropic-ai/sandbox-runtime".source =
      "${sandboxRuntimePkg}/lib/node_modules/@anthropic-ai/sandbox-runtime";
  };
}
