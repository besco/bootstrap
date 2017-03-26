# bootstrap
Setup a Kickstart/PXE/DHCP server for Centos

# Options:

## --prepareImage[=path|url]
Prepare image for PXE.  Use this option when necessary create a copy of the ISO image on hard disk to install Centos over the network. This option will copy the files from the ISO image to /tftpboot/centos<br> 
By default iso-image will be download from: http://mirror.corbina.net/pub/Linux/centos/7/isos/x86_64/CentOS-7-x86_64-Minimal-1503-01.iso <br>

###Examples:
```
#./bash_install.sh --prepareImage=http://mirror.corbina.net/pub/Linux/centos/7/isos/x86_64/CentOS-7-x86_64-Minimal-1503-01.iso
or
#./bash_install.sh --prepareImage=/tmp/downloads/CentOS-7-x86_64-Minimal-1503-01.iso
```


--prepareSoft
Check and install necessery software (dhcp, vsftpd, httpd, syslinux, tftp, tftp-server, wget, nfs-utils, etc)
--prepareDhcp
Generate configuration for DHCP, kickstart and boot menu (/etc/dhcp/dhcpd.conf, /tftpboot/centos7-ks.cfg, /tftpboot/pxelinux.cfg/default)<br>
--prepareTftp<br>
Generate configuration for TFTP server<br>
--prepareFw<br>
Open the necessary ports in the firewall<br>
--prepareNfs<br>
Generate configuration for NFS server<br>
--prepareFtpd<br>
Generate configuration for FTP server<br>
--prepareHttpd<br>
Generate configuration for HTTP server<br>
--prepareNetwork<br>
Generate configuration for all (DHCP,TFTP,NFS,FTP,HTTP,Firewall)<br>
    

