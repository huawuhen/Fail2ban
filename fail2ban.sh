#!/bin/bash

# 检查权限
[[ $EUID -ne 0 ]] && echo "请以 root 运行" && exit 1

# 识别系统
. /etc/os-release
OS=$ID

echo "--- 正在执行强力修复安装 ---"

# 1. 安装 Fail2ban 和 必要的防火墙/系统组件
case $OS in
    ubuntu|debian|kali|raspbian)
        apt-get update
        # 确保安装了 iptables 和 python3-systemd
        apt-get install -y fail2ban python3-systemd iptables
        ;;
    centos|rhel|almalinux|rocky)
        yum install -y epel-release
        yum install -y fail2ban python3-systemd iptables
        ;;
esac

# 2. 清理可能导致冲突的旧配置
echo "清理旧配置..."
rm -rf /etc/fail2ban/jail.local
rm -f /etc/fail2ban/jail.d/*.conf
rm -f /var/run/fail2ban/fail2ban.sock

# 3. 获取 SSH 端口
ssh_port=$(grep "^Port" /etc/ssh/sshd_config | awk '{print $2}')
[ -z "$ssh_port" ] && ssh_port=22

# 4. 重新写入最稳健的配置
# 显式使用 systemd 作为后端（目前最推荐的做法）
cat > /etc/fail2ban/jail.local <<EOF
[DEFAULT]
ignoreip = 127.0.0.1/8 ::1
bantime  = 86400
findtime = 3600
maxretry = 3
# 使用 systemd 读取日志，不需要指定 logpath
backend = systemd

[sshd]
enabled = true
port    = $ssh_port
filter  = sshd
# 强制指定 action 为 iptables-multiport，确保兼容性
action  = iptables-multiport[name=ssh, port="$ssh_port", protocol=tcp]
EOF

# 5. 重启并验证
echo "正在尝试启动服务..."
systemctl daemon-reload
systemctl enable fail2ban
systemctl restart fail2ban

sleep 3

# 检查状态
if systemctl is-active --quiet fail2ban; then
    echo "✅ Fail2ban 已成功运行！"
    fail2ban-client status sshd
else
    echo "❌ 依然失败。正在捕获最后 10 行关键错误日志："
    fail2ban-server -D -vvv -c /etc/fail2ban start 2>&1 | tail -n 10
fi
