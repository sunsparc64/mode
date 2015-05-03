
ESXi uses a modified form of kickstart for OS deployment.

Server commands are run on the Deployment Server. The client configuration
commands are run on the Deployment Server, and the client creation commands are
run on the host.

The commands are split into three types:

- Server configuration
  - Creating OS deployment repositories from the OS installation media (ISOs)
- Client creation
  - Creating client VMs.
- Client configuration
  - Creating client profiles
    - PXE / DHCP / BOOTP configuration
    - Install configurations
    - Post install scripts

This section refers to the server related commands. For the client related
commands refer to the [vSphere Client Examples](5.7.-vSphere-Client-Examples).

For client creation commands refer to either the [VirtualBox Examples](3.1.-VirtualBox-Examples)
or [VMware Fusion Examples](3.2.-VMware-Fusion-Examples).

By default the vSphere client creation will configure the installer to run in
text mode.

Example Server Commands
-----------------------

These commands are run on the deployment server.

Configure ESXi service:

```
# ./mode.rb --action=add --file=/export/isos/VMware/6.0/VMware-VMvisor-Installer-6.0.0-2494585.x86_64.iso
```

Unconfigure an ESXi services:

```
# modest -E -S -z vmware_5_5_0_x86_64
```

ESXi Service Configuration
--------------------------

These commands are run on the deployment server.

List available ISOs:

```
# ./mode.rb --action=list --type=iso --os=vsphere
Available ESX/vSphere ISOs:

Checking:     /export/isos
ISO file:     /export/isos/VMware-VMvisor-Installer-5.1.0-799733.x86_64.iso
Distribution: vmware
Version:      5.1.0
Release:      799733
Architecture: x86_64
Service Name: vmware_5_1_0_x86_64 (exists)

ISO file:     /export/isos/VMware-VMvisor-Installer-5.5.0-1331820.x86_64.iso
Distribution: vmware
Version:      5.5.0
Release:      1331820
Architecture: x86_64
Service Name: vmware_5_5_0_x86_64 (exists)
```

List available ESX/vSphere services:

```
# ./mode.rb --action=list --type=service --os=vsphere
VSphere services:

vmware_5_1_0_x86_64
vmware_5_5_0_x86_64
```

Configure ESX service from ISO:

```
# ./mode.rb --action=add --file=/export/isos/VMware-VMvisor-Installer-5.1.0-799733.x86_64.iso --verbose
Information:  Running in verbose mode
Information:  Home directory /root
Information:  Setting work directory to /opt/modest
Information:  Setting temporary directory to /opt/modest
Determining:  Default host IP
Executing:    ipadm show-addr net0/v4 |grep net |awk '{print $4}' |cut -f1 -d'/'
Output:       192.168.1.191
Information:  Setting apache allow range to 192.168.1
Checking:     Package lftp installed
Executing:    which lftp
Output:       /usr/bin/lftp
Information:  Setting install type to text based
Information:  Setting publisher port to 10081
Information:  Setting publisher host to 10081
Information:  Using ISO /export/isos/VMware-VMvisor-Installer-5.1.0-799733.x86_64.iso
Setting:      Architecture to x86_64
Setting:      Operating System version of container to same as host [5.11]
Checking:     DHCPd config for subnet entry
Executing:    cat /etc/inet/dhcpd4.conf | grep 'subnet 192.168.1.0'
Output:       subnet 192.168.1.0 netmask 255.255.255.0 {
Checking:     Apache confing file /etc/apache2/2.2/httpd.conf for vmware_5_1_0_x86_64
Executing:    cat /etc/apache2/2.2/httpd.conf |grep 'vmware_5_1_0_x86_64'
Archiving:    Apache config file /etc/apache2/2.2/httpd.conf to /etc/apache2/2.2/httpd.conf.no_vmware_5_1_0_x86_64
Executing:    cp /etc/apache2/2.2/httpd.conf /etc/apache2/2.2/httpd.conf.no_vmware_5_1_0_x86_64
Adding:       Directory and Alias entry to /etc/apache2/2.2/httpd.conf
Copying:      Apache config file so it can be edited
Executing:    cp /etc/apache2/2.2/httpd.conf /tmp/httpd.conf ; chown 0 /tmp/httpd.conf
Updating:     Apache config file
Executing:    cp /tmp/httpd.conf /etc/apache2/2.2/httpd.conf ; rm /tmp/httpd.conf
Checking:     Status of service svc:/network/http:apache22
Executing:    svcs svc:/network/http:apache22 |grep -v STATE
Output:       online          8:40:23 svc:/network/http:apache22
Refresh:      Service svc:/network/http:apache22
Executing:    svcadm refresh svc:/network/http:apache22 ; sleep 5
Warning:      /export/repo/vmware_5_1_0_x86_64 does not exist
Executing:    zfs create rpool/export/repo/vmware_5_1_0_x86_64
Information:  VMware repository being mounted under /etc/netboot/vmware_5_1_0_x86_64
Executing:    zfs set mountpoint-/etc/netboot/vmware_5_1_0_x86_64 rpool/export/repo/vmware_5_1_0_x86_64
Information:  Symlinking /etc/netboot/vmware_5_1_0_x86_64 to /export/repo/vmware_5_1_0_x86_64
Executing:    ln -s /etc/netboot/vmware_5_1_0_x86_64 /export/repo/vmware_5_1_0_x86_64
Checking:     Directory /export/repo/vmware_5_1_0_x86_64/upgrade exists
Processing:   /export/isos/VMware-VMvisor-Installer-5.1.0-799733.x86_64.iso
Checking:     Existing mounts
Executing:    df |awk '{print $1}' |grep '^/cdrom$'
Mounting:     ISO /export/isos/VMware-VMvisor-Installer-5.1.0-799733.x86_64.iso on /cdrom
Executing:    mount -F hsfs /export/isos/VMware-VMvisor-Installer-5.1.0-799733.x86_64.iso /cdrom
Checking:     If we can copy data from full repo ISO
Creating:     /etc/netboot/vmware_5_1_0_x86_64/upgrade
Executing:    mkdir -p '/etc/netboot/vmware_5_1_0_x86_64/upgrade'
Copying:      /cdrom contents to /etc/netboot/vmware_5_1_0_x86_64
Executing:    rsync -a /cdrom/* /etc/netboot/vmware_5_1_0_x86_64
Unmounting:   ISO mounted on /cdrom
Executing:    umount /cdrom
Locating:     Syslinux package
Executing:    ls /opt/modest/rpms |grep 'syslinux-[0-9]'
Output:       syslinux-4.02-7.2.el5.i386.rpm
Copying:      PXE boot files from /opt/modest/rpms/syslinux-4.02-7.2.el5.i386.rpm to /etc/netboot/vmware_5_1_0_x86_64
Executing:    cd /etc/netboot/vmware_5_1_0_x86_64 ; /opt/modest/bin/rpm2cpio /opt/modest/rpms/syslinux-4.02-7.2.el5.i386.rpm | cpio -iud
4163 blocks
```

