{ ... }:
{
  programs.git = {
    enable = true;

    settings = {
      user = {
        name = "Paul Koeck";
        email = "paul@koeck.dev";
      };

      init.defaultBranch = "main";
      merge.conflictstyle = "diff3";
      diff.colorMoved = "default";
      color.ui = true;
    };
  };
}
