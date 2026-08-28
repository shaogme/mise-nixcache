{ config, pkgs, lib, ... }:

let
  cfg = config.programs.mise;
  root = import ../default.nix { inherit pkgs; };
in
{
  options.programs.mise = {
    enable = lib.mkEnableOption "mise: Dev tools, env vars, and tasks in one CLI";

    package = lib.mkOption {
      type = lib.types.package;
      default = root.mise;
      defaultText = lib.literalExpression "(import ./default.nix { inherit pkgs; }).mise";
      description = "The mise package to install.";
    };

    enableSubstituter = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to automatically configure the binary cache substituter and trusted public key for mise.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];

    nix.settings = lib.mkIf cfg.enableSubstituter {
      extra-substituters = [ "http://localhost:37515" ];
      extra-trusted-substituters = [ "http://localhost:37515" ];
      extra-trusted-public-keys = [ "mise-cache-1:wc5EMEDHcUyzRUTm6EuRKp0hhsJiKB2lfEi3ZOT1ahg=" ];
    };
  };
}
