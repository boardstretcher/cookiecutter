# Centos 7.5 Kickstart basic
auth --enableshadow --passalgo=sha512
cdrom
firstboot --enable
ignoredisk --only-use=sda
keyboard --vckeymap=us --xlayouts='us'
lang en_US.UTF-8

zerombr
clearpart --all --initlabel

network  --bootproto=dhcp --ipv6=auto --activate
network  --hostname=###THEHOSTNAME###

rootpw ###THEPASSWORD###
services --enabled="chronyd"
timezone --utc America/Detroit
bootloader --append=" crashkernel=auto" --location=mbr --boot-drive=sda

part /boot --fstype="xfs" --ondisk=sda --size=1024
part pv.1 --fstype="lvmpv" --ondisk=sda --size=1 --grow
volgroup vg00 --pesize=4096 pv.1
logvol                swap         --vgname=vg00 --name=lvswap01  --size=4096
logvol /              --fstype=xfs --vgname=vg00 --name=lvroot01  --size=4096
logvol /home          --fstype=xfs --vgname=vg00 --name=lvhome01  --size=512  --fsoptions="nodev"
logvol /opt           --fstype=xfs --vgname=vg00 --name=lvopt01   --size=512  --fsoptions="nodev"
logvol /tmp           --fstype=xfs --vgname=vg00 --name=lvtmp01   --size=2048 --fsoptions="nodev,nosuid"
logvol /var           --fstype=xfs --vgname=vg00 --name=lvvar01   --size=3072 --fsoptions="nodev,nosuid"
logvol /var/log       --fstype=xfs --vgname=vg00 --name=lvlog01   --size=1024 --fsoptions="nodev,nosuid,noexec"
logvol /var/log/audit --fstype=xfs --vgname=vg00 --name=lvaudit01 --size=512  --fsoptions="nodev,nosuid,noexec"

reboot
firewall --disabled
skipx

%packages --nobase
@^minimal
@core
chrony
kexec-tools
sudo
-cpuspeed
-smartmontools
-aic94xx-firmware
-atmel-firmware
-b43-openfwwf
-bfa-firmware
-ipw2100-firmware
-ipw2200-firmware
-ivtv-firmware
-iwl100-firmware
-iwl105-firmware
-iwl135-firmware
-iwl1000-firmware
-iwl2000-firmware
-iwl2030-firmware
-iwl3160-firmware
-iwl3945-firmware
-iwl4965-firmware
-iwl5000-firmware
-iwl5150-firmware
-iwl6000-firmware
-iwl6000g2a-firmware
-iwl6000g2b-firmware
-iwl6050-firmware
-iwl7260-firmware
-libertas-usb8388-firmware
-libertas-sd8686-firmware
-libertas-sd8787-firmware
-ql2100-firmware
-ql2200-firmware
-ql23xx-firmware
-ql2400-firmware
-ql2500-firmware
-rt61pci-firmware
-rt73usb-firmware
-xorg-x11-drv-ati-firmware
-zd1211-firmware

%end

%addon com_redhat_kdump --enable --reserve-mb='auto'

%end

%anaconda
pwpolicy root --minlen=6 --minquality=1 --notstrict --nochanges --notempty
pwpolicy user --minlen=6 --minquality=1 --notstrict --nochanges --emptyok
pwpolicy luks --minlen=6 --minquality=1 --notstrict --nochanges --notempty

