# Usage information

def print_error_header(type)
  handle_output("")
  if type.length > 2
    handle_output("Warning:\tInvalid #{type.capitalize} specified")
  else
    handle_output("Warning:\tInvalid #{type.upcase} specified")
  end
  handle_output("")
  return
end

def error_message(type,option)
  print_error_header(type) 
  eval"[print_#{type}_types(option)]"
  exit
end

def print_arch_types(option)
  handle_output("")
  handle_output("Available Architectures:")
  handle_output("")
  handle_output("i386   - 32 bit Intel/AMD")
  handle_output("x86_64 - 64 bit Intel/AMD")
  if option["vm"] =~ /ldom|zone/
    handle_output("sparc  - 64 bit SPARC")
  end
  handle_output("")
  handle_output("Example:")
  handle_output("")
  handle_output("--arch=x86_64")
  handle_output("")
  return
end

def print_client_types(option)
  handle_output("")
  handle_output("Refer to RFC1178 for valid host names")
  handle_output("")
  handle_output("Example:")
  handle_output("")
  handle_output("--client=hostname")
  handle_output("")
  return
end

def print_vm_types(option)
  handle_output("Available VM types:")
  handle_output("")
  handle_output("vbox   - VirtualBox")
  handle_output("fusion - VMware Fusion")
  handle_output("ldom   - Solaris 10/11 LDom (Logical Domain")
  handle_output("lxc    - Linux Container")
  handle_output("zone   - Solaris 10/11 Zone/Container")
  handle_output("")
  return
end

def print_install_types(option)
  handle_output("Available OS Install Types:")
  handle_output("")
  handle_output("ai             - Automated Installer (Solaris 11)")
  handle_output("ks/kickstart   - Kickstart (RedHat, CentOS, Scientific, Fedora)")
  handle_output("js/jumpstart   - Jumpstart (Solaris 10 or earlier")
  handle_output("ps/preseed     - Preseed (Ubuntu, Debian)")
  handle_output("ay/autoyast    - Autoyast (SLES, SuSE, OpenSuSE)")
  handle_output("vs/vsphere/esx - VSphere/ESX Kickstart")
  handle_output("container      - Container (Sets install type to Zone on Solaris and LXC on Linux")
  handle_output("zone           - Zone (Sets install type to Zone on Solaris and LXC on Linux")
  handle_output("lxc            - Linux Container")
  handle_output("xb/bsd         - OpenBSD/NetBSD")
  handle_output("")
  return
end

def print_os_types()
  handle_output("Available OS Types:")
  handle_output("")
  handle_output("solaris       - Solaris (Sets install type to Jumpstart on Solaris 10, and AI on Solaris 11)")
  handle_output("ubuntu        - Ubuntu Linux (Sets install type to Preseed)")
  handle_output("debian        - Debian Linux (Sets install type to Preseed)")
  handle_output("suse          - SuSE Linux (Sets install type to Autoyast)")
  handle_output("sles          - SuSE Linux (Sets install type to Autoyast)")
  handle_output("redhat        - Redhat Linux (Sets install type to Kickstart)")
  handle_output("rhel          - Redhat Linux (Sets install type to Kickstart)")
  handle_output("centos        - CentOS Linux (Sets install type to Kickstart)")
  handle_output("fedora        - Fedora Linux (Sets install type to Kickstart)")
  handle_output("scientific/sl - Scientific Linux (Sets install type to Kickstart)")
  handle_output("vsphere/esx   - vSphere (Sets install type to Kickstart)")
  handle_output("windows       - Windows (Incomplete)")
  handle_output("")
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
            handle_output(line)
          end
        end
      end
    else
      if $verbose_mode == true
        handle_output("Warning:\tFile: #{md_file} contains no information")
      end
    end
  else
    $verbose_mode = 1
    handle_output("Warning:\tWiki directory '#{$wiki_dir}' does not exist")
    $sudo_mode = false
    message    = "Attempting to clone Wiki dir from: '"+$wiki_url+"' to: '"+$wiki_dir
    command    = "cd #{$script_dir} ; git clone #{$wiki_url}"
    execute_command(message,command)
    handle_output("")
    ptint_md(md_file)
    exit
  end
  return
end

# Detailed usage

