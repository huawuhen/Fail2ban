#!/bin/bash

# 检查权限
[[ $EUID -ne 0 ]] && echo "请以 root 运行" && exit 1

# 识别系统
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo "无法识别系统"
    exit 1
fi

echo "--- 正在卸载 Fail2ban ---"

# 1. 停止服务并清除自启动
systemctl stop fail2ban
systemctl disable fail2ban

# 2. 卸载软件包
echo "正在移除软件包..."
case $OS in
    ubuntu|debian|kali|raspbian)
        apt-get purge -y fail2ban
        apt-get autoremove -y
        ;;
    centos|rhel|almalinux|rocky)
        yum remove -y fail2ban
        ;;
esac

# 3. 清理残留文件
echo "清理配置文件和日志..."
rm -rf /etc/fail2ban
rm -rf /var/lib/fail2ban
rm -rf /var/run/fail2ban
rm -f /var/log/fail2ban.log*

# 4. 清理防火墙残留规则（可选）
# Fail2ban 正常停止时会自动清理，但如果之前崩溃过，可能残留规则
echo "正在清理可能的防火墙残留..."
iptables -F
# 如果你使用了特定的链，可能需要重启防火墙服务来彻底重置
if command -v firewalld >/dev/null 2>&1; then
    systemctl restart firewalld
elif command -v ufw >/dev/null 2>&1; then
    ufw reload
fi

echo "--- Fail2ban 已彻底卸载 ---"
