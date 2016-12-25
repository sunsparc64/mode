# Parallels VM support code

# Add CDROM to Parallels VM

def attach_file_to_parallels_vm(install_client,install_file)
  message = "Information:\tAttaching Image "+install_file+" to "+install_client
  command = "prlctl set \"#{install_client}\" --device-set cdrom0 --image \"#{install_file}\""
  execute_command(message,command)
  return
end

# Detach CDROM from Parallels VM

def detach_file_from_parallels_vm(install_client)
  message = "Information:\tAttaching Image "+install_file+" to "+install_client
  command = "prlctl set \"#{install_client}\" --device-set cdrom0 --disable\""
  execute_command(message,command)
  return
end

# Get Parallels VM OS

def get_parallels_os(vm_name)
	message = "Information:\tDetermining OS for "+vm_name
	command = "prlctl list --info \"#{vm_name}\" |grep '^OS' |cut -f2 -d:"
	os_info = execute_command(message,command)
	case os_info
	when /rhel/
		os_info = "RedHat Enterprise Linux"
	end
	return os_info
end

# Get Parallels VM status

def get_parallels_vm_status(install_client)
  message = "Information:\tDetermining status of Parallels VM "+install_client
  command = "prlctl list \"#{install_client}\" --info |grep '^Status' |grep ^State |cut -f2 -d:"
  status  = execute_command(message,command)
  status  = status.chomp.gsub(/\s+/,"")
  return status
end

# Get a list of all VMs

def get_all_parallels_vms()
  message = "Information:\tListing Parallels VMs"
  command = "prlctl list --all |grep -v UUID |awk '{print $4}'"
  vm_list = execute_command(message,command)
  vm_list = vm_list.split("\n")
  return vm_list
end

# List all VMs

def list_all_parallels_vms()
  vm_list = get_all_parallels_vms()
  handle_output("") 
  handle_output("Parallels VMS:")
  handle_output("") 
  vm_list.each do |vm_name|
    os_info = %x[prlctl list --info "#{vm_name}" |grep '^OS' |cut -f2 -d:].chomp.gsub(/^\s+/,"")
    case os_info
    when /rhel/
    	os_info = "RedHat Enterprise Linux"
    end
    handle_output("#{vm_name}\t#{os_info}")
  end
  handle_output("") 
  return
end

# List running VMs

def list_running_parallels_vms()
  message = "Information:\tListing running VMs"
  command = "prlctl list --all |grep running |awk '{print $4}'"
	vm_list = execute_command(message,command)
  vm_list = vm_list.split("\n")
  handle_output("") 
  handle_output("Running Parallels VMS:")
  handle_output("") 
  vm_list.each do |vm_name|
    os_info = get_parallels_os(vm_name)
    handle_output("#{vm_name}\t#{os_info}")
  end
  handle_output("") 
  return
end

# List stopped VMs

def list_stopped_parallels_vms()
  message = "Information:\tListing stopped VMs"
  command = "prlctl list --all |grep stopped |awk '{print $4}'"
  vm_list = execute_command(message,command)
  vm_list = vm_list.split("\n")
  vm_list = %x[prlctl list --all |grep stopped |awk '{print $4}'].split("\n")
  handle_output("") 
  handle_output("Stopped Parallels VMS:")
  handle_output("") 
  vm_list.each do |vm_name|
    os_info = get_parallels_os(vm_name)
    handle_output("#{vm_name}\t#{os_info}")
  end
  handle_output("") 
  return
end

# List Parallels VMs

def list_parallels_vms(search_string)
  dom_type    = "Parallels VM"
  dom_command = "prlctl list --all |grep -v UUID |awk '{print $4}'"
  list_doms(dom_type,dom_command)
  return
end

# Clone Parallels VM

def clone_parallels_vm(install_client,new_name,install_mac,client_ip)
  exists = check_parallels_vm_exists(install_client)
  if exists.match(/no/)
    handle_output("Warning:\tParallels VM #{install_client} does not exist")
    exit
  end
  message = "Information:\tCloning Parallels VM "+install_client+" to "+new_name
  command = "prlctl clone \"#{install_client}\" --name \"#{new_name}\""
  execute_command(message,command)
  if client_ip.match(/[0-9]/)
    add_hosts_entry(new_name,client_ip)
  end
  if install_mac.match(/[0-9,a-z,A-Z]/)
    change_parallels_vm_mac(new_name,install_mac)
  end
  return
end

# Get Parallels VM disk

