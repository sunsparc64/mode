# Usage information

def print_error_header(type)
  puts
  if type.length > 2
    puts "Invalid "+type.capitalize+" specified"
  else
    puts "Invalid "+type.upcase+" specified"
  end
  puts
  return
end

def error_message(type,option)
  print_error_header(type) 
  eval"[print_#{type}_types(option)]"
  exit
end

def print_arch_types(option)
  puts
  puts "Available Architectures:"
  puts
  puts "i386   - 32 bit Intel/AMD"
  puts "x86_64 - 64 bit Intel/AMD"
  if option["vm"] =~ /ldom|zone/
    puts "sparc  - 64 bit SPARC"
  end
  puts
  puts "Example:"
  puts
  puts "--arch=x86_64"
  puts
  return
end

def print_client_types(option)
  puts
  puts "Refer to RFC1178 for valid host names"
  puts
  puts "Example:"
  puts 
  puts "--client=hostname"
  puts
  return
end

def print_vm_types(option)
  puts "Available VM types:"
  puts
  puts "vbox   - VirtualBox"
  puts "fusion - VMware Fusion"
  puts "ldom   - Solaris 10/11 LDom (Logical Domain"
  puts "lxc    - Linux Container"
  puts "zone   - Solaris 10/11 Zone/Container"
  puts
  return
end

def print_install_types(option)
  puts "Available OS Install Types:"
  puts
  puts "ai             - Automated Installer (Solaris 11)"
  puts "ks/kickstart   - Kickstart (RedHat, CentOS, Scientific, Fedora)"
  puts "js/jumpstart   - Jumpstart (Solaris 10 or earlier"
  puts "ps/preseed     - Preseed (Ubuntu, Debian)"
  puts "ay/autoyast    - Autoyast (SLES, SuSE, OpenSuSE)"
  puts "vs/vsphere/esx - VSphere/ESX Kickstart"
  puts "container      - Container (Sets install type to Zone on Solaris and LXC on Linux"
  puts "zone           - Zone (Sets install type to Zone on Solaris and LXC on Linux"
  puts "lxc            - Linux Container"
  puts "xb/bsd         - OpenBSD/NetBSD"
  puts
  return
end

def print_os_types()
  puts "Available OS Types:"
  puts
  puts "solaris       - Solaris (Sets install type to Jumpstart on Solaris 10, and AI on Solaris 11)"
  puts "ubuntu        - Ubuntu Linux (Sets install type to Preseed)"
  puts "debian        - Debian Linux (Sets install type to Preseed)"
  puts "suse          - SuSE Linux (Sets install type to Autoyast)"
  puts "sles          - SuSE Linux (Sets install type to Autoyast)"
  puts "redhat        - Redhat Linux (Sets install type to Kickstart)"
  puts "rhel          - Redhat Linux (Sets install type to Kickstart)"
  puts "centos        - CentOS Linux (Sets install type to Kickstart)"
  puts "fedora        - Fedora Linux (Sets install type to Kickstart)"
  puts "scientific/sl - Scientific Linux (Sets install type to Kickstart)"
  puts "vsphere/esx   - vSphere (Sets install type to Kickstart)"
  puts "windows       - Windows (Incomplete)"
  puts
  return
end

# Detailed usage

