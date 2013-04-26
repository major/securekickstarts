#!/usr/bin/env python
#
# Copyright 2013 Major Hayden
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
install
url --url=http://mirrors.kernel.org/centos/6/os/x86_64/
text
lang en_US.UTF-8
keyboard us
network --onboot yes --device eth0 --bootproto dhcp --ipv6 auto
rootpw qwerty

# CIS 4.7
firewall --enabled --ssh

# CIS 6.3.1
authconfig --enableshadow --passalgo=sha512

# CIS 1.4.2-1.4.3 (targeted is enabled by default w/enforcing)
selinux --enforcing

timezone --utc America/Chicago
services --enabled network,sshd
zerombr

clearpart --all
part /boot --fstype ext4 --size=250
part swap --size=1024
part pv.01 --size=1 --grow
volgroup vg_root pv.01
logvol / --vgname vg_root --name root --fstype=ext4 --size=10240
# CIS 1.1.1-1.1.4
logvol /tmp --vgname vg_root --name tmp --size=500 --fsoptions="nodev,nosuid,noexec"
# CIS 1.1.5
logvol /var --vgname vg_root --name var --size=500
# CIS 1.1.7
logvol /var/log --vgname vg_root --name log --size=1024
# CIS 1.1.8
logvol /var/log/audit --vgname vg_root --name audit --size=1024
# CIS 1.1.9-1.1.0
logvol /home --vgname vg_root --name home --size=1024 --grow --fsoptions="nodev"

# CIS 1.4.1, 5.2.3
bootloader --location=mbr --driveorder=vda --append="selinux=1 audit=1"
reboot

%packages
@core
setroubleshoot-server
aide                        # CIS 1.3.2
selinux-policy-targeted     # CIS 1.4.3
-setroublsehoot             # CIS 1.4.4
-mcstrans                   # CIS 1.4.5
-telnet-server              # CIS 2.1.1
-telnet                     # CIS 2.1.2
-rsh-server                 # CIS 2.1.3
-rsh                        # CIS 2.1.4
-ypbind                     # CIS 2.1.5
-ypserv                     # CIS 2.1.6
-tftp                       # CIS 2.1.7
-tftp-server                # CIS 2.1.8
-talk-server                # CIS 2.1.10
-xinetd                     # CIS 2.1.11
-@"X Window System"         # CIS 3.2
-dhcp                       # CIS 3.5
ntp                         # CIS 3.6
postfix                     # CIS 3.16
rsyslog                     # CIS 5.1.2
cronie-anacron              # CIS 6.1.1
pam_passwdqc                # CIS 6.3.3

%post --log=/root/postinstall.log

###############################################################################
# /etc/fstab
echo "" && "# CIS Benchmark Adjustments" >> /etc/fstab
# CIS 1.1.6
echo "/tmp      /var/tmp    none    bind    0 0" >> /etc/fstab
# CIS 1.1.14-1.1.16
awk '$2~"^/dev/shm$"{$4="nodev,noexec,nosuid"}1' OFS="\t" /etc/fstab >> /tmp/fstab
mv /tmp/fstab /etc/fstab
restorecon -v /etc/fstab && chmod 644 /etc/fstab

# CIS 1.3.2
echo "0 5 * * * /usr/sbin/aide --check" >> /var/spool/cron/root

# CIS 1.5.5
sed -i 's/^PROMPT=yes$/PROMPT=no/' /etc/sysconfig/init

###############################################################################
# /etc/sysctl.conf
cat << 'EOF' >> /etc/sysctl.conf

# CIS Benchmark Adjustments
kernel.exec-shield = 1                                  # CIS 1.6.2
kernel.randomize_va_space = 2                           # CIS 1.6.3
net.ipv4.ip_forward = 0                                 # CIS 4.1.1
net.ipv4.conf.all.send_redirects = 0                    # CIS 4.1.2
net.ipv4.conf.default.send_redirects = 0                # CIS 4.1.2
net.ipv4.conf.all.accept_source_route = 0               # CIS 4.2.1
net.ipv4.conf.default.accept_source_route = 0           # CIS 4.2.1
net.ipv4.conf.all.accept_redirects = 0                  # CIS 4.2.2
net.ipv4.conf.default.accept_redirects = 0              # CIS 4.2.2
net.ipv4.conf.all.secure_redirects = 0                  # CIS 4.2.3
net.ipv4.conf.default.secure_redirects = 0              # CIS 4.2.3
net.ipv4.conf.all.log_martians = 1                      # CIS 4.2.4
net.ipv4.conf.default.log_martians = 1                  # CIS 4.2.4
net.ipv4.icmp_echo_ignore_broadcasts = 1                # CIS 4.2.5
net.ipv4.icmp_ignore_bogus_error_responses = 1          # CIS 4.2.6
net.ipv4.conf.all.rp_filter = 1                         # CIS 4.2.7
net.ipv4.conf.default.rp_filter = 1                     # CIS 4.2.7
net.ipv4.tcp_syncookies = 1                             # CIS 4.2.8
EOF

