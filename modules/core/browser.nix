{ ... }:
{
    environment.systemPackages = [
        (callPackage ../../pkgs/helium {})
    ];
}