def print_examples(install_method,install_type,install_vm)
  handle_output("")
  examples = install_method+install_type+install_vm
  if !examples.match(/[a-z,A-Z]/)
    examples = "all"
  end
  if examples.match(/iso|all/)
    print_md("ISOs")
    handle_output("")
  end
  if examples.match(/packer|all/)
    print_md("Packer")
    handle_output("")
  end
  if examples.match(/all|server|dist|setup/)
    print_md("Distribution-Server-Setup")
    handle_output("")
  end
  if examples.match(/vbox|all|virtualbox/)
    print_md("VirtualBox")
    handle_output("")
  end
  if examples.match(/fusion|all/)
    print_md("VMware-Fusion")
    handle_output("")
  end
  if examples.match(/server|ai|all/)
    print_md("AI-Server")
    handle_output("")
  end
  if examples.match(/server|ay|all/)
    print_md("AutoYast-Server")
    handle_output("")
  end
  if examples.match(/server|ks|all/)
    print_md("Kickstart-Server")
    handle_output("")
  end
  if examples.match(/server|ps|all/)
    print_md("Preseed-Server")
    handle_output("")
  end
  if examples.match(/server|xb|ob|nb|all/)
    handle_output("*BSD server related examples:")
    handle_output("")
    handle_output("List all *BSD services:")
    handle_output("#{$script} -B -S -L")
    handle_output("Configure all *BSD services:")
    handle_output("#{$script} -B -S")
    handle_output("Configure a NetBSD service (from ISO):")
    handle_output("#{$script} -B -S -f /export/isos/install55-i386.iso")
    handle_output("Configure a FreeBSD service (from ISO):")
    handle_output("#{$script} -B -S -f /export/isos/FreeBSD-10.0-RELEASE-amd64-dvd1.iso")
    handle_output("")
  end
  if examples.match(/server|js|all/)
    print_md("Jumpstart-Server")
    handle_output("")
  end
  if examples.match(/server|vs|all/)
    print_md("vSphere-Server")
    handle_output("")
  end
  if examples.match(/maint|all/)
    handle_output("Maintenance related examples:")
    handle_output("")
    handle_output("Configure AI client services:")
    handle_output("#{$script} -A -G -C -a i386")
    handle_output("Enable AI proxy:")
    handle_output("#{$script} -A -G -W -n sol_11_1")
    handle_output("Disable AI proxy:")
    handle_output("#{$script} -A -G -W -z sol_11_1")
    handle_output("Configure AI alternate repo:")
    handle_output("#{$script} -A -G -R")
    handle_output("Unconfigure AI alternate repo:")
    handle_output("#{$script} -A -G -R -z sol_11_1_alt")
    handle_output("Configure Kickstart alternate repo:")
    handle_output("#{$script} -K -G -R -n centos_5_10_x86_64")
    handle_output("Unconfigure Kickstart alternate repo:")
    handle_output("#{$script} -K -G -R -z centos_5_10_x86_64")
    handle_output("Enable Kickstart alias:")
    handle_output("#{$script} -K -G -W -n centos_5_10_x86_64")
    handle_output("Disable Kickstart alias:")
    handle_output("#{$script} -K -G -W -z centos_5_10_x86_64")
    handle_output("Import Kickstart PXE files:")
    handle_output("#{$script} -K -G -P -n centos_5_10_x86_64")
    handle_output("Delete Kickstart PXE files:")
    handle_output("#{$script} -K -G -P -z centos_5_10_x86_64")
    handle_output("Unconfigure Kickstart client PXE:")
    handle_output("#{$script} -K -G -P -d centos510vm01")
    handle_output("")
  end
  if examples.match(/zone|all/)
    handle_output("Solaris Zone related examples:")
    handle_output("")
    handle_output("List Zones:")
    handle_output("#{$script} -Z -L")
    handle_output("Configure Zone:")
    handle_output("#{$script} -Z -c sol11u01z01 -i 192.168.1.181")
    handle_output("Configure Branded Zone:")
    handle_output("#{$script} -Z -c sol10u11z01 -i 192.168.1.171 -f /export/isos/solaris-10u11-x86.bin")
    handle_output("Configure Branded Zone:")
    handle_output("#{$script} -Z -c sol10u11z02 -i 192.168.1.172 -n sol_10_11_i386")
    handle_output("Delete Zone:")
    handle_output("#{$script} -Z -d sol11u01z01")
    handle_output("Boot Zone:")
    handle_output("#{$script} -Z -b sol11u01z01")
    handle_output("Boot Zone (connect to console):")
    handle_output("#{$script} -Z -b sol11u01z01 -B")
    handle_output("Halt Zone:")
    handle_output("#{$script} -Z -s sol11u01z01")
    handle_output("")
  end
  if examples.match(/ldom|all/)
    handle_output("Oracle VM Server for SPARC related examples:")
    handle_output("")
    handle_output("Configure Control Domain:")
    handle_output("#{$script} -O -S")
    handle_output("List Guest Domains:")
    handle_output("#{$script} -O -L")
    handle_output("Configure Guest Domain:")
    handle_output("#{$script} -O -c sol11u01gd01")
    handle_output("")
  end
  if examples.match(/lxc|all/)
    handle_output("Linux Container related examples:")
    handle_output("")
    handle_output("Configure Container Services:")
    handle_output("#{$script} -Z -S")
    handle_output("List Containers:")
    handle_output("#{$script} -Z -L")
    handle_output("Configure Standard Container:")
    handle_output("#{$script} -Z -c ubuntu1310lx01 -i 192.168.1.206")
    handle_output("Execute post install script:")
    handle_output("#{$script} -Z -p ubuntu1310lx01")
    handle_output("")
  end
  if examples.match(/client|ks|all/)
    print_md("Kickstart-Client")
    handle_output("")
  end
  if examples.match(/client|ai|all/)
    print_md("AI-Client")
    handle_output("")
  end
  if examples.match(/client|xb|ob|nb|all/)
    handle_output("*BSD client related examples:")
    handle_output("")
    handle_output("List *BSD clients:")
    handle_output("#{$script} -B -C -L")
    handle_output("Create OpenBSD client:")
    handle_output("#{$script} -B -C -c openbsd55vm01 -e 00:50:56:26:92:d8 -a x86_64 -i 192.168.1.193 -n openbsd_5_5_x86_64")
    handle_output("Create FreeBSD client:")
    handle_output("#{$script} -B -C -c freebsd10vm01 -e 00:50:56:26:92:d7 -a x86_64 -i 192.168.1.194 -n netbsd_10_0_x86_64")
    handle_output("Delete FreeBSD client:")
    handle_output("#{$script} -B -C -d freebsd10vm01")
    handle_output("")
  end
  if examples.match(/client|ps|all/)
    print_md("Preseed-Client")
    handle_output("")
  end
  if examples.match(/client|js|all/)
    print_md("Jumpstart-Client")
    handle_output("")
  end
  if examples.match(/client|ay|all/)
    print_md("AutoYast-Client")
    handle_output("")
  end
  if examples.match(/client|vcsa|all/)
    print_md("VCSA-Deployment")
    handle_output("")
  end
  if examples.match(/client|vs|all/)
    print_md("vSphere-Client")
    handle_output("")
  end
  exit
end