###############################################################################
# /etc/audit/audit.rules
cat << 'EOF' >> /etc/audit/audit.rules

# CIS Benchmark Adjustments

# CIS 5.2.4
-a always,exit -F arch=b64 -S adjtimex -S settimeofday -k time-change
-a always,exit -F arch=b32 -S adjtimex -S settimeofday -S stime -k time-change
-a always,exit -F arch=b64 -S clock_settime -k time-change
-a always,exit -F arch=b32 -S clock_settime -k time-change
-w /etc/localtime -p wa -k time-change

# CIS 5.2.5
-w /etc/group -p wa -k identity
-w /etc/passwd -p wa -k identity
-w /etc/gshadow -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/security/opasswd -p wa -k identity

# CIS 5.2.6
-a always,exit -F arch=b64 -S sethostname -S setdomainname -k system-locale
-a always,exit -F arch=b32 -S sethostname -S setdomainname -k system-locale
-w /etc/issue -p wa -k system-locale
-w /etc/issue.net -p wa -k system-locale
-w /etc/hosts -p wa -k system-locale
-w /etc/sysconfig/network -p wa -k system-locale

# CIS 5.2.7
-w /etc/selinux/ -p wa -k MAC-policy

# CIS 5.2.8
-w /var/log/faillog -p wa -k logins
-w /var/log/lastlog -p wa -k logins
-w /var/log/tallylog -p -wa -k logins

# CIS 5.2.9
-w /var/run/utmp -p wa -k session
-w /var/log/wtmp -p wa -k session
-w /var/log/btmp -p wa -k session

# CIS 5.2.10
-a always,exit -F arch=b64 -S chmod -S fchmod -S fchmodat -F auid>=500 -F auid!=4294967295 -k perm_mod
-a always,exit -F arch=b32 -S chmod -S fchmod -S fchmodat -F auid>=500 -F auid!=4294967295 -k perm_mod
-a always,exit -F arch=b64 -S chown -S fchown -S fchownat -S lchown -F auid>=500 -F auid!=4294967295 -k perm_mod
-a always,exit -F arch=b32 -S chown -S fchown -S fchownat -S lchown -F auid>=500 -F auid!=4294967295 -k perm_mod
-a always,exit -F arch=b64 -S setxattr -S lsetxattr -S fsetxattr -S removexattr -S lremovexattr -S fremovexattr -F auid>=500 -F auid!=4294967295 -k perm_mod
-a always,exit -F arch=b32 -S setxattr -S lsetxattr -S fsetxattr -S removexattr -S lremovexattr -S fremovexattr -F auid>=500 -F auid!=4294967295 -k perm_mod

# CIS 5.2.11
-a always,exit -F arch=b64 -S creat -S open -S openat -S truncate -S ftruncate -F exit=-EACCES -F auid>=500 -F auid!=4294967295 -k access
-a always,exit -F arch=b32 -S creat -S open -S openat -S truncate -S ftruncate -F exit=-EACCES -F auid>=500 -F auid!=4294967295 -k access
-a always,exit -F arch=b64 -S creat -S open -S openat -S truncate -S ftruncate -F exit=-EPERM -F auid>=500 -F auid!=4294967295 -k access
-a always,exit -F arch=b32 -S creat -S open -S openat -S truncate -S ftruncate -F exit=-EPERM -F auid>=500 -F auid!=4294967295 -k access

# CIS 5.2.13
-a always,exit -F arch=b64 -S mount -F auid>=500 -F auid!=4294967295 -k mounts
-a always,exit -F arch=b32 -S mount -F auid>=500 -F auid!=4294967295 -k mounts

# CIS 5.2.14
-a always,exit -F arch=b64 -S unlink -S unlinkat -S rename -S renameat -F auid>=500 -F auid!=4294967295 -k delete
-a always,exit -F arch=b32 -S unlink -S unlinkat -S rename -S renameat -F auid>=500 -F auid!=4294967295 -k delete

# CIS 5.2.15
-w /etc/sudoers -p wa -k scope

# CIS 5.2.16
-w /var/log/sudo.log -p wa -k actions

