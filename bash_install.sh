#!/bin/bash
# (c) 2015, by Wasiliy Besedin, besco@yabesco.ru, 2:5028/68@fidonet.org, skype: unique-login-for-all

isoUrl="http://mirror.corbina.net/pub/Linux/centos/7/isos/x86_64/CentOS-7-x86_64-Minimal-1503-01.iso";
tftp_root="/tftpboot";
isoFile="";


function installSoft () {
    # The necessary software
    nSoft=("dhcp" "vsftpd" "httpd" "syslinux" "tftp" "tftp-server" "vim-enhanced" "wget" "nfs-utils" "net-tools");

    for index in ${!nSoft[*]}
    do
        checkInstall=`yum list installed "${nSoft[$index]}" &>/dev/null`;
        if [ $? == "1" ]; then 
	    echo "${nSoft[$index]} is not installed. Installing...";
	    rc=`yum install -y ${nSoft[$index]}`;
	    if [ $? == "1" ]; then 
		echo "Install ${nSoft[$index]} failed:";
		echo $rc;
	    else
		echo "Install ${nSoft[$index]} complete.";
	    fi
        else 
    	    echo "${nSoft[$index]} ready."
        fi
    done
}

function createDirs {

    nDirs=("$tftp_root" "$tftp_root/centos" "$tftp_root/pxelinux.cfg" "$tftp_root/netboot/centos/7/x86_64");
    for index in ${!nDirs[*]}
    do
      if [ ! -d "${nDirs[$index]}" ]; then
        echo "Directory ${nDirs[$index]} doesn't exist. Creating...";
        mkdir -p ${nDirs[$index]}
      else 
        echo "Directory ${nDirs[$index]} exist. Skiping...";
      fi
    done
    chmod -R 777 $tftp_root
}


function GiveMeBackMyEth {
    status=0;
    echo "Checking for changes in system for names of the interfaces";
    result=`cat /etc/sysconfig/grub | grep net.ifnames | wc -l`;
    if [ $result -eq "0" ]; then
	echo "Changes not detected. Check interfaces names";
	result=`ifconfig|grep eth0 | wc -l`;
	if [ $result -eq "0" ]; then
	    echo "Not found eth! Correcting."
	    ruselt=`sed -i 's/GRUB_CMDLINE_LINUX="/GRUB_CMDLINE_LINUX="net.ifnames=0 biosdevname=0 /' /etc/sysconfig/grub`;
	fi
    fi
}

