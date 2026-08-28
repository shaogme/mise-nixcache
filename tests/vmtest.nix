{ pkgs ? import (import ../npins).nixpkgs { } }:

let
  root = import ../default.nix { inherit pkgs; };
in
pkgs.testers.nixosTest {
  name = "mise-module-test";

  nodes.machine = { ... }: {
    imports = [ root.nixosModules.default ];
    programs.mise.enable = true;
  };

  testScript = ''
    machine.wait_for_unit("multi-user.target")

    # 1. 验证 mise 命令可执行且版本输出正常
    version_output = machine.succeed("mise --version")
    print(f"mise version: {version_output.strip()}")
    assert len(version_output.strip()) > 0 and "linux" in version_output

    # 2. 验证 mise doctor 诊断命令可正常运行并输出诊断信息
    status, doctor_output = machine.execute("mise doctor")
    print(f"mise doctor (exit code {status}):\n{doctor_output.strip()}")
    assert "build_info:" in doctor_output

    # 3. 验证 mise exec 执行命令
    exec_output = machine.succeed("mise exec -- echo 'mise is functional in NixOS VM'")
    assert "mise is functional in NixOS VM" in exec_output

    # 4. 验证 mise settings 配置查看
    machine.succeed("mise settings")

    # 5. 验证 NixOS 模块自动配置的 Nix 替代器与公钥
    nix_conf = machine.succeed("cat /etc/nix/nix.conf")
    print(f"nix.conf content:\n{nix_conf}")
    assert "37515" in nix_conf
    assert "mise-cache-1" in nix_conf
  '';
}
