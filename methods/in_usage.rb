# Usage information

def print_error_header(type)
  puts
  if type.length > 2
    puts "Warning:\tInvalid "+type.capitalize+" specified"
  else
    puts "Warning:\tInvalid "+type.upcase+" specified"
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

# Print a .md file

def print_md(md_file)
  md_file = $wiki_dir+"/"+md_file+".md"
  if File.directory?($wiki_dir) or File.symlink?($wiki_dir)
    if File.exist?(md_file)
      md_info = File.readlines(md_file)
      if md_info
        md_info.each do |line,index|
          if !line.match(/\`\`\`/)
            puts line
          end
        end
      end
    else
      if $verbose_mode == 1
        puts "Warning:\tFile: "+md_file+" contains no information"
      end
    end
  else
    $verbose_mode = 1
    puts "Warning:\tWiki directory '"+$wiki_dir+"' does not exist"
    $use_sudo = 0
    message   = "Attempting to clone Wiki dir from: '"+$wiki_url+"' to: '"+$wiki_dir
    command   = "cd #{$script_dir} ; git clone #{$wiki_url}"
    execute_command(message,command)
    puts
    ptint_md(md_file)
    exit
  end
  return
end

# Detailed usage

def print_examples(install_method,install_type,install_vm)
  puts
  examples = install_method+install_type+install_vm
  if !examples.match(/[a-z,A-Z]/)
    examples = "all"
  end
  if examples.match(/iso|all/)
    print_md("ISOs")
    puts
  end
  if examples.match(/packer|all/)
    print_md("Packer")
    puts
  end
  if examples.match(/all|server|dist|setup/)
    print_md("Distribution-Server-Setup")
    puts
  end
  if examples.match(/vbox|all|virtualbox/)
    print_md("VirtualBox")
    puts
  end
  if examples.match(/fusion|all/)
    print_md("VMware-Fusion")
    puts
  end
  if examples.match(/server|ai|all/)
    print_md("AI-Server")
    puts
  end
  if examples.match(/server|ay|all/)
    print_md("AutoYast-Server")
    puts
  end
  if examples.match(/server|ks|all/)
    print_md("Kickstart-Server")
    puts
  end
  if examples.match(/server|ps|all/)
    print_md("Preseed-Server")
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
    print_md("Jumpstart-Server")
    puts
  end
  if examples.match(/server|vs|all/)
    print_md("vSphere-Server")
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
    print_md("Kickstart-Client")
    puts
  end
  if examples.match(/client|ai|all/)
    print_md("AI-Client")
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
    print_md("Preseed-Client")
    puts
  end
  if examples.match(/client|js|all/)
    print_md("Jumpstart-Client")
    puts
  end
  if examples.match(/client|ay|all/)
    print_md("AutoYast-Client")
    puts
  end
  if examples.match(/client|vcsa|all/)
    print_md("VCSA-Deployment")
    puts
  end
  if examples.match(/client|vs|all/)
    print_md("vSphere-Client")
    puts
  end
  exit
end