function prepareDhcp {
    echo "Creating config for DHCP server";
    echo "";
    echo "Check directories:"
    createDirs;
    eth_arr=(`ifconfig|grep flags|awk '{split ($1,a,":"); print a[1]}'|xargs`)
    echo "On what interface DHCP must listen to?";
    echo "Fount ${#eth_arr[@]} interfaces.";
    for index in ${!eth_arr[*]}    
    do
	echo "["$index"] "${eth_arr[$index]}
    done
    echo -n "On what interface DHCP must listen to? [1]: ";
    read int_num
    if [ -z "$int_num" ]; then
	int_num=1;
    fi
    int_ip=`ifconfig ${eth_arr[$int_num]} |grep -w inet|awk '{print $2}'`
    echo "You select ${eth_arr[$int_num]}. Good choice :)";

    echo -n "Enter PXE server ip [$int_ip]: "
    read server_ip
    if [ -z "$server_ip" ]; then
	server_ip=$int_ip
    fi
    network=`echo $server_ip|awk '{split($1,a,"."); print a[1]"."a[2]"."a[3]".0"}'`;
    echo -n "Enter netmask [255.255.255.0]: "
    read netmask_nm;
    if [ -z "$netmask_nm" ]; then
	netmask_nm="255.255.255.0"
    fi

    echo -n "Enter network domain [localdomain]: "
    read network_dn
    if [ -z "$network_dn" ]; then 
	network_dn="localdomain"
    fi
    
    echo -n "Enter DNS ip[$server_ip]: "
    read dns_ip
    if [ -z "$dns_ip" ]; then
	dns_ip=$server_ip
    fi    
    
    echo -n "Enter gateway ip [$server_ip]: "
    read gateway_ip
    if [ -z "$gateway_ip" ]; then
	gateway_ip=$server_ip
    fi
    auto_first_ip=`echo $server_ip|awk '{split($1,a,"."); print a[1]"."a[2]"."a[3]".10"}'`;
    
    echo -n "Enter first ip of range [$auto_first_ip]: "
    read first_ip
    if [ -z "$first_ip" ]; then
	first_ip=$auto_first_ip
    fi
    auto_last_ip=`echo $server_ip|awk '{split($1,a,"."); print a[1]"."a[2]"."a[3]".100"}'`;
    
    echo -n "Enter last ip of range [$auto_last_ip]: "
    read last_ip
    if [ -z "$last_ip" ]; then

	last_ip=$auto_last_ip
    fi
    
    echo -n "Enter tftp server [$server_ip]: "
    read tftpd_ip
    if [ -z "$tftpd_ip" ]; then
	tftpd_ip=$server_ip
    fi

    backup_ext=`date +%m-%d-%Y" "%H:%M:%S`;
    rc=`cp $tftp_root/pxelinux.cfg/default "$tftp_root/pxelinux.cfg/default-$backup_ext"`;

    echo "Creating default PXE boot menu"
cat > $tftp_root/pxelinux.cfg/default << EOF
default menu.c32
prompt 0
timeout 100
MENU TITLE Our PXE Menu

LABEL centos7_x64
MENU LABEL CentOS 7
# NFS
#KERNEL netboot/centos/7/x86_64/vmlinuz ks=nfs:$server_ip:/$tftp_root/centos7-ks.cfg
# FTP
KERNEL netboot/centos/7/x86_64/vmlinuz ks=ftp://$server_ip/centos7-ks.cfg
# HTTP
#KERNEL netboot/centos/7/x86_64/vmlinuz ks=http://$server_ip/centos7-ks.cfg

APPEND console=tty0 console=ttyS0,9600N1 initrd=netboot/centos/7/x86_64/initrd.img ksdevice=link
EOF

    backup_ext=`date +%m-%d-%Y" "%H:%M:%S`;
    rc=`cp $tftp_root/centos7-ks.cfg "$tftp_root/centos7-ks.cfg-$backup_ext"`;
    echo "Creating default kickstart file"
    
cat > $tftp_root/centos7-ks.cfg << EOF
auth --enableshadow --passalgo=sha512
# cdrom
url --url ftp://$server_ip/centos
# url --url http://$server_ip/centos
# nfs --server $server_ip --dir $tftp_root/centos
# Use graphical install
graphical
# Run the Setup Agent on first boot
firstboot --enable
# ignoredisk --only-use=sda
# Keyboard layouts
keyboard --vckeymap=us --xlayouts='us'
# System language
lang en_US.UTF-8

# Network information
network  --bootproto=dhcp --device=eth0 --onboot=on --ipv6=auto --hostname=localhost.localdomain
# Root password
# rootpw --iscrypted $6$Ndp/IGYadY7ft923$hhX1/z55TJ2/8kQiu5dd41QRQW1rqhelmIMGKfHaMMW87f.XFJwJQVVNWNTuEd/pqSldEqmg1o9DANW3GEyKu/
# System timezone
timezone America/New_York --isUtc
# System bootloader configuration
bootloader --append=" crashkernel=auto" --location=mbr --boot-drive=sda
# autopart --type=lvm
# Partition clearing information
# clearpart --all --initlabel 
reboot

%packages
@core
kexec-tools

%end

%addon com_redhat_kdump --enable --reserve-mb='auto'

%end
EOF

    backup_ext=`date +%m-%d-%Y" "%H:%M:%S`;
    rc=`cp /etc/dhcp/dhcpd.conf "/etc/dhcp/dhcpd.conf-$backup_ext"`;

cat > /etc/dhcp/dhcpd.conf << EOF
option option-100 code 100 = string;
option option-128 code 128 = string;
option option-129 code 129 = text;
option option-140 code 140 = string;
option option-141 code 141 = unsigned integer 32;
option option-142 code 142 = string;
option option-143 code 143 = string;
option option-144 code 144 = string;
option option-144 "n";
option option-140 "$server_ip";

# ddns-update-style ad-hoc;
log-facility syslog;

option domain-name "$network_dn";
option domain-name-servers $dns_ip;
option subnet-mask $netmask_nm;
subnet $network netmask $netmask_nm {
    authoritative;
    range $first_ip $last_ip;
    option routers $gateway_ip;
    allow booting;
    allow bootp;
    next-server $tftpd_ip;
    filename "pxelinux.0";
}
EOF
    `systemctl enable dhcpd`
    `systemctl restart dhcpd`
    echo "DHCP configuration complete.";
}

