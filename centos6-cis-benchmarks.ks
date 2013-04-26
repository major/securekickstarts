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
url --url=http://192.168.250.30/centos6/
text
lang en_US.UTF-8
keyboard us
network --onboot yes --device eth0 --bootproto dhcp --ipv6 auto
rootpw qwerty
firewall --disabled
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

# CIS 1.4.1
bootloader --location=mbr --driveorder=vda --append="selinux=1"
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
echo "" && "# CIS Benchmark Adjustments" >> /etc/fstab
# CIS 1.6.2
echo "kernel.exec-shield = 1" >> /etc/sysctl.conf
# CIS 1.6.3
echo "kernel.randomize_va_space = 2" >> /etc/sysctl.conf

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



%end