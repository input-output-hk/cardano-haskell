let default-compiler = "ghc865"; in
{ compiler         ? default-compiler
}@args:
(import ./nix/packages.nix args).shell