function prepareTftp {
    echo "Setting up TFTP server and prepare tftproot directory";
    echo "";
    echo "Checking directories:"
    createDirs;
    installSoft;
    backup_ext=`date +%m-%d-%Y" "%H:%M:%S`;
    rc=`cp /etc/xinetd.d/tftp "/etc/xinetd.d/tftp-$backup_ext"`;

    echo "Creating TFTP config"
cat > /etc/xinetd.d/tftp << EOF
service tftp
{
	socket_type		= dgram
	protocol		= udp
	wait			= yes
	user			= root
	server			= /usr/sbin/in.tftpd
	server_args		= -s $tftp_root
	disable			= no
	per_source		= 11
	cps			= 100 2
	flags			= IPv4
}
EOF
    
    echo "Preparing directory";
    cp /usr/share/syslinux/{pxelinux.0,menu.c32,memdisk,mboot.c32,chain.c32} $tftp_root
    if [ ! -f "$tftp_root/netboot/centos/7/x86_64/initrd.img" ]; then
 
    echo "Check for initrd.img"
      echo "Initrd file doesn't exists. Downloading..."
      wget -q --directory-prefix=$tftp_root/netboot/centos/7/x86_64 -c ftp://ftp.ines.lug.ro/centos/7/os/x86_64/images/pxeboot/initrd.img
    else 
      echo "Initrd exist."
    fi
    echo "Check for vmlinuz"
    if [ ! -f "$tftp_root/netboot/centos/7/x86_64/vmlinuz" ]; then
      echo "Vmlinuz file doesn't exist. Downloading..."
      wget -q --directory-prefix=$tftp_root/netboot/centos/7/x86_64 -c ftp://ftp.ines.lug.ro/centos/7/os/x86_64/images/pxeboot/vmlinuz
    else
      echo "Vmlinuz exists."
    fi
    systemctl enable xinetd
    systemctl restart xinetd
    echo "Preparing TFTP complete"


};

function disableSelinux {
    echo "Disabling SElinux";
    status=`cat /etc/selinux/config |grep -w SELINUX|grep -v "#"|awk '{split($1,a,"=");print a[2]}'| tr [a-z] [A-Z]`
    if [ "$status" == "DISABLED" ]; then
	echo "SElinux already disabled"
    else
	`sed -i 's/=enforcing/=disabled/;s/=permissive/=disabled/' /etc/selinux/config`;
	echo "SElinux disabled. You must reboot server"
    fi
    setenforce 0
};

function disableFirewalld {
    echo "Disabling firewalld"
    rc=`systemctl disable firewalld`
    rc=`systemctl stop firewalld`
    fwst=`cat /etc/rc.local|grep firewalld|wc -l`
    if [ $fwst -ne 0 ]; then
	echo "Firewalld already disabled"
    else 
	echo "systemctl stop firewalld" >>/etc/rc.local
    fi
};

function enableNfs {
    echo "Enabling NFS";
    installSoft;
    rc=`cat /etc/exports|grep -w $tftp_root -c`
    if [ $rc -eq "0" ]; then 
	echo "Add access to centos via nfs"
	echo "$tftp_root		*(ro,sync,no_root_squash,no_all_squash)" >>/etc/exports
    else
	echo "NFS dir already configured"
    fi

    rc=`systemctl enable rpcbind`
    rc=`systemctl enable nfs-server`
    rc=`systemctl enable nfs-lock`
    rc=`systemctl enable nfs-idmap`

    rc=`systemctl start rpcbind`
    rcst=`cat /etc/rc.local|grep -w rpcbind|wc -l`
    if [ $rcst -ne 0 ]; then
	echo "systemctl start rpcbind" >>/etc/rc.local
    fi

    rc=`systemctl start nfs-server`
    rcst=`cat /etc/rc.local|grep -w nfs-server|wc -l`
    if [ $rcst -ne 0 ]; then
	echo "systemctl start nfs-server" >>/etc/rc.local	
    fi
    
    rc=`systemctl start nfs-lock`
    rcst=`cat /etc/rc.local|grep -w nfs-lock|wc -l`
    if [ $rcst -ne 0 ]; then
	echo "systemctl start nfs-lock" >>/etc/rc.local
    fi

    rc=`systemctl start nfs-idmap`
    rcst=`cat /etc/rc.local|grep -w nfs-idmap|wc -l`
    if [ $rcst -ne 0 ]; then
	echo "systemctl start nfs-idmap" >>/etc/rc.local	
    fi
};

