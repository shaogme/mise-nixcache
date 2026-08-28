{ pkgs ? import (import ../npins).nixpkgs { } }:

let
  root = import ../default.nix { inherit pkgs; };
  
  # NixOS 模块静态评估
  evalModule = import (pkgs.path + "/nixos/lib/eval-config.nix") {
    modules = [
      root.nixosModules.default
      {
        programs.mise.enable = true;
      }
    ];
    inherit pkgs;
  };
in
{
  # 软件包派生元数据静态求值检查
  eval-check = pkgs.runCommand "eval-check-mise" { } ''
    echo "Checking mise derivation metadata..."
    if [ "${root.mise.pname}" != "mise" ]; then
      echo "Error: pname is not mise" >&2
      exit 1
    fi
    if [ -z "${root.mise.version}" ]; then
      echo "Error: version is empty" >&2
      exit 1
    fi
    echo "Static evaluation check passed: ${root.mise.name}"
    touch $out
  '';

  # NixOS 模块静态配置求值检查
  module-eval-check = pkgs.runCommand "eval-check-module" { } ''
    echo "Checking NixOS module evaluation..."
    if [ "${toString evalModule.config.programs.mise.enable}" != "1" ] && [ "${toString evalModule.config.programs.mise.enable}" != "true" ]; then
      echo "Error: programs.mise.enable is not true" >&2
      exit 1
    fi
    echo "NixOS module static check passed."
    touch $out
  '';

  # 虚拟机运行期可用性测试 (通过 NixOS 模块加载)
  vmtest = import ./vmtest.nix { inherit pkgs; };
}
