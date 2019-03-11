{ pkgs }:

with builtins;

let
  usePackageNameExtract =
    pkgs.runCommand "use-package-name-extract" { nativeBuildInputs = [ pkgs.emacs ]; }
                    ''
                      mkdir $out
                      cp ${./use-package-name-extract.el} "$out/use-package-name-extract.el"
                      emacs --no-site-file --batch \
                            --eval "(byte-compile-file \"$out/use-package-name-extract.el\")"
                    '';
                                      
  packageList = dotEmacs:
    pkgs.runCommand "usePackagePackageList" { nativeBuildInputs = [ pkgs.emacs ]; }
                    ''
                      emacs ${dotEmacs} --no-site-file --batch \
                                        -l ${usePackageNameExtract}/use-package-name-extract.el \
                                        -f print-packages 2> $out
                    '';
in
rec {
  parsePackages = dotEmacs:
    filter (x: x != "")
           (filter (x: typeOf x == "string")
                   (split "\n"
                          (readFile (packageList dotEmacs))));
  
  emacsWithUsePackagePkgs = {
    config,
    package ? pkgs.emacs,
    override ? (epkgs: epkgs),
    extraPackages ? []
  }:
  let
    packages = parsePackages config;
    emacsPackages = pkgs.emacsPackagesNgGen package;
    emacsWithPackages = emacsPackages.emacsWithPackages;
  in emacsWithPackages (epkgs:
                          let
                            overridden = override epkgs;
                          in map (name: if hasAttr name overridden then
                                          overridden.${name}
                                        else
                                          null)
                                 (packages ++ [ "use-package" ] ++ extraPackages ));


}