function prepareFtpd {
    echo "Enabling vsftpd"
    installSoft;
    backup_ext=`date +%m-%d-%Y" "%H:%M:%S`;
    rc=`cp /etc/vsftpd/vsftpd.conf "/etc/vsftpd/vsftpd.conf-$backup_ext"`;

cat >/etc/vsftpd/vsftpd.conf <<EOF

anonymous_enable=YES
local_enable=YES
write_enable=YES
local_umask=022
dirmessage_enable=YES
xferlog_enable=YES
connect_from_port_20=YES
xferlog_std_format=YES
listen=NO
listen_ipv6=YES

pam_service_name=vsftpd
userlist_enable=YES
tcp_wrappers=YES
anon_root=$tftp_root/
EOF

    chmod a-w $tftp_root
    `systemctl enable vsftpd`
    `systemctl restart vsftpd`
}

function prepareHttpd {
    echo "Enabling httpd"
    installSoft;
    backup_ext=`date +%m-%d-%Y" "%H:%M:%S`;
    rc=`cp /etc/httpd/conf/httpd.conf "/etc/httpd/conf/httpd.conf-$backup_ext"`;
    if [ -f /etc/httpd/conf.d/welcome.conf ]; then 
	mv /etc/httpd/conf.d/welcome.conf /etc/httpd/conf.d/welcome.disable
    fi 

cat >/etc/httpd/conf/httpd.conf <<EOF
ServerRoot "/etc/httpd"
Listen 80
Include conf.modules.d/*.conf
User apache
Group apache
ServerAdmin root@localhost
<Directory />
    AllowOverride none
    Require all denied
</Directory>

DocumentRoot "$tftp_root"
<Directory "$tftp_root">
    Options +Indexes +FollowSymLinks
    AllowOverride None
    Require all granted
</Directory>
<IfModule dir_module>
    DirectoryIndex index.html
</IfModule>
<Files ".ht*">
    Require all denied
</Files>
ErrorLog "logs/error_log"
LogLevel warn
<IfModule log_config_module>
    LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"" combined
    LogFormat "%h %l %u %t \"%r\" %>s %b" common
    <IfModule logio_module>
      LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\" %I %O" combinedio
    </IfModule>
    CustomLog "logs/access_log" combined
</IfModule>
<IfModule alias_module>
    ScriptAlias /cgi-bin/ "/var/www/cgi-bin/"
</IfModule>

<Directory "/var/www/cgi-bin">
    AllowOverride None
    Options None
    Require all granted
</Directory>

<IfModule mime_module>
    TypesConfig /etc/mime.types
    AddType application/x-compress .Z
    AddType application/x-gzip .gz .tgz
    AddType text/html .shtml
    AddOutputFilter INCLUDES .shtml
</IfModule>

AddDefaultCharset UTF-8
<IfModule mime_magic_module>
    MIMEMagicFile conf/magic
</IfModule>
EnableSendfile on
IncludeOptional conf.d/*.conf

EOF

    `systemctl enable httpd`
    `systemctl restart httpd`

};

function prepareFw {
    echo "Preparing firewalld"
    firewall-cmd --permanent --zone=public --add-service=nfs
    firewall-cmd --permanent --zone=public --add-service=http
    firewall-cmd --permanent --zone=public --add-service=tftp
    firewall-cmd --permanent --zone=public --add-service=ftp
    firewall-cmd --permanent --zone=public --add-service=dhcp
    firewall-cmd --permanent --zone=public --add-port=2049/tcp
    firewall-cmd --permanent --zone=public --add-port=56584/tcp
    firewall-cmd --permanent --zone=public --add-port=56622/tcp
    firewall-cmd --permanent --zone=public --add-port=111/tcp
    firewall-cmd --permanent --zone=public --add-port=20048/tcp
    firewall-cmd --permanent --zone=public --add-port=2049/udp
    firewall-cmd --permanent --zone=public --add-port=69/udp
    firewall-cmd --permanent --zone=public --add-port=20048/udp
    firewall-cmd --permanent --zone=public --add-port=111/udp
    firewall-cmd --permanent --zone=public --add-port=659/udp
    firewall-cmd --permanent --zone=public --add-port=58681/udp
    firewall-cmd --permanent --zone=public --add-port=31045/udp
    firewall-cmd --permanent --zone=public --add-port=3449/udp
    firewall-cmd --permanent --zone=public --add-port=57722/udp
    firewall-cmd --permanent --zone=public --add-port=899/udp
    firewall-cmd --reload
    # disableFirewalld
};

function genPwd {
    echo "genpw"
};

function prepareNetwork {
    echo "Preparing network"
    prepareDhcp;
    prepareTftp;
    disableSelinux;
    prepareFw;
    enableNfs;
    prepareFtpd;
    prepareHttpd;
    netArray=("net.ipv4.ip_forward=1")
    for index in ${!netArray[*]}
    do
	rc=`cat /etc/sysctl.conf |grep ${netArray[$index]}|wc -l`
	if [ $rc -eq 0 ]; then
	    echo "Add ${netArray[$index]} in sysctl"
	    echo "${netArray[$index]}" >> /etc/sysctl.conf
	else
	    echo "${netArray[$index]} already exist"
	fi
    done
};

function prepareImage {
    echo "Preparing installation image."
    createDirs;
    if [ ! -z "$filePath" ]; then
      dtype=`echo \"$filePath\" | awk '{split($0,a,":"); print toupper(a[1])}'|sed 's/"//'`
      if [[ $dtype == "HTTP" || $dtype == "HTTPS" || $dtype == "FTP" ]]; then
        isoUrl=$filePath
      else
	isoFile=$filePath
      fi
    fi
    if [[ -z "$isoFile" ]]; then 
	echo -n "Donwload Centos 7 image from $isoUrl? (YN)[N]: "
	read yn
	if [[ $yn == "Y" || $yn == "y" ]]; then 
	    wget -c --directory-prefix=/tmp $isoUrl
	    # `echo "$isoUrl"|awk '{n=split(\$1,a,"/");print a[n]}'`
	    isoFile="/tmp/`echo "$isoUrl"|awk '{n=split(\$1,a,"/");print a[n]}'`"; 
	fi
    fi
    if [ $isoFile ]; then
	echo "Mounting $isoFile to /mnt"
	mount -o loop $isoFile /mnt
	rc=$?
	if [ $rc -eq "0" ]; then
	    echo "Mount succesful";
	    cp -fvr /mnt/* $tftp_root/centos/
	    umount /mnt
	    echo "Preparing complete";
	else
	    echo "Mount failed. Errcode = $rc";
            echo "Trying to unmount previous mount."
            umount /mnt
            rc=$?
            case "$rc" in 
              0 )
                echo "Umount successfully. Retrying..."
                prepareImage
                ;;
              * )
                echo "Umount error. Skip operation. Errcode = $rc"
              ;;
            esac
	fi
    fi
    
    # Mount errcodes:
    # 0      success
    # 1      incorrect invocation or permissions
    # 2      system error (out of memory, cannot fork, no more loop devices)
    # 4      internal mount bug
    # 8      user interrupt
    # 16     problems writing or locking /etc/mtab
    # 32     mount failure
    # 64     some mount succeeded
};

function prepareAll {
    installSoft
    prepareImage
    prepareNetwork
};


if [ $# -eq "0" ]; then
    echo "
    Use $0 script with parametrs:

    --prepareImage=[url|file]       Prepare image for PXE (Specify a URL or path to iso-image)
      By default it be downloaded from $isoUrl
    --prepareSoft                   Install necessery software
    --prepareDhcp                   Configure DHCP server
    --prepareTftp                   Configure TFTP server
    --prepareFw                     Prepare firewall
    --prepareNfs                     Configure NFS server
    --prepareFtpd                   Configure FTP server
    --prepareHttpd                  Configure HTTP server
    --prepareNetwork                Configure all (DHCP,TFTP,NFS,FTP,HTTP,Firewall)
    ";
    exit;
fi

while test $# -gt 0
do
    param1=`echo $1 |awk '{split(\$0,a,"=");print a[1]}'`
    param2=`echo $1 |awk '{split(\$0,a,"=");print a[2]}'`
    case $param1 in
        --prepareSoft)
            installSoft;
            ;;
        --prepareNetwork)
            prepareNetwork;
            ;;
        --prepareDhcp)
            prepareDhcp;
            ;;
        --prepareTftp)
            prepareTftp
            ;;
        --prepareFw)
            prepareFw;
            ;;
        --prepareNfs)
            prepareNfs;
            ;;
        --prepareFtpd)
            prepareTf3tp
            ;;
        --prepareHttpd)
            prepareHttpd;
            ;;
        --prepareImage)
            filePath=$param2;
            prepareImage;
            ;;
        *)
            echo >&2 "Invalid argument: $1"
            ;;
    esac
    shift
done
