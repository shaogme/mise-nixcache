{ pkgs ? import (import ./npins).nixpkgs { }
, doCheck ? false
}:

let
  sources = import ./npins;
in
rec {
  # 构建包
  mise = (pkgs.callPackage "${sources.mise}/default.nix" { }).overrideAttrs (oldAttrs: {
    inherit doCheck;
  });
  default = mise;

  # 结构化 packages 属性集
  packages = {
    inherit mise default;
  };

  # NixOS 模块
  nixosModules = {
    default = import ./nix/module.nix;
    mise = import ./nix/module.nix;
  };

  # Overlay 定义
  overlays = {
    default = final: prev: {
      mise = (import ./default.nix { pkgs = prev; inherit doCheck; }).mise;
    };
  };
}
