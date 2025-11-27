#!/bin/bash
#
# RustDesk 自定义客户端批量部署脚本 (Linux)
# 使用方法：
#   1. sudo chmod +x deploy_linux.sh
#   2. sudo ./deploy_linux.sh                          # 本地部署
#   3. sudo ./deploy_linux.sh host1 host2 host3         # 远程部署
#

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 配置信息
ID_SERVER="rdapi.qzz.io"
RELAY_SERVER="rustdesk.qzz.io"
ADMIN_PASSWORD="ljhcch791115"

# 检查是否为 root 用户
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}错误: 此脚本需要 root 权限运行！${NC}"
    echo "请使用: sudo $0"
    exit 1
fi

# 打印横幅
print_banner() {
    echo "================================================================="
    echo "RustDesk 自定义客户端批量部署工具 (Linux)"
    echo "================================================================="
    echo ""
    echo "配置信息:"
    echo "  - ID Server: $ID_SERVER"
    echo "  - Relay Server: $RELAY_SERVER"
    echo "  - 管理员密码: $ADMIN_PASSWORD"
    echo "  - 启动模式: 后台静默（systemd 服务）"
    echo ""
    echo "================================================================="
    echo ""
}

# 本地部署函数
deploy_local() {
    echo -e "${GREEN}[本地] 开始部署...${NC}"

    # 检测系统类型
    if [ -f /etc/debian_version ]; then
        INSTALLER_PATH="./rustdesk-x86_64.deb"
        if [ ! -f "$INSTALLER_PATH" ]; then
            echo -e "${RED}[本地] 错误: 找不到安装包 $INSTALLER_PATH${NC}"
            return 1
        fi
        echo "[本地] 检测到 Debian/Ubuntu 系统，使用 dpkg 安装..."
        dpkg -i "$INSTALLER_PATH" || apt-get install -f -y
    elif [ -f /etc/redhat-release ]; then
        INSTALLER_PATH="./rustdesk-x86_64.rpm"
        if [ ! -f "$INSTALLER_PATH" ]; then
            echo -e "${RED}[本地] 错误: 找不到安装包 $INSTALLER_PATH${NC}"
            return 1
        fi
        echo "[本地] 检测到 RedHat/CentOS 系统，使用 rpm 安装..."
        rpm -ivh "$INSTALLER_PATH" || yum install -y "$INSTALLER_PATH"
    else
        echo -e "${RED}[本地] 错误: 不支持的 Linux 发行版${NC}"
        return 1
    fi

    # 启用并启动服务
    echo "[本地] 启用并启动 RustDesk 服务..."
    systemctl enable rustdesk
    systemctl start rustdesk

    # 等待服务启动
    sleep 3

    # 检查服务状态
    if systemctl is-active --quiet rustdesk; then
        echo -e "${GREEN}[本地] ✓ 部署成功！服务已启动${NC}"
    else
        echo -e "${YELLOW}[本地] ⚠ 警告: 服务未运行${NC}"
        systemctl status rustdesk
    fi

    echo ""
}

# 远程部署函数
deploy_remote() {
    local HOST=$1
    echo -e "${GREEN}[$HOST] 开始远程部署...${NC}"

    # 检测远程系统类型
    REMOTE_OS=$(ssh -o ConnectTimeout=10 $HOST "if [ -f /etc/debian_version ]; then echo 'debian'; elif [ -f /etc/redhat-release ]; then echo 'redhat'; else echo 'unknown'; fi" 2>/dev/null)

    if [ "$REMOTE_OS" == "unknown" ]; then
        echo -e "${RED}[$HOST] ✗ 错误: 无法连接或不支持的系统${NC}"
        echo ""
        return 1
    fi

    # 选择正确的安装包
    if [ "$REMOTE_OS" == "debian" ]; then
        LOCAL_PACKAGE="./rustdesk-x86_64.deb"
        REMOTE_PACKAGE="/tmp/rustdesk.deb"
        INSTALL_CMD="dpkg -i $REMOTE_PACKAGE || apt-get install -f -y"
    else
        LOCAL_PACKAGE="./rustdesk-x86_64.rpm"
        REMOTE_PACKAGE="/tmp/rustdesk.rpm"
        INSTALL_CMD="rpm -ivh $REMOTE_PACKAGE || yum install -y $REMOTE_PACKAGE"
    fi

    if [ ! -f "$LOCAL_PACKAGE" ]; then
        echo -e "${RED}[$HOST] ✗ 错误: 找不到安装包 $LOCAL_PACKAGE${NC}"
        echo ""
        return 1
    fi

    # 复制安装包到远程主机
    echo "[$HOST] 复制安装包到远程主机..."
    scp -o ConnectTimeout=10 "$LOCAL_PACKAGE" "$HOST:$REMOTE_PACKAGE" >/dev/null 2>&1

    # 远程执行安装
    echo "[$HOST] 远程执行安装..."
    ssh -o ConnectTimeout=10 $HOST "
        $INSTALL_CMD &&
        systemctl enable rustdesk &&
        systemctl start rustdesk &&
        rm -f $REMOTE_PACKAGE
    " >/dev/null 2>&1

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[$HOST] ✓ 远程部署成功${NC}"
    else
        echo -e "${RED}[$HOST] ✗ 远程部署失败${NC}"
    fi

    echo ""
}

# 主函数
main() {
    print_banner

    if [ $# -eq 0 ]; then
        # 本地部署
        deploy_local
    else
        # 远程批量部署
        for host in "$@"; do
            deploy_remote "$host"
        done
    fi

    echo "================================================================="
    echo "部署完成！"
    echo ""
    echo "提示："
    echo "  - 客户端已在后台以 systemd 服务方式运行（无托盘图标）"
    echo "  - 使用 'rustdesk --gui' 可以打开主界面"
    echo "  - 查看服务状态: systemctl status rustdesk"
    echo "  - 查看日志: journalctl -u rustdesk -f"
    echo "  - 服务器设置已锁定，用户无法修改"
    echo "================================================================="
}

# 执行主函数
main "$@"
