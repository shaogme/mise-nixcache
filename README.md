# mise 安装指南

本仓库为 mise 提供了预编译的 Nix 二进制缓存。通过本项目，您可以在不耗费本地 CPU 和内存进行 Rust/LLVM 源码编译的情况下，秒级拉取并安装最新版本的 mise。

---

## 1. 缓存公钥信息

本仓库构建发布的二进制包已启用非对称加密签名，公钥信息如下：

```
mise-cache-1:wc5EMEDHcUyzRUTm6EuRKp0hhsJiKB2lfEi3ZOT1ahg=
```

---

## 2. 快速开始：配置二进制缓存

在使用本仓库安装 mise 之前，建议先配置二进制缓存源，以享受免编译的加速下载体验。

### 步骤 1：启动本地缓存代理

由于 GitHub Container Registry (GHCR) 存储采用 OCI 协议，需要通过轻量级代理服务进行协议转换（极低内存占用，流式传输）：

```bash
# 启动本地代理（后台常驻）
nix run --accept-flake-config github:shaogme/nixcache-oci#cache-proxy-bin -- --repo shaogme/mise-nixcache &
```

### 步骤 2：在 nix.conf 中添加缓存源

编辑您的 Nix 配置文件（用户级别 `~/.config/nix/nix.conf` 或系统级别 `nix.conf`），追加以下内容：

```ini
extra-substituters = http://localhost:37515
extra-trusted-substituters = http://localhost:37515
extra-trusted-public-keys = mise-cache-1:wc5EMEDHcUyzRUTm6EuRKp0hhsJiKB2lfEi3ZOT1ahg=
```

---

## 3. 安装 mise

完成缓存配置后，您可以根据自己的 Nix 使用习惯选择以下任一方式安装 mise：

### 方式一：使用 Flake NixOS 模块全局配置（推荐，Flake 体系）

在您的系统 `flake.nix` 中引入本仓库并启用模块：

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    mise-nixcache.url = "github:shaogme/mise-nixcache";
  };

  outputs = { self, nixpkgs, mise-nixcache }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        mise-nixcache.nixosModules.default
        {
          # 一键安装 mise 并自动配置二进制缓存与信任公钥
          programs.mise.enable = true;
        }
      ];
    };
  };
}
```

### 方式二：使用 npins 管理依赖（推荐，非 Flake 项目）

在您的项目或系统配置中，通过 `npins` 追踪并引入本仓库：

1. 添加依赖到您的项目：
```bash
npins add github shaogme mise-nixcache -b main
```

2. 在 NixOS 系统配置中引入模块：
```nix
{ pkgs, ... }:

let
  sources = import ./npins;
  miseRepo = import sources.mise-nixcache { inherit pkgs; };
in
{
  imports = [
    miseRepo.nixosModules.default
  ];

  programs.mise.enable = true;
}
```

3. 或在通用配置中作为软件包使用：
```nix
{ pkgs, ... }:

let
  sources = import ./npins;
  miseRepo = import sources.mise-nixcache { inherit pkgs; };
in
{
  environment.systemPackages = [
    miseRepo.mise
  ];
}
```

### 方式三：使用 nix profile 安装（Nix 3.x 命令行）

```bash
# 安装 mise 到当前用户环境
nix profile install github:shaogme/mise-nixcache#mise
```

### 方式四：使用传统 nix-env 安装（非 Flake 命令行）

```bash
# 从仓库主分支源码压缩包直接安装
nix-env -f https://github.com/shaogme/mise-nixcache/archive/main.tar.gz -iA mise
```

### 方式五：临时运行（无需安装）

如果您仅需临时使用 mise 而不想污染环境：

```bash
# 临时运行 mise 命令
nix run github:shaogme/mise-nixcache#mise -- --version

# 进入包含 mise 的临时 Shell
nix shell github:shaogme/mise-nixcache#mise
```

### 方式六：在传统 NixOS 系统中全局安装（builtins.fetchTarball）

在系统的 `configuration.nix` 中添加配置：

```nix
{ pkgs, ... }:

let
  # 导入本仓库的 mise 模块与定义
  miseRepo = import (builtins.fetchTarball "https://github.com/shaogme/mise-nixcache/archive/main.tar.gz") { inherit pkgs; };
in
{
  imports = [
    miseRepo.nixosModules.default
  ];

  programs.mise.enable = true;
}
```

应用配置：
```bash
sudo nixos-rebuild switch
```

### 方式七：在 Home Manager 中安装

在您的 `home.nix` 配置文件中引入：

```nix
{ pkgs, ... }:

let
  miseRepo = import (builtins.fetchTarball "https://github.com/shaogme/mise-nixcache/archive/main.tar.gz") { inherit pkgs; };
in
{
  home.packages = [
    miseRepo.mise
  ];
}
```

应用配置：
```bash
home-manager switch
```

---

## 4. 验证安装

安装完成后，打开新的终端会话，执行以下命令验证 mise 是否安装成功：

```bash
# 查看版本信息
mise --version

# 检查运行环境与状态
mise doctor
```

---

## 5. 常见问题排查

### 1. 安装时仍在本地从源码编译 Rust 代码
- **检查代理状态**：确认 `nixcache-proxy` 是否正常运行并监听在 `37515` 端口（执行 `curl http://localhost:37515/_status`）。
- **检查公钥配置**：确保 `extra-trusted-public-keys` 中已正确添加 `mise-cache-1:wc5EMEDHcUyzRUTm6EuRKp0hhsJiKB2lfEi3ZOT1ahg=`。
- **强制刷新索引**：执行 `curl -X POST http://localhost:37515/_refresh` 强制让代理拉取最新的 GHCR 索引。

### 2. 权限不足报错
- 若在单用户非 root 环境下修改系统 `nix.conf` 失败，请将配置写入用户级配置文件 `~/.config/nix/nix.conf` 中。
