{ ... }:
{
  # Helium reads Chromium's policy directory on Linux; the directory name does
  # not require installing the Chromium browser.
  environment.etc."chromium/policies/managed/helium-search.json".text = builtins.toJSON {
    DefaultSearchProviderEnabled = true;
    DefaultSearchProviderName = "Google";
    DefaultSearchProviderKeyword = "google.com";
    DefaultSearchProviderSearchURL = "https://www.google.com/search?q={searchTerms}";
  };
}
