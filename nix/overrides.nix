pkgs: new: old:
with new; with pkgs.haskell.lib;
let
  local
    = repo: path: cabalExtras:
      doJailbreak
      (old.callCabal2nixWithOptions repo path cabalExtras {});
  cabal2nix
    = owner: repo: rev: sha256: cabalExtras:
      doJailbreak (old.callCabal2nixWithOptions repo (pkgs.fetchFromGitHub {
        inherit owner repo rev sha256;
      }) cabalExtras {});
  iohk
    = repo: rev: s: subdir: cabal2nix "input-output-hk" repo rev s "--subpath ${subdir}";
in {
}
