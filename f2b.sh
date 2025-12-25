#!/bin/bash

# 定义颜色
CGREEN=$(tput setaf 2)
CROOT=$(tput setaf 1)
CYELLOW=$(tput setaf 3)
CEND=$(tput sgr0)

# 1. 权限检查
[[ $EUID -ne 0 ]] && echo "${CROOT}错误: 请以 root 权限运行${CEND}" && exit 1

# 2. 识别系统
. /etc/os-release
OS=$ID

# 3. 交互设置参数
echo "${CGREEN}-------------------- Fail2ban 交互安装 (强力修复版) --------------------${CEND}"

# 获取 SSH 端口
ssh_port=$(grep "^Port" /etc/ssh/sshd_config | awk '{print $2}')
[ -z "$ssh_port" ] && ssh_port=22

read -p "请输入最大尝试次数 (默认 3 次): " maxretry
maxretry=${maxretry:-3}

read -p "请输入封禁时长 (小时, 默认 24 小时): " bantime_h
bantime_h=${bantime_h:-24}
bantime_s=$((bantime_h * 3600))

echo ""
echo "配置确认: 最大尝试 $maxretry 次，封禁 $bantime_h 小时，当前 SSH 端口 $ssh_port"
echo "-----------------------------------------------------------------------"

# 4. 安装软件及必要依赖
echo "正在安装 Fail2ban 及兼容性组件..."
case $OS in
    ubuntu|debian|kali|raspbian)
        apt-get update
        apt-get install -y fail2ban python3-systemd iptables
        ;;
    centos|rhel|almalinux|rocky)
        yum install -y epel-release
        yum install -y fail2ban python3-systemd iptables
        ;;
    *)
        echo "${CROOT}不支持的系统: $OS${CEND}"
        exit 1
        ;;
esac

# 5. 清理可能导致报错的冲突配置
echo "清理旧配置与残留..."
rm -rf /etc/fail2ban/jail.local
rm -f /etc/fail2ban/jail.d/*.conf
rm -f /var/run/fail2ban/fail2ban.sock

# 6. 写入优化后的稳健配置
# 使用 backend = systemd 解决日志找不到的问题
# 显式指定 action 解决防火墙调用失败的问题
echo "正在写入新配置..."
cat > /etc/fail2ban/jail.local <<EOF
[DEFAULT]
ignoreip = 127.0.0.1/8 ::1
bantime  = $bantime_s
findtime = 3600
maxretry = $maxretry
# 使用 systemd 模式（兼容性最强）
backend = systemd

[sshd]
enabled = true
port    = $ssh_port
filter  = sshd
# 显式指定 iptables 动作，防止崩溃
action  = iptables-multiport[name=ssh, port="$ssh_port", protocol=tcp]
EOF

# 7. 重启服务
echo "启动 Fail2ban 服务..."
systemctl daemon-reload
systemctl enable fail2ban
systemctl restart fail2ban

# 8. 状态验证
sleep 3
echo "-----------------------------------------------------------------------"
if systemctl is-active --quiet fail2ban; then
    echo "${CGREEN}✅ 安装成功！Fail2ban 正在运行。${CEND}"
    echo "${CGREEN}当前状态：${CEND}"
    fail2ban-client status sshd
else
    echo "${CROOT}❌ 启动失败，正在捕获错误详情...${CEND}"
    # 模拟启动以捕获详细报错
    fail2ban-server -D -vvv -c /etc/fail2ban start 2>&1 | tail -n 10
fi
echo "-----------------------------------------------------------------------"