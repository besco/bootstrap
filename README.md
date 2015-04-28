# bootstrap
Setup a Kickstart/PXE/DHCP server for Centos

# Options:

## --prepareImage[=<file|url>]
Prepare image for PXE.  Use this option when necessary create a copy of the ISO image on hard disk to install Centos over the network. This option will copy the files from the ISO image to /tftpboot/centos<br> 
The following two options point out where to get the ISO image:<br>

###Examples:
```
#./bash_install.sh --prepareImage= http://mirror.corbina.net/pub/Linux/centos/7/isos/x86_64/CentOS-7-x86_64-Minimal-1503-01.iso
or
#./bash_install.sh --prepareImage=/tmp/downloads/CentOS-7-x86_64-Minimal-1503-01.iso
```
##--prepareSoft
Check and install necessery software (dhcp, vsftpd, httpd, syslinux, tftp, tftp-server, wget, nfs-utils, etc)
##--prepareDhcp
Generate configuration for DHCP, kickstart and boot menu (/etc/dhcp/dhcpd.conf, /tftpboot/centos7-ks.cfg, /tftpboot/pxelinux.cfg/default)
##--prepareTftp
Generate configuration for TFTP server
##--prepareFw
Open the necessary ports in the firewall
##--enableNfs
Generate configuration for NFS server
##--prepareFtpd
Generate configuration for FTP server
##--prepareHttpd
Generate configuration for HTTP server
##--prepareNetwork
Generate configuration for all (DHCP,TFTP,NFS,FTP,HTTP,Firewall)
    

