{ runCommand, emacs, emacsPackagesNgGen }:

with builtins;

let
  usePackageNameExtract =
    runCommand "use-package-name-extract" { nativeBuildInputs = [ emacs ]; }
               ''
                 mkdir $out
                 cp ${./use-package-name-extract.el} "$out/use-package-name-extract.el"
                 emacs --no-site-file --batch \
                       --eval "(byte-compile-file \"$out/use-package-name-extract.el\")"
               '';

  packageList = dotEmacs:
    runCommand "usePackagePackageList" { nativeBuildInputs = [ emacs ]; }
               ''
                 emacs ${dotEmacs} --no-site-file --batch \
                                   -l ${usePackageNameExtract}/use-package-name-extract.el \
                                   -f print-packages 2> $out
               '';

  parsePackages = dotEmacs:
    filter (x: x != "")
           (filter (x: typeOf x == "string")
                   (split "\n"
                          (readFile (packageList dotEmacs))));
in
rec {
  usePackagePkgs = {
    config,
    override ? (epkgs: epkgs),
    extraPackages ? []
  }:
  (epkgs:
    let
      packages = parsePackages config;
      overridden = override epkgs;
    in map (name: if hasAttr name overridden then
                    overridden.${name}
                  else
                    null)
           (packages ++ [ "use-package" ] ++ extraPackages ));

  emacsWithUsePackagePkgs = {
    config,
    override ? (epkgs: epkgs),
    extraPackages ? []
  }:
  let
    emacsPackages = emacsPackagesNgGen emacs;
    emacsWithPackages = emacsPackages.emacsWithPackages;
  in emacsWithPackages (usePackagePkgs { inherit config override extraPackages; });
}
