# Fail2ban #
这是一个利用iptables和开源程序fail2ban来进行服务器简单防爆破的脚本。默认自带SSH防御规则。

# 功能 #
- 自助修改SSH端口
- 自定义最高封禁IP的时间（以小时为单位）
- 自定义SSH尝试连接次数
- 一键完成SSH防止暴力破解

# 支持系统 #
- Centos 6+ (x86/x64)
- Ubuntu 16+ (x86/x64)
- Debian 7+ (x86/x64)

# 安装 #
    wget https://raw.githubusercontent.com/huawuhen/Fail2ban/refs/heads/master/fail2ban.sh && chmod +x fail2ban.sh && bash fail2ban.sh
1. 第一步选择是否修改SSH端口。如果你已在`sshd.conf`已修改非默认22这里就不用改了。
1. 第二部输入最多尝试输入SSH连接密码的次数
1. 第三部输入每个恶意IP的封禁时间（单位：小时）

# 卸载 #
    wget https://raw.githubusercontent.com/FunctionClub/Fail2ban/master/uninstall.sh && bash uninstall.sh

# 注意事项 #
1. 安装完成后请会重启SSH服务，请重新连接SSH会话
2. 若出现SSH无法连接的情况，请检查是否修改过SSH端口，请填写写改后的正确端口进行连接

# 常用命令
- 查看运行状态 `fail2ban-client status sshd`
```
|- Filter
|  |- Currently failed当前失败次数:	0
|  |- Total failed总失败次数:	3
|  `- File list:	/var/log/auth.log
 。`- Actions
|- Currently banned当前ban掉的ip数:	1
|- Total banned总计ban掉了多少ip:	1
   `- Banned IP listban掉的ip列表:	45.130.23.212
```
- 手动阻住某IP `fail2ban-client set sshd banip <IP地址>`
- 手动解除某IP `fail2ban-client set sshd unbanip <IP地址>`
# 更新日志 #
2025.12.25 提示步骤中英汉化
2016.11.15 第一次提交，初步完成。

# 关于 #
Made by [huawuhen](https://19940816.xyz/ "FunctionClub")

# 鸣谢 #
- [Fail2ban](http://www.fail2ban.org "Fail2ban")
- [Oneinstack](http://oneinstack.com "Oneinstack")
