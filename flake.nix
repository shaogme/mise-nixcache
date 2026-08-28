{
  description = "mise-nixcache: Binary cache and Flake module for mise";

  nixConfig = {
    extra-substituters = [ "http://localhost:37515" ];
    extra-trusted-public-keys = [ "mise-cache-1:wc5EMEDHcUyzRUTm6EuRKp0hhsJiKB2lfEi3ZOT1ahg=" ];
  };

  outputs = { self }:
    let
      sources = import ./npins;
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      lib = import "${sources.nixpkgs}/lib";
      forAllSystems = f: lib.genAttrs systems (system: f system);
      defaultForSystem = system:
        let
          pkgs = import sources.nixpkgs { inherit system; };
        in
        import ./default.nix { inherit pkgs; };
    in {
      packages = forAllSystems (system: (defaultForSystem system).packages);

      overlays = (import ./default.nix { }).overlays;

      nixosModules = (import ./default.nix { }).nixosModules;
    };
}