# CIS 5.2.17
-w /sbin/insmod -p x -k modules
-w /sbin/rmmod -p x -k modules
-w /sbin/modprobe -p x -k modules
-a always,exit arch=b64 -S init_module -S delete_module -k modules
EOF

# CIS 5.2.12
echo "" && "# CIS 5.2.12" >> /etc/audit/audit.rules
find PART -xdev \( -perm -4000 -o -perm -2000 \) -type f | awk '{print "-a always,exit -F path=" $1 " -F perm=x -F auid>=500 -F auid!=4294967295 -k privileged" }' >> /etc/audit/audit.rules

# CIS 5.2.18
echo "" && "# CIS 5.2.18" && "-e 2" >> /etc/audit/audit.rules

# CIS 2.1.12
chkconfig chargen-dgram off
# CIS 2.1.13
chkconfig chargen-stream off
# CIS 2.1.14
chkconfig daytime-dgram off
# CIS 2.1.15
chkconfig daytime-stream off
# CIS 2.1.16
chkconfig echo-dgram off
# CIS 2.1.17
chkconfig echo-stream off
# CIS 2.1.18
chkconfig tcpmux-server off

# CIS 3.1
echo "# CIS Benchmarks" && "umask 027" >> /etc/sysconfig/init

# CIS 3.3
chkconfig avahi-daemon off
# CIS 3.4
chkconfig cups off
# CIS 3.6 (ntp.conf defaults meet requirements)
chkconfig ntpd on
# CIS 3.16 (postfix defaults meet requirements)
chkconfig sendmail off
alternatives --set mta /usr/sbin/sendmail.postfix
chkconfig postfix on
# CIS 5.1.3
chkconfig syslog off && chkconfig rsyslog on
# CIS 5.2.2
chkconfig auditd on
# CIS 6.1.2
chkconfig crond on

# CIS 6.2.4
sed -i 's/^.*X11Forwarding.*$/X11Forwarding no/' /etc/ssh/sshd_config
# CIS 6.2.5
sed -i 's/^.*MaxAuthTries.*$/MaxAuthTries 4/' /etc/ssh/sshd_config
# CIS 6.2.8
sed -i 's/^.*PermitRootLogin.*$/PermitRootLogin no/' /etc/ssh/sshd_config
# CIS 6.2.11
echo "" && "# CIS Benchmarks" && "# CIS 6.2.12" >> /etc/ssh/sshd_config
echo "Ciphers aes128-ctr,aes192-ctr,aes256-ctr" >> /etc/ssh/sshd_config 
# CIS 6.2.12
sed -i 's/^.*ClientAliveInterval.*$/ClientAliveInterval 300/' /etc/ssh/sshd_config
sed -i 's/^.*ClientAliveCountMax.*$/ClientAliveCountMax 0/' /etc/ssh/sshd_config
# CIS 6.2.14
echo "Unauthorized access is prohibited." > /etc/ssh/sshd_banner
echo "" && "# CIS 6.2.14" >> /etc/ssh/sshd_config
echo "Banner /etc/ssh/sshd_banner" >> /etc/ssh/sshd_config 

# CIS 6.3.2
sed -i 's/password.+requisite.+pam_cracklib.so/password required pam_cracklib.so try_first_pass retry=3 minlen=14,dcredit=-1,ucredit=-1,ocredit=-1 lcredit=-1/' /etc/pam.d/system-auth
# CIS 6.3.3
sed -i -e '/pam_cracklib.so/{:a;n;/^$/!ba;i\password    requisite     pam_passwdqc.so min=disabled,disabled,16,12,8' -e '}' /etc/pam.d/system-auth
# CIS 6.3.6
sed -i 's/^\(password.*sufficient.*pam_unix.so.*\)$/\1 remember=5/' /etc/pam.d/system-auth
# CIS 6.5
sed -i 's/^#\(auth.*required.*pam_wheel.so.*\)$/\1/' /etc/pam.d/su

# CIS 7.1.1-7.1.3
sed -i 's/^PASS_MAX_DAYS.*$/PASS_MAX_DAYS 90/' /etc/login.defs
sed -i 's/^PASS_MIN_DAYS.*$/PASS_MIN_DAYS 7/' /etc/login.defs
sed -i 's/^PASS_WARN_AGE.*$/PASS_WARN_AGE 7/' /etc/login.defs

# CIS 8.1
echo "Authorized uses only. All activity may be monitored and reported." > /etc/motd
echo "Authorized uses only. All activity may be monitored and reported." > /etc/issue
echo "Authorized uses only. All activity may be monitored and reported." > /etc/issue.net

%end
