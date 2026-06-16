{
  pkgs,
  inputs,
  ...
}:
let
  commonSettings = {
    "browser.urlbar.suggest.quicksuggest.sponsored" = false;
    "browser.urlbar.suggest.quicksuggest.nononsense" = true;
    "media.ffmpeg.vaapi.enabled" = true;
    "devtools.netmonitor.persistlog" = true;
    "browser.aboutConfig.showWarning" = false;
    "browser.compactmode.show" = true;
    "toolkit.legacyUserProfileCustomizations.stylesheets" = true;

    "gfx.webrender.all" = true;
    "browser.cache.disk.enable" = true;
    "browser.cache.memory.enable" = true;
    "browser.cache.memory.capacity" = 524288;
    "browser.sessionstore.interval" = 1800000; # 30 mins in ms
    "toolkit.cosmeticAnimations.enabled" = false;
    "accessibility.force_disabled" = 1;

    "general.smoothScroll" = true;
    "general.smoothScroll.mouseWheel.durationMinMS" = 20;
    "general.smoothScroll.mouseWheel.durationMaxMS" = 45;
    "general.smoothScroll.pixels.durationMinMS" = 20;
    "general.smoothScroll.pixels.durationMaxMS" = 45;
    "general.smoothScroll.lines.durationMinMS" = 20;
    "general.smoothScroll.lines.durationMaxMS" = 45;
    "general.smoothScroll.pages.durationMinMS" = 30;
    "general.smoothScroll.pages.durationMaxMS" = 60;
  };

  mkSettings =
    accent: extra:
    commonSettings
    // {
      "zen.theme.accent-color" = accent;
    }
    // extra;

  bookmarkBarAlways = {
    "browser.toolbars.bookmarks.visibility" = "always";
  };

  sharedMods = [
    "e122b5d9-d385-4bf8-9971-e137809097d0" # No Top Sites
    "4ab93b88-151c-451b-a1b7-a1e0e28fa7f8" # No Sidebar Scrollbar
  ];

  sharedKeyboardShortcutsVersion = 19;
  sharedKeyboardShortcuts = [
    {
      id = "zen-compact-mode-toggle";
      key = "c";
      modifiers = {
        control = true;
        alt = true;
      };
    }
    {
      id = "key_quitApplication";
      disabled = true;
    }
  ];

  sharedSearch = {
    force = true;
    default = "google";
    engines = {
      "Nix Packages" = {
        urls = [
          { template = "https://search.nixos.org/packages?channel=unstable&query={searchTerms}"; }
        ];
        icon = "https://nixos.org/favicon.png";
        updateInterval = 24 * 60 * 60 * 1000;
        definedAliases = [
          "@np"
          "np"
        ];
      };
      "NPM" = {
        urls = [
          { template = "https://www.npmjs.com/search?q={searchTerms}"; }
        ];
        icon = "https://static-production.npmjs.com/58a19602036db1daee0d7863c94673a4.png";
        updateInterval = 24 * 60 * 60 * 1000;
        definedAliases = [
          "@npm"
          "npm"
        ];
      };
      "GitHub" = {
        urls = [
          { template = "https://github.com/search?q={searchTerms}&type=repositories"; }
        ];
        icon = "https://github.githubassets.com/favicons/favicon.svg";
        updateInterval = 24 * 60 * 60 * 1000;
        definedAliases = [
          "@gh"
          "gh"
        ];
      };

      "bing".metaData.hidden = true;
      "ebay".metaData.hidden = true;
    };
  };
in
{
  imports = [ inputs.zen-browser.homeModules.beta ];

  programs.zen-browser = {
    enable = true;

    policies = {
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      DisablePocket = true;
      DisableFirefoxAccounts = true;
      DisableAccounts = true;
      DisableFirefoxScreenshots = true;
      OverrideFirstRunPage = "";
      OverridePostUpdatePage = "";
      DontCheckDefaultBrowser = true;
      SearchBar = "unified";

      Certificates = { };

      EnableTrackingProtection = {
        Value = true;
        Locked = true;
        Cryptomining = true;
        Fingerprinting = true;
      };
      HttpsOnlyMode = "enabled";

      UserMessaging = {
        ExtensionRecommendations = false;
        FeatureRecommendations = false;
        UrlbarInterventions = false;
        SkipOnboarding = true;
        MoreFromMozilla = false;
      };

      FirefoxHome = {
        Search = true;
        TopSites = true;
        SponsoredTopSites = false;
        Highlights = false;
        Pocket = false;
        SponsoredPocket = false;
        Snippets = false;
      };

      SearchSuggestEnabled = true;
      FirefoxSuggest = {
        WebSuggestions = false;
        SponsoredSuggestions = false;
        ImproveSuggest = false;
      };

      PictureInPicture.Enabled = false;
    };

    profiles.personal = {
      id = 0;
      name = "Personal";
      isDefault = true;
      settings = mkSettings "#2563eb" bookmarkBarAlways;

      search = sharedSearch;

      mods = sharedMods;
      keyboardShortcutsVersion = sharedKeyboardShortcutsVersion;
      keyboardShortcuts = sharedKeyboardShortcuts;

      bookmarks = {
        force = true;
        settings = [
          {
            name = "Toolbar";
            toolbar = true;
            bookmarks = [
              {
                name = "GitHub";
                bookmarks = [
                  {
                    name = "Paul";
                    url = "https://github.com/paul";
                  }
                ];
              }
              {
                name = "YouTube";
                url = "https://youtube.com/";
              }
            ];
          }
        ];
      };

      extensions.packages = with pkgs.firefox-addons; [
        ublock-origin
        onepassword-password-manager
        sponsorblock
        youtube-shorts-block
      ];
    };
  };

  xdg.desktopEntries.zen-personal = {
    name = "Zen (Personal)";
    genericName = "Web Browser";
    exec = "zen-beta -P Personal %U";
    icon = "zen-browser";
    terminal = false;
    categories = [
      "Network"
      "WebBrowser"
    ];
  };
}