def print_examples(install_method,install_type,install_vm)
  puts
  examples = install_method+install_type+install_vm
  if !examples.match(/[A-z]/)
    examples = "all"
  end
  if examples.match(/iso|all/)
    puts
    puts "ISO/Image related examples"
    puts
    puts "List Linux ISOs:"
    puts
    puts $script+" --os=linux --action=list --type=iso"
    puts
    puts "List Solaris 10 (Jumpstart) ISOs:"
    puts
    puts $script+" --os=solaris --method=jumstart --type=iso"
    puts $script+" --os=solaris --release=10 --type=iso"
    puts
    puts "List Solaris 11 (AI) ISOs:"
    puts
    puts $script+" --os=solaris --method=ai --type=iso"
    puts $script+" --os=solaris --release=11 --type=iso"
    puts
  end
  if examples.match(/vbox|all/)
    puts
    puts "VirtualBox related examples"
    puts
    puts "Creating Kickstart (CentOS, Scientific, RedHat Enterprise, Fedora, Oracle Enterprise) Linux VirtualBox VM examples:"
    puts
    puts $script+" --action=create --method=kickstart --vm=vbox --client=centos510vm01 --arch=x86_64 --mac=00:50:56:34:4E:7A"
    puts $script+" --action=create --os=rhel --vm=vbox --client=centos510vm01 --arch=x86_64 --mac=00:50:56:34:4E:7A"
    puts
    puts "Create Preseed (Ubuntu, Debian) Linux VirtualBox VM:"
    puts    
    puts $script+" --action=create --method=preseed --vm=vbox --client=ubuntu1310vm01 --arch=x86_64 --mac=08:00:27:BA:34:7C"
    puts $script+" --action=create --os=ubuntu --vm=vbox --client=ubuntu1310vm01 --arch=x86_64 --mac=08:00:27:BA:34:7C"
    puts
    puts "Create AutoYast (SuSE Enterprise, OpenSuSE) Linux VirtualBox VM:"
    puts
    puts $script+" --action=create --method=autoyast --vm=vbox -client=sles11sp2vm01 --arch=x86_64 --mac=08:00:27:BA:34:7D"
    puts $script+" --action=create --os=sles --vm=vbox -client=sles11sp2vm01 --arch=x86_64 --mac=08:00:27:BA:34:7D"
    puts
    puts "Create Jumpstart (Solaris 2.6 - 10) VirtualBox VM:"
    puts
    puts $script+" --action=create --method=jumstart --vm=vbox --client=sol10u11vm01 --arch=i386 --mac=00:0C:29:FA:0C:7F"
    puts $script+" --action=create --os=solaris --release=10 --vm=vbox --client=sol10u11vm01 --arch=i386 --mac=00:0C:29:FA:0C:7F"
    puts
    puts "Create AI (Solaris 11) VirtualBox VM:"
    puts
    puts $script+" --action=create --method=ai --vm=vbox --client=sol11u01vm03 --arch=i386 --mac=00:50:56:26:92:D8"
    puts $script+" --action=create --os=solaris --release=11 --vm=vbox --client=sol11u01vm03 --arch=i386 --mac=00:50:56:26:92:D8"
    puts
    puts "Create vSphere (ESXi) VirtualBox VM:"
    puts
    puts $script+" --action=create --os=vmware --vm=vbox --client=vmware55vm01 --arch=x86_64 --mac=08:00:27:61:B7:AD"
    puts
    puts "Create OpenBSD VirtualBox VirtualBox VM:"
    puts
    puts $script+" --action=create --os=openbsd --vm=vbox --client=openbsd55vm01 --arch=x86_64 --mac=08:00:27:61:B7:AA"
    puts
    puts "Create NetBSD VirtualBox VirtualBox VM:"
    puts
    puts $script+" --action=create --os=netbsd --vm=vbox --client=netbsd10vm01 --arch=x86_64 --mac=08:00:27:61:B7:AB"
    puts
    puts "Delete Kickstart (Linux) VirtualBox VM:"
    puts
    puts $script+" --action=delete --vm=vbox --client=centos510vm01"
    puts
    puts "Delete Jumpstart (Solaris 10) VirtualBox VM:"
    puts
    puts $script+" -action=delete --vm=vbox --client=sol10u11vm01"
    puts
    puts "Delete AI (Solaris 11) VirtualBox VM:"
    puts
    puts $script+" --action=delete --vm=vbox --client=sol11u01vm03"
    puts
    puts "Delete vSphere (ESXi) VirtualBox VM:"
    puts
    puts $script+" --action=delete --vm=vbox --client=vmware55vm01"
    puts
    puts "Boot headless Linux VirtualBox VM:"
    puts
    puts $script+" --action=boot --vm=vbox --client=centos510vm01"
    puts
    puts "Boot headless serial enabled Linux VirtualBox VM:"
    puts
    puts $script+" --action=boot --vm=vbox --console=serial --client=centos510vm01"
    puts
    puts "Boot non headless Linux VirtualBox VM:"
    puts
    puts $script+" --action=boot --vm=vbox --console=headless --client=centos510vm01"
    puts
    puts "Connect to serial port of running VirtualBox VM:"
    puts
    puts $script+" --action=serial --client=centos510vm01"
    puts
    puts "Halt Linux VirtualBox VM:"
    puts
    puts $script+" --action=stop --vm=vbox --client=centos510vm01"
    puts
    puts "Modify VirtualBox VM MAC Address:"
    puts
    puts $script+" --action=change --client=centos510vm01 --mac=00:50:56:34:4E:7A"
    puts
    puts "Check VirtualBox Configuration:"
    puts
    puts $script+" --action=check --vm=vbox"
    puts
    puts "List running VirtualBox VMs:"
    puts
    puts $script+" --action=running --vm=vbox"
    puts
    puts "Snapshot VirtualBox VMs:"
    puts
    puts $script+" --action=snapshot --vm=vbox --client=centos510vm01"
    puts
  end
  if examples.match(/fusion|all/)
    puts
    puts "VMware Fusion related examples"
    puts
    puts "Creating Kickstart (CentOS, Scientific, RedHat Enterprise, Fedora, Oracle Enterprise) VMware Fusion VM examples:"
    puts
    puts $script+" --action=create --method=kickstart --vm=fusion ==client=centos510vm01 --arch=x86_64 --mac=00:50:56:34:4E:7A"
    puts $script+" --action=create --os=centos --vm=fusion ==client=centos510vm01 --arch=x86_64 --mac=00:50:56:34:4E:7A"
    puts
    puts "Create Preseed (Ubuntu, Debian) Linux VMware Fusion VM:"
    puts
    puts $script+" --action=create --method=preseed --vm=fusion --client=ubuntu1310vm01 --arch x86_64 -mac=08:00:27:BA:34:7C"
    puts $script+" --action=create --os=ubuntu --vm=fusion --client=ubuntu1310vm01 --arch x86_64 -mac=08:00:27:BA:34:7C"
    puts
    puts "Create AutoYast (SuSE, OpenSuSE) Linux VMware Fusion VM:"
    puts
    puts $script+" --action=create --method=autoyast --vm=fusion --client=sles11sp2vm01 --arch=x86_64 --mac=08:00:27:BA:34:7D"
    puts $script+" --action=create --os=sles --vm=fusion --client=sles11sp2vm01 --arach=x86_64 --mac=08:00:27:BA:34:7D"
    puts
    puts "Create Jumpstart (Solaris 2.6 - 10) VMware Fusion VM:"
    puts
    puts $script+" --action=create --method=jumpstart --vm=fusion --client=sol10u11vm01 --arch=i386 --mac=00:0C:29:FA:0C:7F"
    puts $script+" --action=create --os=solaris --release--vm=fusion --client=sol10u11vm01 --arch=i386 --mac=00:0C:29:FA:0C:7F"
    puts
    puts "Create AI (Solaris 11) VMware Fusion VM:"
    puts
    puts $script+" --action=create --method=ai --vm=fusion --client=sol11u01vm03 --mac=00:50:56:26:92:D8"
    puts $script+" --action=create --os=solaris --release=11 --vm=fusion --client=sol11u01vm03 --mac=00:50:56:26:92:D8"
    puts
    puts "Create vSphere (ESXi) VMware Fusion VM:"
    puts
    puts $script+" --action=create --method=vsphere --vm=fusion --client=vmware55vm01 --mac=00:50:56:26:92:D8"
    puts $script+" --action=create --os=vsphere --vm=fusion --client=vmware55vm01 --mac=00:50:56:26:92:D8"
    puts
    puts "Create Windows VMware Fusion VM:"
    puts
    puts $script+" --action=create --method=windows --vm=fusion --client=win2008r2vm01 --mac=08:00:27:61:B7:AF"
    puts
    puts "Create OpenBSD VMware Fusion VM:"
    puts
    puts $script+" --action=create --os=openbsd --client=openbsd55vm01 --mac=08:00:27:61:B7:AA"
    puts $script+" --action=create --method=bsd --client=openbsd55vm01 --mac=08:00:27:61:B7:AA"
    puts
    puts "Create NetBSD VMware Fusion VM:"
    puts
    puts $script+" --action=create --os=netbsd --client=netbsd10vm01 --mac=08:00:27:61:B7:AA"
    puts $script+" --action=create --method=bsd --client=netbsd10vm01 --mac=08:00:27:61:B7:AA"
    puts
    puts "Delete Kickstart (CentOS, Scientific, RedHat Enterprise, Fedora, Oracle Enterprise) Linux VMware Fusion VM:"
    puts
    puts $script+" --action=delete --vm=fusion --client=centos510vm01"
    puts
    puts "Delete Jumpstart (Solaris 2.6 - 10) VMware Fusion VM:"
    puts
    puts $script+" --action=delete --vm=fusion --client=sol10u11vm01"
    puts
    puts "Delete AI (Solaris 11) VMware Fusion VM:"
    puts
    puts $script+" --action=delete --vm=fusion --client=sol11u01vm03"
    puts
    puts "Delete vSphere (ESXi) VMware Fusion VM:"
    puts
    puts $script+" --action=delete --vm=fusion --client=vmware55vm01"
    puts
    puts "Boot headless Linux VMware Fusion VM:"
    puts
    puts $script+" --action=boot --vm=fusion --client=centos510vm01 --console=headless"
    puts
    puts "Boot headless serial enabled Linux VMware Fusion VM:"
    puts
    puts $script+" --action=boot --vm=fusion --client=centos510vm01 --console=serial"
    puts
    puts "Boot non headless (default boot mode) Linux VMware Fusion VM:"
    puts
    puts $script+" --action=boot --vm=fusion --client=centos510vm01"
    puts $script+" --action=boot --vm=fusion --client=centos510vm01 --console=text"
    puts
    puts "Halt/Pause Linux VMware Fusion VM:"
    puts
    puts $script+" --action=halt --vm=fusion --client=centos510vm01"
    puts $script+" --action=pause --vm=fusion --client=centos510vm01"
    puts
    puts "Boot Windows VMware Fusion VM:"
    puts
    puts $script+" --action=boot --vm=fusion --client=win2008r2vm01"
    puts
    puts "Stop Windows VMware Fusion VM:"
    puts
    puts $script+" --action=stop --vm=fusion --client=win2008r2vm01"
    puts
    puts "Resume Windows VMware Fusion VM:"
    puts
    puts $script+" --action=resume --vm=fusion --client=win2008r2vm01"
    puts
    puts "Modify VMware Fusion VM MAC Address:"
    puts
    puts $script+" --action=modify --vm=fusion --client=centos510vm01 --mac=00:50:56:34:4E:7A"
    puts $script+" --action=change --vm=fusion --client=centos510vm01 --mac=00:50:56:34:4E:7A"
    puts
    puts "Attach CDROM to Fusion VM:"
    puts
    puts $script+" --action=attach --vm=fusion --client=sol11u2vm01 --file=/isos/sol-11_2-text-x86.iso"
    puts
    puts "Detach CDROM to Fusion VM:"
    puts
    puts $script+" --action=detach --vm=fusion --client=sol11u2vm01"
    puts
  end
  if examples.match(/server|ai|all/)
    puts
    puts "AI server related examples"
    puts
    puts "List AI services:"
    puts
    puts $script+" --action=list --method=ai"
    puts
    puts "Configure all AI services:"
    puts
    puts $script+" --action=add --method=ai"
    puts
    puts "Unconfigure AI service:"
    puts
    puts $script+" --action=delete --method=ai --service=sol_11_1"
    puts
  end
  if examples.match(/server|ks|all/)
    puts "Kickstart server related examples"
    puts
    puts "List Kickstart services:"
    puts
    puts $script+" --action=list --method=kickstart"
    puts
    puts "List Kickstart ISOs:"
    puts
    puts $script+" --action=list --method=kickstart --type=iso"
    puts
    puts "Configure all Kickstart services (Service names will be automatically created):"
    puts
    puts $script+" --action=add --method=kickstart"
    puts
    puts "Configure Kickstart service from ISO (Service name will be automatically created):"
    puts
    puts $script+" --action=add --method=iso --type=iso --file=/export/isos/Fedora-20-x86_64-DVD.iso"
    puts $script+" --action=add --type=iso --file=/export/isos/Fedora-20-x86_64-DVD.iso"
    puts $script+" --action=add --file=/export/isos/Fedora-20-x86_64-DVD.iso"
    puts
    puts "Unconfigure Kickstart service:"
    puts
    puts $script+" --action=delete --method=kickstart --service=centos_5_10_i386"
    puts
    puts "Delete Kickstart service:"
    puts
    puts $script+" -K -S -z centos_5_10_i386 -y"
    puts
  end
  if examples.match(/server|ay|all/)
    puts "AutoYast server related examples:"
    puts
    puts "List Autoyast services:"
    puts $script+" -Y -S -L"
    puts "Configure Autoyast services:"
    puts $script+" -Y -S"
    puts "Configure Autoyast service (from ISO):"
    puts $script+" -Y -S -f /export/isos/SLES-11-SP2-DVD-x86_64-GM-DVD1.iso"
    puts
  end
  if examples.match(/server|ps|all/)
    puts "Preseed server related examples:"
    puts
    puts "List all Preseed services:"
    puts $script+" -U -S -L"
    puts "Configure all Preseed services:"
    puts $script+" -U -S"
    puts "Configure a Preseed service (from ISO):"
    puts $script+" -U -S -f /export/isos/ubuntu-13.10-server-amd64.iso"
    puts
  end
  if examples.match(/server|xb|ob|nb|all/)
    puts "*BSD server related examples:"
    puts
    puts "List all *BSD services:"
    puts $script+" -B -S -L"
    puts "Configure all *BSD services:"
    puts $script+" -B -S"
    puts "Configure a NetBSD service (from ISO):"
    puts $script+" -B -S -f /export/isos/install55-i386.iso"
    puts "Configure a FreeBSD service (from ISO):"
    puts $script+" -B -S -f /export/isos/FreeBSD-10.0-RELEASE-amd64-dvd1.iso"
    puts
  end
  if examples.match(/server|js|all/)
    puts "Jumpstart server related examples:"
    puts
    puts "List Jumpstart services:"
    puts $script+" -J -S -L"
    puts "Configure Jumpstart services:"
    puts $script+" -J -S"
    puts "Unconfigure Jumpstart service:"
    puts $script+" -J -S -z sol_10_11"
    puts
  end
  if examples.match(/server|vs|all/)
    puts "ESX/vSphere server related examples"
    puts
    puts "List vSphere ISOs:"
    puts $script+" -E -S -I"
    puts "List vSphere services:"
    puts $script+" -E -S -L"
    puts "Configure all vSphere services:"
    puts $script+" -E -S"
    puts "Configure vSphere service (from ISO):"
    puts $script+" -E -S -f /export/isos/VMware-VMvisor-Installer-5.5.0.update01-1623387.x86_64.iso"
    puts
  end
  if examples.match(/maint|all/)
    puts "Maintenance related examples:"
    puts
    puts "Configure AI client services:"
    puts $script+" -A -G -C -a i386"
    puts "Enable AI proxy:"
    puts $script+" -A -G -W -n sol_11_1"
    puts "Disable AI proxy:"
    puts $script+" -A -G -W -z sol_11_1"
    puts "Configure AI alternate repo:"
    puts $script+" -A -G -R"
    puts "Unconfigure AI alternate repo:"
    puts $script+" -A -G -R -z sol_11_1_alt"
    puts "Configure Kickstart alternate repo:"
    puts $script+" -K -G -R -n centos_5_10_x86_64"
    puts "Unconfigure Kickstart alternate repo:"
    puts $script+" -K -G -R -z centos_5_10_x86_64"
    puts "Enable Kickstart alias:"
    puts $script+" -K -G -W -n centos_5_10_x86_64"
    puts "Disable Kickstart alias:"
    puts $script+" -K -G -W -z centos_5_10_x86_64"
    puts "Import Kickstart PXE files:"
    puts $script+" -K -G -P -n centos_5_10_x86_64"
    puts "Delete Kickstart PXE files:"
    puts $script+" -K -G -P -z centos_5_10_x86_64"
    puts "Unconfigure Kickstart client PXE:"
    puts $script+" -K -G -P -d centos510vm01"
    puts
  end
  if examples.match(/zone|all/)
    puts "Solaris Zone related examples:"
    puts
    puts "List Zones:"
    puts $script+" -Z -L"
    puts "Configure Zone:"
    puts $script+" -Z -c sol11u01z01 -i 192.168.1.181"
    puts "Configure Branded Zone:"
    puts $script+" -Z -c sol10u11z01 -i 192.168.1.171 -f /export/isos/solaris-10u11-x86.bin"
    puts "Configure Branded Zone:"
    puts $script+" -Z -c sol10u11z02 -i 192.168.1.172 -n sol_10_11_i386"
    puts "Delete Zone:"
    puts $script+" -Z -d sol11u01z01"
    puts "Boot Zone:"
    puts $script+" -Z -b sol11u01z01"
    puts "Boot Zone (connect to console):"
    puts $script+" -Z -b sol11u01z01 -B"
    puts "Halt Zone:"
    puts $script+" -Z -s sol11u01z01"
    puts
  end
  if examples.match(/ldom|all/)
    puts "Oracle VM Server for SPARC related examples:"
    puts
    puts "Configure Control Domain:"
    puts $script+" -O -S"
    puts "List Guest Domains:"
    puts $script+" -O -L"
    puts "Configure Guest Domain:"
    puts $script+" -O -c sol11u01gd01"
    puts
  end
  if examples.match(/lxc|all/)
    puts "Linux Container related examples:"
    puts
    puts "Configure Container Services:"
    puts $script+" -Z -S"
    puts "List Containers:"
    puts $script+" -Z -L"
    puts "Configure Standard Container:"
    puts $script+" -Z -c ubuntu1310lx01 -i 192.168.1.206"
    puts "Execute post install script:"
    puts $script+" -Z -p ubuntu1310lx01"
    puts
  end
  if examples.match(/client|ks|all/)
    puts "Kickstart client creation related examples:"
    puts
    puts "List Kickstart clients:"
    puts $script+" -K -C -L"
    puts "Create Kickstart client:"
    puts $script+" -K -C -c centos510vm01 -e 00:50:56:34:4E:7A -a x86_64 -i 192.168.1.194 -n centos_5_10_x86_64"
    puts "Create Kickstart client:"
    puts $script+" -K -C -c centos65vm01 -e 00:50:56:34:4E:7B -a x86_64 -i 192.168.1.184 -n centos_6_5_x86_64"
    puts "Create Kickstart client:"
    puts $script+" -K -C -c sl64vm01 -e 00:50:56:34:4E:FB -a x86_64 -i 192.168.1.185 -n sl_6_4_x86_64"
    puts "Create Kickstart client:"
    puts $script+" -K -C -c oel65vm01 -e 00:50:56:34:4E:BB -a x86_64 -i 192.168.1.186 -n oel_6_5_x86_64"
    puts "Create Kickstart client:"
    puts $script+" -K -C -c rhel63vm01 -e 00:50:56:34:4E:AA -a x86_64 -i 192.168.1.187 -n rhel_6_3_x86_64"
    puts "Create Kickstart client:"
    puts $script+" -K -C -c rhel70vm01 -e 00:50:56:34:4E:AB -a x86_64 -i 192.168.1.188 -n rhel_7_0_x86_64"
    puts "Create Kickstart client:"
    puts $script+" -K -C -c fedora20vm01 -e 00:50:56:34:4E:AC -a x86_64 -i 192.168.1.189 -n fedora_20_x86_64"
    puts
    puts "Kickstart client modification examples:"
    puts
    puts "Configure Kickstart client PXE:"
    puts $script+" -K -P -c centos510vm01 -e 00:50:56:34:4E:7A -i 192.168.1.194 -n centos_5_10_x86_64"
    puts
    puts "Kickstart client deletion related examples:"
    puts
    puts "Delete Kickstart client:"
    puts $script+" -K -C -d centos510vm01"
    puts "Delete Kickstart client:"
    puts $script+" -K -C -d centos65vm01"
    puts "Delete Kickstart client:"
    puts $script+" -K -C -d sl64vm01"
    puts "Delete Kickstart client:"
    puts $script+" -K -C -d oel65vm01"
    puts
  end
  if examples.match(/client|ai|all/)
    puts "AI client related examples:"
    puts
    puts "List AI clients:"
    puts $script+" -A -C -L"
    puts "Create AI client:"
    puts $script+" -A -C -c sol11u01vm03 -e 00:50:56:26:92:d8 -a i386 -i 192.168.1.193"
    puts "Delete AI client:"
    puts $script+" -A -C -d sol11u01vm03"
    puts
  end
  if examples.match(/client|xb|ob|nb|all/)
    puts "*BSD client related examples:"
    puts
    puts "List *BSD clients:"
    puts $script+" -B -C -L"
    puts "Create OpenBSD client:"
    puts $script+" -B -C -c openbsd55vm01 -e 00:50:56:26:92:d8 -a x86_64 -i 192.168.1.193 -n openbsd_5_5_x86_64"
    puts "Create FreeBSD client:"
    puts $script+" -B -C -c freebsd10vm01 -e 00:50:56:26:92:d7 -a x86_64 -i 192.168.1.194 -n netbsd_10_0_x86_64"
    puts "Delete FreeBSD client:"
    puts $script+" -B -C -d freebsd10vm01"
    puts
  end
  if examples.match(/client|ps|all/)
    puts "Preseed client related examples:"
    puts
    puts "List Preseed clients:"
    puts $script+" -U -C -L"
    puts "Create Preseed client:"
    puts $script+" -U -C -c ubuntu1310vm01 -e 08:00:27:BA:34:7C -a x86_64 -i 192.168.1.196 -n ubuntu_13_10_x86_64"
    puts "Delete Preseed client:"
    puts $script+" -U -C -d ubuntu1310vm01"
    puts
  end
  if examples.match(/client|js|all/)
    puts "Jumpstart client related examples:"
    puts
    puts "List Jumpstart clients:"
    puts $script+" -J -C -L"
    puts "Create Jumpstart client:"
    puts $script+" -J -C -c sol10u11vm01 -e 00:0C:29:FA:0C:7F -a i386 -i 192.168.1.195 -n sol_10_11"
    puts "Delete Jumpstart client:"
    puts $script+" -J -C -d sol10u11vm01"
    puts
  end
  if examples.match(/client|ay|all/)
    puts "AutoYast client related examples:"
    puts
    puts "List Autoyast clients:"
    puts $script+" -Y -C -L"
    puts "Create Autoyast client:"
    puts $script+" -Y -C -c sles11sp2vm01 -e 08:00:27:BA:34:7D -a x86_64 -i 192.168.1.197 -n sles_11_2_x86_64"
    puts "Delete Autoyast client:"
    puts $script+" -Y -C -d sles11sp2vm01"
    puts
  end
  if examples.match(/client|vs|all/)
    puts "ESX/vSphere client related examples:"
    puts
    puts "List vSphere clients:"
    puts $script+" -E -C -L"
    puts "Create vSphere client:"
    puts $script+" -E -C -c vmware55vm01 -e 08:00:27:61:B7:AD -i 192.168.1.195 -n vmware_5_5_0_x86_64"
    puts "Delete vSphere client:"
    puts $script+" -E -C -d vmware55vm01"
    puts
  end
  exit
end

