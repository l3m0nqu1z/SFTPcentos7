#!/bin/bash
printf "\033c"
echo "######################################"
echo "#              Hola!                 #"
echo "# It's Auto SFTP building script for #"
echo "#    Centos7_min_x64 presented by    #"
echo "#            l3m0nqu1z               #"
echo "######################################"
read -n 1 -r -s -p $'Press any key to continue...\n'
if [ "$1" = "" ]
then
    NUMBER_USERS=1
else
    NUMBER_USERS=$1
fi
echo -n 'Updating system... '
yum update -y > /dev/null 2>&1 && echo "OK"
fail2ban() {
yum install -y epel-release fail2ban 
systemctl enable fail2ban
F2B_JAIL="/etc/fail2ban/jail.d/sshd.local"
echo "[sshd]
enabled = true
port = ssh
action = firewallcmd-ipset
logpath = %(sshd_log)s
maxretry = 5
bantime = 86400" > $F2B_JAIL
systemctl restart fail2ban
} 
diskextend() {
START=$(cat /sys/block/vda/vda2/start)
END=$(($(cat /sys/block/vda/size)-8))
LENGTH=$(($END-$START))
resizepart /dev/vda 2 $LENGTH
pvresize /dev/vda2
lvextend -l +100%FREE /dev/mapper/centos-root
xfs_growfs /    
sleep 1
} 
sshd() {
sed -i '/Subsystem/s/^/#/' /etc/ssh/sshd_config
echo "
Subsystem sftp internal-sftp
Match group sftpaccess
ChrootDirectory %h
X11Forwarding no
AllowTcpForwarding no
ForceCommand internal-sftp" >> /etc/ssh/sshd_config
sleep 1
} 
users() {
groupadd sftpaccess
for (( a = 1; a <= $NUMBER_USERS; a++ ))
do 
sleep 1
adduser -d /home/sftpuser$a -s /sbin/nologin sftpuser$a -g sftpaccess 
echo -n "Created user: sftpuser$a | password: "
PASS=$(</dev/urandom tr -dc 'a-zA-Z0-9#$*=' | head -c12;)
echo "$PASS"
echo "$PASS" | passwd --stdin sftpuser$a > /dev/null 2>&1
chown root /home/sftpuser$a
chmod 750 /home/sftpuser$a
mkdir /home/sftpuser$a/uploads
chown sftpuser$a:sftpaccess /home/sftpuser$a/uploads
done
}
echo -n 'Installing fail2ban... '
fail2ban > /dev/null 2>&1 && echo "OK"
echo -n 'Extending disk capacity... '
diskextend > /dev/null 2>&1 && echo "OK"
echo -n "Configuring sshd_config... "
sshd > /dev/null 2>&1 && echo "OK"
echo 'Adding group and user(s)... '
users 
echo "All Done"
echo "SSHD restarted"
systemctl restart sshd 
sleep 1
