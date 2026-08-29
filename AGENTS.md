# AGENTS.md

本文档旨在指导 AI 助手（Agents）在本仓库中高效工作。

## 依赖管理指南

在本仓库中引入外部 Nix 依赖（非 Flake 项目）时，请务必**优先使用 `npins`**，而不是手动编写 `fetchFromGitHub` 或 `fetchTarball`。

### 核心规则
- **优先使用 npins**：除非有极特殊理由，否则所有外部 Git 仓库、Nix Channels、PyPi 包或 Tarball 依赖都应通过 `npins` 管理。
- **强制阅读文档**：在任何涉及 `npins` 的操作（添加、更新、维护、代码引入）之前，必须阅读并遵循以下文档：
    - [npins CLI 详细文档](docs/npins/cli.md)：了解如何使用命令行工具管理依赖。
    - [npins 产物使用指南](docs/npins/usage.md)：了解如何在 Nix 代码中正确引用和覆盖依赖。
    - [项目测试指南](docs/npins/testing.md)：了解如何编写和运行静态检查及 VM 测试。

## 开发工作流

### 添加新依赖
1. 确认依赖类型（GitHub, Git, PyPi 等）。
2. 使用 `npins add <type> ...` 命令添加。
3. 检查 `npins/sources.json` 是否已正确更新。
4. 在 Nix 代码中通过 `import <npins-path>` 引入。

### 更新依赖
1. 定期运行 `npins update` 保持依赖项最新。
2. 运行 `npins verify` 确保哈希值正确。

### 调试与覆盖
- 如果需要修改依赖项代码进行调试，请利用 `NPINS_OVERRIDE_<NAME>` 环境变量切换到本地路径，切勿直接修改 `sources.json` 中的哈希值指向不稳定的版本。

## 代码提交流程
- **提交 `sources.json`**：确保 `npins/sources.json` 的更改随代码一同提交。
- **不要提交 `default.nix` 修改**：该文件由工具自动生成，不应手动修改。

## 测试与验证

在提交任何修改（尤其是涉及内核参数、磁盘分区或底层服务时），必须执行相关测试以确保稳定性。

### 强制测试要求
1. **执行静态检查**：通过 `evalConfig` 验证配置项是否正确应用。
2. **运行 VM 测试**：涉及运行时逻辑（如驱动加载、服务状态）时，必须通过 `nixosTest` 验证。
3. **构建验证**：确保 `toplevel` 或相关包能够成功构建，无下载或评估错误。

详细测试方法和实现参考请阅读：[项目测试指南](docs/npins/testing.md)。

## 代码编辑最佳实践

使用局部代码编辑工具（如 `replace_file_content`）修改文件时，必须严格遵守以下规范以避免引入意外格式变动（如多余空行或被删空行）：

1. **整行对齐（Full-line Context Matching）**：
   - 匹配代码时应包含完整的上下代码行作为定位锚点，确保 `TargetContent` 与 `ReplacementContent` 的首尾行边界严密契合。
2. **严防首尾悬挂换行符（Trailing/Leading Newlines）**：
   - 仔细核对待替换片段的首尾换行，避免因末尾多出 `\n` 与原文件保留的换行拼接而意外产生空行。
3. **严格禁止无意义的空行增删**：
   - 严禁随意在 `import`/`use` 语句、结构体字段、函数大括号前后增删空行。