def get_parallels_disk(install_client)
  message = "Information:\tDetermining directory for Parallels VM "+install_client
  command = "prlctl list #{install_client} --info |grep image |awk '{print $4}' |cut -f2 -d="
  vm_dir  = execute_command(message,command)
  vm_dir  = vm_dir.chomp.gsub(/'/,"")
  return vm_dir
end

# Get Parallels VM UUID

def get_parallels_vm_uuid(install_client)
  message = "Information:\tDetermining UUID for Parallels VM "+install_client
  command = "prlctl list --info \"#{install_client}\" |grep '^ID' |cut -f2 -d:"
  vm_uuid = vm_uuid.chomp.gsub(/^\s+/,"")
  vm_uuid = execute_command(message,command)
  return vm_uuid
end

# Check Parallels hostonly network

def check_parallels_hostonly_network()
  message = "Information:\tChecking Parallels hostonly network exists"
  command = "prlsrvctl net list |grep ^prls |grep host-only |awk '{print $1}'"
  if_name = execute_command(message,command)
  if_name = if_name.chomp
  if !if_name.match(/prls/)
    message  = "Information:\tDetermining possible Parallels host-only network interface name"
    command  = "prlsrvctl net list |grep ^prls"
    if_count = execute_command(message,command)
    if_count = if_count.grep(/prls/).count.to_s
    if_name  = "prlsnet"+if_count
    message = "Information:\tPlumbing Parallels hostonly network "+if_name
    command = "prlsrvctl net add #{if_name} --type host-only"
    execute_command(message,command)
  end
  message  = "Information:\tDetermining Parallels network interface name"
  command  = "prlsrvctl net list |grep ^#{if_name} |awk '{print $3}'"
  nic_name = execute_command(message,command)
  nic_name = nic_name.chomp
  message = "Information:\tChecking Parallels hostonly network "+nic_name+" has address "+$default_hostonly_ip
  command = "ifconfig #{nic_name} |grep inet |awk '{print $2}"
  host_ip = execute_command(message,command)
  host_ip = host_ip.chomp
  if !host_ip.match(/#{$default_hostonly_ip}/)
    message = "Information:\tConfiguring Parallels hostonly network "+nic_name+" with IP "+$default_hostonly_ip
    command = "sudo sh -c 'ifconfig #{nic_name} inet #{$default_hostonly_ip} netmask #{$default_netmask} up'"
    execute_command(message,command)
  end
  gw_if_name = get_osx_gw_if_name()
  if $os_rel.split(".")[0].to_i < 14
    check_osx_nat(gw_if_name,if_name)
  else
    check_osx_pfctl(gw_if_name,if_name)
  end
	return nic_name
end

# Get Parallels VM directory

def get_parallels_vm_dir(install_client)
	return vm_dir
end

# Control Parallels VM

def control_parallels_vm(install_client,install_status)
  current_status = get_parallels_vm_status(install_client)
  if !current_status.match(/#{install_status}/)
    message = "Information:\tSetting Parallels VM status for "+install_client+" to "+
    if install_status.match(/stop/)
      command = "prlctl #{install_status} \"#{install_client}\" --kill"
    else
      command = "prlctl #{install_status} \"#{install_client}\""
    end
    execute_command(message,command)
  end
  return
end

# Stop Parallels VM

def stop_parallels_vm(install_client)
  control_parallels_vm(install_client,"stop")
  return
end

# Stop Parallels VM

def restart_parallels_vm(install_client)
  control_parallels_vm(install_client,"stop")
  boot_parallels_vm(install_client)
  return
end

# Routine to add serial to a VM

def add_serial_to_parallels_vm(install_client)
  message = "Information:\tAdding Serial Port to "+install_client
  command = "prlctl set \"#{install_client}\" --add-device serial --ouput /tmp/#{install_client}"
  execute_command(message,command)
  return
end

# Configure a Generic Virtual Box VM

def configure_other_parallels_vm(install_client,install_mac,install_arch,install_os,install_release,install_size,install_file,install_memory,install_cpu,install_network,install_share,install_mount)
  install_os="other"
  configure_parallels_vm(install_client,install_mac,install_os,install_size,install_file,install_memory,install_cpu,install_network,install_share,install_mount)
  return
end

# Configure a AI Virtual Box VM

def configure_ai_parallels_vm(install_client,install_mac,install_arch,install_os,install_release,install_size,install_file,install_memory,install_cpu,install_network,install_share,install_mount)
  install_os="solaris-11"
  configure_parallels_vm(install_client,install_mac,install_os,install_size,install_file,install_memory,install_cpu,install_network,install_share,install_mount)
  return
end

# Configure a Jumpstart Virtual Box VM

def configure_js_parallels_vm(install_client,install_mac,install_arch,install_os,install_release,install_size,install_file,install_memory,install_cpu,install_network,install_share,install_mount)
  install_os = "solaris-10"
  configure_parallels_vm(install_client,install_mac,install_os,install_size,install_file,install_memory,install_cpu,install_network,install_share,install_mount)
  return
end

# Configure a RedHat or Centos Kickstart Parallels VM

def configure_ks_parallels_vm(install_client,install_mac,install_arch,install_os,install_release,install_size,install_file,install_memory,install_cpu,install_network,install_share,install_mount)
  install_os = "rhel"
  configure_parallels_vm(install_client,install_mac,install_os,install_size,install_file,install_memory,install_cpu,install_network,install_share,install_mount)
  return
end

# Configure a Preseed Ubuntu Parallels VM

def configure_ps_parallels_vm(install_client,install_mac,install_arch,install_os,install_release,install_size,install_file,install_memory,install_cpu,install_network,install_share,install_mount)
  install_os = "ubuntu"
  configure_parallels_vm(install_client,install_mac,install_os,install_size,install_file,install_memory,install_cpu,install_network,install_share,install_mount)
  return
end

# Configure a AutoYast SuSE Parallels VM

def configure_ay_parallels_vm(install_client,install_mac,install_arch,install_os,install_release,install_size,install_file,install_memory,install_cpu,install_network,install_share,install_mount)
  install_os = "opensuse"
  configure_parallels_vm(install_client,install_mac,install_os,install_size,install_file,install_memory,install_cpu,install_network,install_share,install_mount)
  return
end

# Configure a vSphere Parallels VM

def configure_vs_parallels_vm(install_client,install_mac,install_arch,install_os,install_release,install_size,install_file,install_memory,install_cpu,install_network,install_share,install_mount)
  install_os = "other"
  configure_parallels_vm(install_client,install_mac,install_os,install_size,install_file,install_memory,install_cpu,install_network,install_share,install_mount)
  return
end

# Configure an OpenBSD VM

def configure_ob_parallels_vm(install_client,install_mac,install_arch,install_os,install_release,install_size,install_file,install_memory,install_cpu,install_network,install_share,install_mount)
  install_os = "freebsd-4"
  configure_parallels_vm(install_client,install_mac,install_os,install_size,install_file,install_memory,install_cpu,install_network,install_share,install_mount)
  return
end

# Configure a NetBSD VM

def configure_nb_parallels_vm(install_client,install_mac,install_arch,install_os,install_release,install_size,install_file,install_memory,install_cpu,install_network,install_share,install_mount)
  install_os = "freebsd-4"
  configure_parallels_vm(install_client,install_mac,install_os,install_size,install_file,install_memory,install_cpu,install_network,install_share,install_mount)
  return
end

# Change Parallels VM Memory

def change_parallels_vm_mem(install_client,install_memory)
  message = "Information:\tSetting Parallels VM "+install_client+" RAM to "+install_memory
  command = "prlctl set #{install_client} --memsize #{install_memory}"
  execute_command(message,command)
  return
end

# Change Parallels VM Cores

def change_parallels_vm_cpu(install_client,install_cpu)
  message = "Information:\tSetting Parallels VM "+install_client+" CPUs to "+install_cpu
  command = "prlctl set #{install_client} --cpus #{install_cpus}"
  execute_command(message,command)
  return
end

# Change Parallels VM MAC address

def change_parallels_vm_mac(install_client,install_mac)
  message = "Information:\tSetting Parallels VM "+install_client+" MAC address to "+install_mac
  if install_mac.match(/:/)
    install_mac = install_mac.gsub(/:/,"")
  end
  command = "prlctl set #{install_client} --device-set net0 #{install_mac}"
  execute_command(message,command)
  return
end

# Get Parallels VM MAC address

def get_parallels_vm_mac(install_client)
  message = "Information:\tGetting MAC address for "+install_client
  command = "prlctl list --info #{install_client} |grep net0 |grep mac |awk '{print $4}' |cut -f2 -d="
  vm_mac  = execute_command(message,command)
  vm_mac  = vm_mac.chomp
  vm_mac  = vm_mac.gsub(/\,/,"")
  return vm_mac
end

# Check Parallels is installed

def check_parallels_is_installed()
  install_status = "no"
  app_dir = "/Applications/Parallels Desktop.app"
  if File.directory?(app_dir)
    install_status = "yes"
  end
  return install_status
end

# Boot Parallels VM

def boot_parallels_vm(install_client)
  check_parallels_hostonly_network()
  exists = check_parallels_vm_exists(install_client)
  if exists.match(/no/)
    handle_output("Warning:\tParallels VM #{install_client} does not exist")
    exit
  end
  message = "Starting:\tVM "+install_client
  if $text_mode == true or $serial_mode == true
    handle_output("") 
    handle_output("Information:\tBooting and connecting to virtual serial port of #{install_client}")
    handle_output("") 
    handle_output("To disconnect from this session use CTRL-Q")
    handle_output("") 
    handle_output("If you wish to re-connect to the serial console of this machine,")
    handle_output("run the following command")
    handle_output("") 
    handle_output("socat UNIX-CONNECT:/tmp/#{install_client} STDIO,raw,echo=0,escape=0x11,icanon=0")
    handle_output("") 
    %x[prlctl start #{install_client}]
  else
    command = "prlctl start #{install_client} ; open \"/Applications/Parallels Desktop.app\" &"
    execute_command(message,command)
  end
  if $serial_mode == true
    system("socat UNIX-CONNECT:/tmp/#{install_client} STDIO,raw,echo=0,escape=0x11,icanon=0")
  else
    handle_output("") 
    handle_output("If you wish to connect to the serial console of this machine,")
    handle_output("run the following command")
    handle_output("") 
    handle_output("socat UNIX-CONNECT:/tmp/#{install_client} STDIO,raw,echo=0,escape=0x11,icanon=0")
    handle_output("") 
    handle_output("To disconnect from this session use CTRL-Q")
    handle_output("") 
    handle_output("") 
  end
  return
end

# Routine to register a Parallels VM

def register_parallels_vm(install_client,install_os)
  message = "Registering Parallels VM "+install_client
  command = "prlctl create \"#{install_client}\" --ostype \"#{install_os}\""
  execute_command(message,command)
  return
end

# Configure a Parallels VM

def configure_parallels_vm(install_client,install_mac,install_os,install_size,install_file,install_memory,install_cpu,install_network)
  check_parallels_is_installed()
  if $default_vm_network.match(/hostonly/)
    nic_name = check_parallels_hostonly_network()
  end
  disk_name   = get_parallels_disk(install_client)
  socket_name = "/tmp/#{install_client}"
  check_parallels_vm_doesnt_exist(install_client)
  register_parallels_vm(install_client,install_os)
  add_serial_to_parallels_vm(install_client)
  change_parallels_vm_mem(install_client,install_memory)
  change_parallels_vm_cpu(install_client,install_cpu)
  if install_file.match(/[0-9]|[a-z]/)
    attach_file_to_parallels_vm(install_client,install_file)
  end
  if install_mac.match(/[0-9]/)
    change_parallels_vm_mac(install_client,install_mac)
  else
    install_mac = get_parallels_vm_mac(install_client)
  end
  handle_output("Created Parallels VM #{install_client} with MAC address #{install_mac}")
  return
end

# List Linux KS Parallels VMs

def list_ks_parallels_vms()
  search_string = "rhel|fedora|fc|centos|redhat|mandriva"
  list_parallels_vms(search_string)
  return
end

# List Linux Preseed Parallels VMs

def list_ps_parallels_vms()
  search_string = "ubuntu|debian"
  list_parallels_vms(search_string)
end

# List Solaris Kickstart Parallels VMs

def list_js_parallels_vms()
  search_string = "solaris-10"
  list_parallels_vms(search_string)
  return
end

# List Solaris AI Parallels VMs

def list_ai_parallels_vms()
  search_string = "solaris-11"
  list_parallels_vms(search_string)
  return
end

# List Linux Autoyast Parallels VMs

def list_ay_parallels_vms()
  search_string = "opensuse"
  list_parallels_vms(search_string)
  return
end

# List vSphere Parallels VMs

def list_vs_parallels_vms()
  search_string = "other"
  list_parallels_vms(search_string)
  return
end

# Check Parallels VM doesn't exit

def check_parallels_vm_doesnt_exist(install_client)
  exists = check_parallels_vm_exists(install_client)
  if exists.match(/yes/)
    handle_output("Parallels VM #{install_client} already exists")
    exit
  end
  return
end

# Check Parallels VM exists

def check_parallels_vm_exists(install_client)
  set_vmrun_bin()
  exists  = "no"
  vm_list = get_all_parallels_vms()
  vm_list.each do |vm_name|
    if vm_name.match(/^#{install_client}$/)
      exists = "yes"
      return exists
    end
  end
  return exists
end

# Unconfigure a Parallels VM

def unconfigure_parallels_vm(install_client)
  check_parallels_is_installed()
  exists = check_parallels_vm_exists(install_client)
  if exists.match(/no/)
    handle_output("Parallels VM #{install_client} does not exist")
    exit
  end
  stop_parallels_vm(install_client)
  sleep(5)
  message = "Deleting Parallels VM "+install_client
  command = "prlctl delete #{install_client}"
  execute_command(message,command)
  return
end

