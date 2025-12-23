{ inputs, ... }:
{
  services.keyd = {
    enable = true;
    keyboards = {
      default = {
        ids = [ "*" ];

        settings = {

          main = {
            # Trigger symbol layer via capslock
            capslock = "layer(symbols)";

            # Trigger rightalt layer via rightalt
            rightalt = "layer(rightalt)";

            # Remap <> button to escape
            "102nd" = "esc";

            # Unmapped / special
            "`" = "S-f12";
          };

          shift = {
            # Intentionally unmapped keys (commented out in original)
          };

          rightalt = {
            # Intentionally unmapped keys (commented out in original)
          };

          symbols = {
            # ============================
            # First row
            # ============================
            q = "`";
            w = "S-102nd";
            e = "G-9";
            r = "G-0";
            t = "S-9";
            y = "S-4";
            u = "S-/";
            i = "/";
            o = "S-0";
            p = "]";
            "[" = "S-=";

            # ============================
            # Second row
            # ============================
            a = "S-`";
            s = "S-6";
            d = "S-1";
            f = "S--";
            g = "S-5";
            h = "S-7";
            j = "S-8";
            k = "G-7";
            l = "G-8";
            ";" = "102nd";
            "'" = "G--";

            # ============================
            # Third row
            # ============================
            z = "S-3";
            x = "G-e";
            c = "G-q";
            v = "G-]";
            b = "S-]";
            n = "S-2";
            m = "S-\\";
            "," = "S-,";
            "." = "S-.";
            "/" = "G-102nd";
          };
        };
      };
    };
  };
}