Delete ESX/vSphere service:

```
# ./mode.rb --action=delete --service=vmware_5_1_0_x86_64 --verbose --yes
Information:  Running in verbose mode
Information:  Home directory /root
Information:  Setting work directory to /opt/modest
Information:  Setting temporary directory to /opt/modest
Determining:  Default host IP
Executing:    ipadm show-addr net0/v4 |grep net |awk '{print $4}' |cut -f1 -d'/'
Output:       192.168.1.191
Information:  Setting apache allow range to 192.168.1
Checking:     Package lftp installed
Executing:    which lftp
Output:       /usr/bin/lftp
Information:  Setting service name to vmware_5_1_0_x86_64
Information:  Setting install type to text based
Information:  Setting publisher port to 10081
Information:  Setting publisher host to 10081
Setting:      Architecture to x86_64
Setting:      Operating System version of container to same as host [5.11]
Checking:     DHCPd config for subnet entry
Executing:    cat /etc/inet/dhcpd4.conf | grep 'subnet 192.168.1.0'
Output:       subnet 192.168.1.0 netmask 255.255.255.0 {
Checking:     Apache confing file /etc/apache2/2.2/httpd.conf for vmware_5_1_0_x86_64
Executing:    cat /etc/apache2/2.2/httpd.conf |grep 'vmware_5_1_0_x86_64'
Output:       <Directory /export/repo/vmware_5_1_0_x86_64>
Output:       Alias /vmware_5_1_0_x86_64 /export/repo/vmware_5_1_0_x86_64
Restoring:    /etc/apache2/2.2/httpd.conf.no_vmware_5_1_0_x86_64 to /etc/apache2/2.2/httpd.conf
Executing:    cp /etc/apache2/2.2/httpd.conf.no_vmware_5_1_0_x86_64 /etc/apache2/2.2/httpd.conf
Refresh:      Service svc:/network/http:apache22
Executing:    svcadm refresh svc:/network/http:apache22 ; sleep 5
Warning:      Destroying /export/repo/vmware_5_1_0_x86_64
Executing:    zfs destroy -r rpool/export/repo/vmware_5_1_0_x86_64
Removing:     Symlink /export/repo/vmware_5_1_0_x86_64
Executing:    rm /export/repo/vmware_5_1_0_x86_64
Removing:     Directory /etc/netboot/vmware_5_1_0_x86_64
Executing:    rmdir /etc/netboot/vmware_5_1_0_x86_64
```
