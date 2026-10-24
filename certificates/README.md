The public Otark root CA can be placed here as `otark-root-ca.crt` (PEM format)
and added to Git. It is optional: without it, the system builds normally and
uses the standard public certificate authorities. Otark's private HTTPS sites
will require the real certificate before their certificate chains can be trusted.

Include only the public root certificate here, never a private key. There is no
absolute local-path flake input or required `local/otark-ca` workaround.
