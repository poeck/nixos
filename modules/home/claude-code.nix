{
  pkgs,
  username,
  lib,
  ...
}:
let
  sandboxRuntimePkg = pkgs.sandbox;
  seccompPath = "${sandboxRuntimePkg}/lib/node_modules/@anthropic-ai/sandbox-runtime/vendor/seccomp/x64";
  claudeSeccompDir = "/home/${username}/.local/share/claude-seccomp";
in
{
  home.file = {
    # Symlinks for direct path configuration
    ".local/share/claude-seccomp/apply-seccomp".source = "${seccompPath}/apply-seccomp";
    ".local/share/claude-seccomp/unix-block.bpf".source = "${seccompPath}/unix-block.bpf";

    # Symlink the entire package to ~/.npm-global where sandbox-runtime looks for global installs
    ".npm-global/lib/node_modules/@anthropic-ai/sandbox-runtime".source =
      "${sandboxRuntimePkg}/lib/node_modules/@anthropic-ai/sandbox-runtime";

    ".claude/settings.json".text = builtins.toJSON {
      enabledPlugins = {
        "context7@claude-plugins-official" = true;
        "greptile@claude-plugins-official" = true;
        "security-guidance@claude-plugins-official" = true;
        "typescript-lsp@claude-plugins-official" = true;
        "figma@claude-plugins-official" = true;
        "frontend-design@claude-plugins-official" = true;
        "feature-dev@claude-plugins-official" = true;
        "claude-code-wakatime@wakatime" = true;
      };
      sandbox = {
        enabled = true;
        autoAllowBashIfSandboxed = true;
        seccomp = {
          bpfPath = "${claudeSeccompDir}/unix-block.bpf";
          applyPath = "${claudeSeccompDir}/apply-seccomp";
        };
      };
    };
  };
}
