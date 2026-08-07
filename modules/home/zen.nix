{
  pkgs,
  inputs,
  lib,
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

  sharedMods = [
    "e122b5d9-d385-4bf8-9971-e137809097d0" # No Top Sites
    "4ab93b88-151c-451b-a1b7-a1e0e28fa7f8" # No Sidebar Scrollbar
  ];

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

  zenFolderIcon = "chrome://browser/skin/zen-icons/selectable/folder.svg";

  mkSpaceTheme = r: g: b: {
    type = "gradient";
    colors = [
      {
        red = r;
        green = g;
        blue = b;
        algorithm = "floating";
        type = "explicit-lightness";
        lightness = 50;
      }
    ];
    # Keep it a subtle tint — high opacity floods the whole chrome with the color.
    opacity = 0.2;
    texture = 0.3;
  };

  bookmarkBarNever = {
    "browser.toolbars.bookmarks.visibility" = "never";
  };

  authfill = inputs.firefox-addons.lib."x86_64-linux".buildFirefoxXpiAddon {
    pname = "authfill";
    version = "1.2.0";
    addonId = "extension@authfill.com";
    url = "https://addons.mozilla.org/firefox/downloads/file/4683108/authfill-1.2.0.xpi";
    sha256 = "47e9af2f7de140942587d45f427e0950c8fea79995b83d575958a2fae63bc662";
    mozPermissions = [
      "storage"
      "tabs"
      "notifications"
      "clipboardWrite"
    ];
    meta = with lib; {
      homepage = "https://authfill.com";
      description = "Verify your email with one click";
      license = licenses.gpl3Only;
      platforms = platforms.all;
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
      Certificates.Install = [
        "${inputs.otark-ca}/otark-root-ca.crt"
      ];

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
      settings = mkSettings "#2563eb" bookmarkBarNever;

      mods = sharedMods;
      keyboardShortcutsVersion = 20;
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

      extensions.packages =
        with pkgs.firefox-addons;
        [
          ublock-origin
          onepassword-password-manager
          sponsorblock
          youtube-shorts-block
          cookie-editor
        ]
        ++ [ authfill ];
    };

    profiles.otark =
      let
        # Three themed spaces (workspaces) for the Otark work context. IDs are
      # stable UUIDs (Nix can't generate randomness) — never change them, or Zen
      # treats it as a different space and loses the association.
      spaces = {
        "Dev" = {
          id = "b1ddf3c2-4e26-4861-8cf6-0b2591ef1467";
          position = 1000;
          icon = "💻";
          theme = mkSpaceTheme 46 125 70; # green
        };
        "Deployed" = {
          id = "04e80501-c79b-4133-a1cb-c36371b3c57f";
          position = 2000;
          icon = "🚀";
          theme = mkSpaceTheme 46 125 70; # green
        };
        "Ops" = {
          id = "1eb5eb41-267b-4b98-9f80-901b1cabf98a";
          position = 3000;
          icon = "📊";
          theme = mkSpaceTheme 46 125 70; # green
        };
      };

      # Container for production admin: isolates www.otark.team's cookies/session
      # from staging & dev admin, so a prod login can't bleed across environments
      # (and "am I in prod?" is unambiguous — the tab gets a red container stripe).
      containers = {
        "Prod Admin" = {
          id = 10; # userContextId — kept above Firefox's 1–4 default containers
          color = "red";
          icon = "fence";
        };
      };

      # Folder helper: a pin group bound to a space.
      mkFolder = id: workspace: position: {
        inherit id position workspace;
        isGroup = true;
        isFolderCollapsed = false;
        editedTitle = true;
        folderIcon = zenFolderIcon;
      };
      # Leaf pin helper: a tab pinned inside a folder within a space.
      mkPin = id: workspace: parent: position: url: {
        inherit
          id
          url
          position
          workspace
          ;
        folderParentId = parent;
      };

      pins = {
        # ── Dev space ── local app + admin, source, tickets ────────────────
        "Dev / Local" = mkFolder "c3b58cdc-840f-415d-b8c8-0fb8240f9613" spaces."Dev".id 100;
        "App (local)" =
          mkPin "d7e84c78-e1d5-4a37-b899-8b87354afcc1" spaces."Dev".id pins."Dev / Local".id 101
            "http://localhost:3000";
        "Admin (local)" =
          mkPin "90b8ec21-30f1-49d1-9e66-6b35b120048d" spaces."Dev".id pins."Dev / Local".id 102
            "http://localhost:3001";
        "Dev / Code & Tickets" = mkFolder "4b31a33b-d5e6-4ca7-8aa4-c4af29cdc4dc" spaces."Dev".id 110;
        "GitLab" =
          mkPin "76acc067-7661-4498-9b19-8e4c4c00f3ca" spaces."Dev".id pins."Dev / Code & Tickets".id 111
            "https://gitlab.otark.team";
        "Linear" =
          mkPin "f5a33897-716e-4909-9abf-90c64d3890e3" spaces."Dev".id pins."Dev / Code & Tickets".id 112
            "https://linear.app";

        # ── Deployed space ── app + admin across environments ──────────────
        "Deployed / App" = mkFolder "fd6eaf62-1283-410f-84da-f950c83cdc79" spaces."Deployed".id 200;
        "App — Dev" =
          mkPin "6e640f4b-2172-4310-976e-02d7074c4324" spaces."Deployed".id pins."Deployed / App".id 201
            "https://app.otark.com";
        "App — Staging" =
          mkPin "41901113-0e64-4ed7-aa79-28f812448fce" spaces."Deployed".id pins."Deployed / App".id 202
            "https://app.otark.dev";
        "Deployed / Admin" = mkFolder "90d431da-06ae-4140-a907-12fad12cf8d1" spaces."Deployed".id 210;
        "Admin — Staging" =
          mkPin "3283687f-a285-4c8c-879e-2643c53585c6" spaces."Deployed".id pins."Deployed / Admin".id 211
            "https://staging.otark.team";
        "Admin — Production" =
          mkPin "6964d71e-56f5-4088-b804-26e3913737d2" spaces."Deployed".id pins."Deployed / Admin".id 212
            "https://www.otark.team"
          // {
            container = containers."Prod Admin".id;
          }; # isolated prod session

        # ── Ops space ── observability + secrets ───────────────────────────
        "Grafana" = {
          id = "5c52e863-698f-4627-8c79-cdd68ff18d5e";
          url = "https://grafana.otark.team";
          workspace = spaces."Ops".id;
          position = 301;
        };
        "Vault" = {
          id = "b786f08e-7fa3-431e-b01c-13c82133b92d";
          url = "https://vault.ops.otark.team";
          workspace = spaces."Ops".id;
          position = 302;
        };
        "Workflows" = {
          id = "560308e3-a45f-45fe-b151-7b17367bdc4e";
          url = "https://workflows.otark.team";
          workspace = spaces."Ops".id;
          position = 303;
        };
      };
      in
      {
        id = 1;
      name = "Otark";
      settings = mkSettings "#2e7d46" bookmarkBarNever; # green

      spacesForce = true;
      pinsForce = true;
      pinsForceAction = "remove";
      inherit spaces pins containers;

      mods = sharedMods;
      keyboardShortcutsVersion = 19;
      keyboardShortcuts = sharedKeyboardShortcuts;

      extensions = {
        packages = with pkgs.firefox-addons; [
          ublock-origin
          onepassword-password-manager
        ];
      };
      };
  };

  xdg.desktopEntries = {
    zen-personal = {
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

    zen-otark = {
      name = "Zen (Otark)";
      genericName = "Web Browser";
      exec = "zen-beta -P Otark %U";
      icon = "zen-browser";
      terminal = false;
      categories = [
        "Network"
        "WebBrowser"
      ];
    };
  };
}
