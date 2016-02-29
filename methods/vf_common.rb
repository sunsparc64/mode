# VMware Fusion support code

# Deploy Fusion VM

def deploy_fusion_vm(install_server,install_datastore,install_server_admin,install_server_password,install_server_network,install_client,
                     install_size,install_root_password,install_timeserver,install_admin_password,install_domainname,install_sitename,
                     install_ipfamily,install_mode,install_ip,install_netmask,install_gateway,install_nameserver,install_service,install_file)
  return
end

# Set Fusion dir

def set_fusion_dir()
  $fusion_dir=$home_dir+"/Documents/Virtual Machines.localized"
  if !File.directory?($fusion_dir)
    $fusion_dir=$home_dir+"/Documents/Virtual Machines"
  end
end

# Show VM config

def show_fusion_vm_config(install_client)
  fusion_vmx_file = get_fusion_vm_vmx_file(install_client)
  if File.exist?(fusion_vmx_file)
    file_data = %x[cat "#{fusion_vmx_file}"]
    puts file_data
  else
    puts "Warning:\tFusion VM config file "+fusion_vmx_file+" does not exit"
  end
  return
end

# Import Packer Fusion VM image

def import_packer_fusion_vm(install_client,install_vm)
  (exists,images_dir) = check_packer_vm_image_exists(install_client,install_vm)
  if exists.match(/no/)
    puts "Warning:\tPacker Fusion VM image for "+install_client+" does not exist"
    exit
  end
  fusion_vm_dir,fusion_vmx_file,fusion_disk_file = check_fusion_vm_doesnt_exist(install_client) 
  check_dir_exists(fusion_vm_dir)
  message = "Information:\tCopying Packer VM images from \""+images_dir+"\" to \""+fusion_vm_dir+"\""
  command = "cp '#{images_dir}'/* '#{fusion_vm_dir}'"
  execute_command(message,command)
  return
end

# Migrate Fusion VM

def migrate_fusion_vm(install_client,install_server,install_serveradmin,install_serverpassword,install_servernetwork,install_datastore)
  exists = check_fusion_vm_exists(install_client)
  if exists.match(/no/)
    puts "Warning:\tFusion VM "+install_client+" does not exist"
    exit
  end
  local_vmx_file   = get_fusion_vm_vmx_file(install_client)
  local_vmdk_file  = get_fusion_vm_vmdk_file(install_client)
  if !File.exist?(local_vmx_file) or !File.exist?(local_vmdk_file)
    puts "Warning:\tVMware config or disk file for "+install_client+" does not exist"
    exit
  end
  remote_vmx_file  = File.basename(local_vmx_file)
  remote_vmx_file  = "/vmfs/volumes/"+install_datastore+"/"+install_client+"/"+remote_vmx_file
  fixed_vmx_file   = local_vmx_file+".esx"
  create_fusion_vm_esx_file(install_client,local_vmx_file,fixed_vmx_file)
  remote_vmdk_file = File.basename(local_vmdk_file)
  remote_vmdk_dir  = "/vmfs/volumes/"+install_datastore+"/"+install_client
  remote_vmdk_file = remote_vmdk_dir+"/"+remote_vmdk_file+".old"
  command = "mkdir "+remote_vmdk_dir
  execute_ssh_command(install_server,install_serveradmin,install_serverpassword,command)
  scp_file(install_server,install_serveradmin,install_serverpassword,fixed_vmx_file,remote_vmx_file)
  scp_file(install_server,install_serveradmin,install_serverpassword,local_vmdk_file,remote_vmdk_file)
  import_esx_disk(install_client,install_server,install_serveradmin,install_serverpassword,install_datastore,remote_vmx_file,remote_vmdk_file)
  import_esx_vm(install_server,install_serveradmin,install_serverpassword,remote_vmx_file)
  return
end

# Delete Fusion VM snapshot

def delete_fusion_vm_snapshot(install_client,install_clone)
  clone_list = []
  if install_clone.match(/\*/) or install_clone.match(/all/)
    clone_list = get_fusion_vm_snapshots(install_client)
    clone_list = clone_list.split("\n")[1..-1]
  else
    clone_list[0] = install_clone
  end
  clone_list.each do |install_clone|
    fusion_vmx_file = get_fusion_vm_vmx_file(install_client)
    message = "Information:\tDeleting snapshot "+install_clone+" for Fusion VM "+install_client
    command = "'#{$vmrun_bin}' -T fusion deleteSnapshot '#{fusion_vmx_file}' '#{install_clone}'"
    execute_command(message,command)
  end
  return
end

# Get a list of Fusion VM snapshots for a client

def get_fusion_vm_snapshots(install_client)
  fusion_vmx_file = get_fusion_vm_vmx_file(install_client)
  message = "Information:\tGetting a list of snapshots for Fusion VM "+install_client
  command = "'#{$vmrun_bin}' -T fusion listSnapshots '#{fusion_vmx_file}'"
  output  = execute_command(message,command)
  return output
end

# List all Fusion VM snapshots

def list_all_fusion_vm_snapshots()
  vm_list = get_available_fusion_vms()
  vm_list.each do |vmx_file|
    install_client = File.basename(vmx_file,".vmx")
    list_fusion_vm_snapshots(install_client)
  end
  return
end

# List Fusion VM snapshots

def list_fusion_vm_snapshots(install_client)
  snapshot_list = get_fusion_vm_snapshots(install_client)
  puts snapshot_list 
  return
end


# Get a value from a Fusion VM vmx file

def get_fusion_vm_vmx_file_value(install_client,install_search)
  vm_value  = ""
  vmx_file  = get_fusion_vm_vmx_file(install_client)
  if File.exist?(vmx_file)
    if File.readable?(vmx_file)
      vm_config = ParseConfig.new(vmx_file)
      vm_value  = vm_config[install_search]
    else
      vm_value = "File Not Readable"
    end
  else
    if $verbose_mode == 1
      puts "Warning:\tWMware configuration file \""+vmx_file+"\" not found for client"
    end
  end
  return vm_value
end

# Get Fusion VM OS

def get_fusion_vm_os(install_client)
  install_search = "guestOS"
  install_os = get_fusion_vm_vmx_file_value(install_client,install_search)
  return install_os
end

# List all Fusion VMs

def list_all_fusion_vms()
  puts
  puts "VMware Fusion VMs:"
  puts
  install_os  = ""
  install_mac = ""
  file_list   = Dir.entries($fusion_dir)
  file_list.each do |entry|
    if entry.match(/vmwarevm/)
      install_client = entry.gsub(/\.vmwarevm/,"")
      install_os     = get_fusion_vm_os(install_client)
      install_mac    = get_fusion_vm_mac(install_client)
      if !install_os
        install_os = "unknown"
      end
      puts install_client+" os="+install_os+" mac="+install_mac
    end
  end
  puts
  return
end

# List available VMware Fusion VMs

def list_fusion_vms(search_string)
  output_list = []
  install_os  = ""
  install_mac = ""
  file_list   = Dir.entries($fusion_dir)
  file_list.each do |entry|
    if entry.match(/vmwarevm/)
      install_client = entry.gsub(/\.vmwarevm/,"")
      install_mac    = get_fusion_vm_mac(install_client)
      install_os     = get_fusion_vm_os(install_client)
      output         = install_client+" os="+install_os+" mac="+install_mac
      if search_string
        if output.match(/#{search_string}/)
          output_list.push(output)
        end
      else
        output_list.push(output)
      end
    end
  end
  if output_list.length > 0
    puts
    puts "Available "+search_string+" VMs:"
    puts
    output_list.each do |output|
      puts output
    end
    puts
  end
  return
end

# Get Fusion VM vmx file location

def get_fusion_vm_vmx_file(install_client)
  fusion_vm_dir = $fusion_dir+"/"+install_client+".vmwarevm"
  if File.directory?(fusion_vm_dir)
    fusion_vmx_file  = Dir.entries(fusion_vm_dir).grep(/vmx$/)[0].chomp
  else
    fusion_vmx_file = ""
  end
  fusion_vmx_file = fusion_vm_dir+"/"+fusion_vmx_file
  return fusion_vmx_file
end

# Get Fusion VM vmdk file location

def get_fusion_vm_vmdk_file(install_client)
  fusion_vm_dir = $fusion_dir+"/"+install_client+".vmwarevm"
  if File.directory?(fusion_vm_dir)
    fusion_vmdk_file = Dir.entries(fusion_vm_dir).grep(/vmdk$/)[0].chomp
  else
    fusion_vmdk_file = ""
  end
  fusion_vmdk_file = fusion_vm_dir+"/"+fusion_vmdk_file
  return fusion_vmdk_file
end

# Snapshot Fusion VM

def snapshot_fusion_vm(install_client,install_clone)
  exists = check_fusion_vm_exists(install_client)
  if exists.match(/no/)
    puts "Warning:\tFusion VM "+install_client+" does not exist"
    exit
  end
  fusion_vmx_file = get_fusion_vm_vmx_file(install_client)
  message = "Information:\tCloning Fusion VM "+install_client+" to "+install_clone
  command = "'#{$vmrun_bin}' -T fusion snapshot '#{fusion_vmx_file}' '#{install_clone}'"
  execute_command(message,command)
  return
end

# Get VMware version

def get_fusion_version()
  message = "Determining:\tVMware Version"
  command = "defaults read \"/Applications/VMware Fusion.app/Contents/Info.plist\" CFBundleShortVersionString"
  version = execute_command(message,command)
  version = version.chomp
  return version
end

# Get/set vmrun path

def set_vmrun_bin()
  $vmrun_bin = "/Applications/VMware Fusion.app/Contents/Library/vmrun"
  if !File.exist?($vmrun_bin)
    puts "Warning:\tCould not find vmrun"
    exit
  end
  return
end

# Get/set ovftool path

def set_ovftool_bin()
  $ovftool_bin = "/Applications/VMware Fusion.app/Contents/Library/VMware OVF Tool/ovftool"
  if !File.exist?($ovftool_bin)
    puts "Warning:\tCould not find ovftool"
    exit
  end
  return
end

# Get list of running vms

def get_running_fusion_vms()
  vm_list = %x["#{$vmrun_bin}" list |grep vmx].split("\n")
  return vm_list
end

# List running VMs

def list_running_fusion_vms()
  vm_list = get_running_fusion_vms()
  puts
  puts "Running VMs:"
  puts
  vm_list.each do |vm_name|
    vm_name = File.basename(vm_name,".vmx")
    puts vm_name
  end
  puts
  return
end

# Export OVA

def export_fusion_ova(install_client,install_file)
  exists = check_fusion_vm_exists(install_client)
  if exists.match(/yes/)
    stop_vbox_vm(install_client)
    if !install_file.match(/[0-9,a-z,A-Z]/)
      install_file = "/tmp/"+install_client+".ova"
      puts "Warning:\tNo ouput file given"
      puts "Information:\tExporting VM "+install_client+" to "+install_file
    end
    if !install_file.match(/\.ova$/)
      install_file = install_file+".ova"
    end
    message = "Information:\tExporting VMware Fusion VM "+install_client+" to "+fusion_vmx_file
    command = "\"#{$ovftool_bin}\" --acceptAllEulas --name=\"#{install_client}\" \"#{fusion_vmx_file}\" \"#{install_file}\""
    execute_command(message,command)
  else
    message = "Information:\tExporting VMware Fusion VM "+install_client+" to "+fusion_vmx_file
    command = "\"#{$ovftool_bin}\" --acceptAllEulas --name=\"#{install_client}\" \"#{fusion_vmx_file}\" \"#{install_file}\""
    execute_command(message,command)
  end
  return
end

# Import OVA

def import_fusion_ova(install_client,install_mac,install_ip,install_file)
  set_ovftool_bin()
  fusion_vm_dir   = $fusion_dir+"/"+install_client+".vmwarevm"
  fusion_vmx_file = fusion_vm_dir+"/"+install_client+".vmx"
  if !File.exist?(fusion_vmx_file)
    puts "Warning:\tWMware configuration file for client does not exist"
  end
  exists = check_fusion_vm_exists(install_client)
  if exists.match(/no/)
    if !install_file.match(/\//)
      install_file = $iso_base_dir+"/"+install_file
    end
    if File.exist?(install_file)
      if install_client.match(/[0-9,a-z,A-Z]/)
        if !File.directory?(fusion_vm_dir)
          Dir.mkdir(fusion_vm_dir)
        end
        message = "Information:\tImporting VMware Fusion VM "+install_client+" from "+fusion_vmx_file
        command = "\"#{$ovftool_bin}\" --acceptAllEulas --name=\"#{install_client}\" \"#{install_file}\" \"#{fusion_vmx_file}\""
        execute_command(message,command)
      else
        install_client = %x["#{$ovftool_bin}" "#{install_file}" |grep Name |tail -1 |cut -f2 -d:].chomp
        install_client = install_client.gsub(/\s+/,"")
        fusion_vmx_file = fusion_vm_dir+"/"+install_client+".vmx"
        if !install_client.match(/[0-9,a-z,A-Z]/)
          puts "Warning:\tCould not determine VM name for Virtual Appliance "+install_file
          exit
        else
          install_client = install_client.split(/Suggested VM name /)[1].chomp
          if !File.directory?(fusion_vm_dir)
            Dir.mkdir(fusion_vm_dir)
          end
          message = "Information:\tImporting VMware Fusion VM "+install_client+" from "+fusion_vmx_file
          command = "\"#{$ovftool_bin}\" --acceptAllEulas --name=\"#{install_client}\" \"#{install_file}\" \"#{fusion_vmx_file}\""
          execute_command(message,command)
        end
      end
    else
      puts "Warning:\tVirtual Appliance "+install_file+"does not exist"
    end
  else
    puts "Warning:\tVMware Fusion VM "+install_client+" does not exist"
  end
  if install_ip.match(/[0-9]/)
    add_hosts_entry(install_client,install_ip)
  end
  if install_mac.match(/[0-9]|[A-F]|[a-f]/)
    change_fusion_vm_mac(install_client,install_mac)
  else
    install_mac = get_fusion_vm_mac(install_client)
    if !install_mac
      install_mac = generate_mac_address()
    end
  end
  change_fusion_vm_network(install_client,$default_vm_network)
  puts "Information:\tVirtual Appliance "+install_file+" imported with VM name "+install_client+" and MAC address "+install_mac
  return
end

# List Solaris ESX VirtualBox VMs

def list_vs_fusion_vms()
  search_string = "vmware"
  list_fusion_vms(search_string)
  return
end

# List Linux KS VMware Fusion VMs

def list_ks_fusion_vms()
  search_string = "rhel|centos|oel"
  list_fusion_vms(search_string)
  return
end

# List Linux Preseed VMware Fusion VMs

def list_ps_fusion_vms()
  search_string = "ubuntu"
  list_fusion_vms(search_string)
  return
end

# List Linux AutoYast VMware Fusion VMs

def list_ay_fusion_vms()
  search_string = "sles|suse"
  list_fusion_vms(search_string)
  return
end

# List Solaris Kickstart VMware Fusion VMs

def list_js_fusion_vms()
  search_string = "solaris10"
  list_fusion_vms(search_string)
  return
end

# List Solaris AI VMware Fusion VMs

def list_ai_fusion_vms()
  search_string = "solaris11"
  list_fusion_vms(search_string)
  return
end

# Check Fusion VM MAC address

def check_fusion_vm_mac(install_mac)
  if install_mac.gsub(/:/,"").match(/^08/)
    puts "Warning:\tInvalid MAC address: "+install_mac
    install_mac = generate_mac_address()
    puts "Information:\tGenerated new MAC address: "+install_mac
  end
  return install_mac
end

# Get Fusion VM MAC address

def get_fusion_vm_mac(install_client)
  install_mac    = ""
  install_search = "ethernet0.address"
  install_mac    = get_fusion_vm_vmx_file_value(install_client,install_search)
  if !install_mac
    install_search = "ethernet0.generatedAddress"
    install_mac    = get_fusion_vm_vmx_file_value(install_client,install_search)
  end
  return install_mac
end

# Change VMware Fusion VM MAC address

def change_fusion_vm_mac(install_client,install_mac)
  (fusion_vm_dir,fusion_vmx_file,fusion_disk_file) = check_fusion_vm_doesnt_exist(install_client)
  if !File.exist?(fusion_vmx_file)
    puts "Warning:\tFusion VM "+install_client+" does not exist "
    exit
  end
  copy=[]
  file=IO.readlines(fusion_vmx_file)
  file.each do |line|
    if line.match(/generatedAddress/)
      copy.push("ethernet0.address = \""+install_mac+"\"\n")
    else
      if line.match(/ethernet0\.address/)
        copy.push("ethernet0.address = \""+install_mac+"\"\n")
      else
        copy.push(line)
      end
    end
  end
  File.open(fusion_vmx_file,"w") {|file_data| file_data.puts copy}
  return
end

# Change VMware Fusion VM CDROM

def attach_file_to_fusion_vm(install_client,install_file,install_type)
  fusion_vm_dir    = $fusion_dir+"/"+install_client+".vmwarevm"
  fusion_vmx_file  = fusion_vm_dir+"/"+install_client+".vmx"
  if !File.exist?(fusion_vmx_file)
    puts "Warning:\tFusion VM "+install_client+" does not exist "
    exit
  end
  if $verbose_mode == 1
    puts "Information:\tAttaching file "+install_file+" to "+install_client
    puts "Information:\tModifying file \""+fusion_vmx_file+"\""
  end
  copy=[]
  file=IO.readlines(fusion_vmx_file)
  file.each do |line|
    (item,value) = line.split(/\=/)
    item = item.gsub(/\s+/,"")
    case item
    when /ide0:0.deviceType|ide0:0.startConnected/
      copy.push("ide0:0.deviceType = cdrom-image\n")
    when /ide0:0.filename|ide0:0.autodetect/
      copy.push("ide0:0.filename = #{install_file}\n")
    else
      copy.push(line)
    end
  end
  File.open(fusion_vmx_file,"w") {|file_data| file_data.puts copy}
  return
end

# Detach VMware Fusion VM CDROM

def detach_file_from_fusion_vm(install_client)
  if $verbose_mode == 1
    puts "Information:\tDetaching CDROM from "+install_client
  end
  fusion_vm_dir    = $fusion_dir+"/"+install_client+".vmwarevm"
  fusion_vmx_file  = fusion_vm_dir+"/"+install_client+".vmx"
  copy=[]
  file=IO.readlines(fusion_vmx_file)
  file.each do |line|
    (item,value) = line.split(/\=/)
    item = item.gsub(/\s+/,"")
    case item
    when "ide0:0.deviceType"
      copy.push("ide0:0.startConnected = TRUE\n")
    when "ide0:0.filename"
      copy.push("\n")
    else
      copy.push(line)
    end
  end
  File.open(fusion_vmx_file,"w") {|file_data| file_data.puts copy}
  return
end

# Check Fusion hostonly networking

def check_fusion_hostonly_network(if_name)
  config_file     = "/Library/Preferences/VMware Fusion/networking"
  network_address = $default_hostonly_ip.split(/\./)[0..2].join(".")+".0"
  gw_if_name      = get_osx_gw_if_name()
  dhcp_test  = 0
  vmnet_test = 0
  copy = []
  file = IO.readlines(config_file)
  file.each do |line|
    case line
    when /answer VNET_1_DHCP /
      if !line.match(/no/)
        dhcp_test = 1
        copy.push("answer VNET_1_DHCP no")
      else
        copy.push(line)
      end
    when /answer VNET_1_HOSTONLY_SUBNET/
      if !line.match(/#{network_address}/)
        dhcp_test = 1
        copy.push("answer VNET_1_HOSTONLY_SUBNET #{network_address}")
      else
        copy.push(line)
      end
    else
      copy.push(line)
    end
  end
  message = "Information:\tChecking vmnet interfaces are plumbed"
  command = "ifconfig -a |grep vmnet"
  output  = execute_command(message,command)
  if !output.match(/vmnet/)
    vmnet_test = 1
  end
  if dhcp_test == 1 or vmnet_test == 1
    vmnet_cli = "/Applications/VMware Fusion.app/Contents/Library/vmnet-cli"
    temp_file = "/tmp/networking"
    File.open(temp_file,"w") {|file_data| file_data.puts copy}
    message = "Information:\tConfiguring host only network on #{if_name} for network #{network_address}"
    command = "sudo sh -c 'cp #{temp_file} \"#{config_file}\"'"
    execute_command(message,command)
    message = "Information:\tConfiguring VMware network"
    command = "sudo sh -c '\"#{vmnet_cli}\" --configure'"
    execute_command(message,command)
    message = "Information:\tStopping VMware network"
    command = "sudo sh -c '\"#{vmnet_cli}\" --stop'"
    execute_command(message,command)
    message = "Information:\tStarting VMware network"
    command = "sudo sh -c '\"#{vmnet_cli}\" --start'"
    execute_command(message,command)
  end
  message = "Information:\tChecking vmnet interface address"
  command = "ifconfig vmnet1 |grep inet"
  output  = execute_command(message,command)
  if !output.match(/#{$default_hostonly_ip}/)
    message = "Information:\tSetting vmnet1 address to "+$default_hostonly_ip
    command = "sudo sh -c \"ifconfig vmnet1 inet #{$default_hostonly_ip}\""
    execute_command(message,command)
  end
  if $os_name.match(/Darwin/)
    if $os_rel.split(".")[0].to_i < 14
      check_osx_nat(gw_if_name,if_name)
    else
      check_osx_pfctl(gw_if_name,if_name)
    end
  end
  return
end

# Change VMware Fusion VM network type

def change_fusion_vm_network(install_client,client_network)
  fusion_vm_dir    = $fusion_dir+"/"+install_client+".vmwarevm"
  fusion_vmx_file  = fusion_vm_dir+"/"+install_client+".vmx"
  test = 0
  copy = []
  file = IO.readlines(fusion_vmx_file)
  file.each do |line|
    if line.match(/ethernet0\.connectionType/)
      if !line.match(/#{client_network}/)
        test = 1
        copy.push("ethernet0.connectionType = \""+client_network+"\"\n")
      else
        copy.push(line)
      end
    else
      copy.push(line)
    end
  end
  if test == 1
    File.open(fusion_vmx_file,"w") {|file_data| file_data.puts copy}
  end
  return
end

# Boot VMware Fusion VM

def boot_fusion_vm(install_client,install_type)
  exists = check_fusion_vm_exists(install_client)
  if exists.match(/yes/)
    fusion_vm_dir    = $fusion_dir+"/"+install_client+".vmwarevm"
    fusion_vmx_file  = fusion_vm_dir+"/"+install_client+".vmx"
    message          = "Starting:\tVM "+install_client
    if $text_mode == 1
      command = "'#{$vmrun_bin}' -T fusion start '#{fusion_vmx_file}' nogui &"
    else
      command = "'#{$vmrun_bin}' -T fusion start '#{fusion_vmx_file}' &"
    end
    execute_command(message,command)
    if $serial_mode == 1
      if $verbose_mode == 1
        puts "Information:\tConnecting to serial port of "+install_client
      end
      begin
        socket = UNIXSocket.open("/tmp/#{install_client}")
        socket.each_line do |line|
          puts line
        end
      rescue
        puts "Warning:\tCannot open socket"
        exit
      end
    end
  else
    puts "Warning:\tVMware Fusion VM "+install_client+" does not exist"
  end
  return
end

# Add share to VMware Fusion VM

def add_shared_folder_to_fusion_vm(install_client,install_share,install_mount)
  vm_list = get_running_fusion_vms()
  if vm_list.to_s.match(/#{install_client}/)
    fusion_vm_dir   = $fusion_dir+"/"+install_client+".vmwarevm"
    fusion_vmx_file = fusion_vm_dir+"/"+install_client+".vmx"
    message = "Stopping:\tVirtual Box VM "+install_client
    command = "'#{$vmrun_bin}' -T fusion addSharedFolder '#{fusion_vmx_file}' #{install_mount} #{install_share}"
    execute_command(message,command)
  else
    if $verbose_mode == 1
      puts "Information:\tVMware Fusion VM "+install_client+" not running"
    end
  end
  return
end

# Stop VMware Fusion VM

def halt_fusion_vm(install_client)
  stop_fusion_vm(install_client)
end

def stop_fusion_vm(install_client)
  exists = check_fusion_vm_exists(install_client)
  if exists.match(/yes/)
    fusion_vm_dir   = $fusion_dir+"/"+install_client+".vmwarevm"
    fusion_vmx_file = fusion_vm_dir+"/"+install_client+".vmx"
    message = "Stopping:\tVirtual Box VM "+install_client
    command = "'#{$vmrun_bin}' -T fusion stop '#{fusion_vmx_file}'"
    execute_command(message,command)
  else
    if $verbose_mode == 1
      puts "Information:\tVMware Fusion VM "+install_client+" not running"
    end
  end
  return
end

# Reset VMware Fusion VM

def reboot_fusion_vm(install_client)
  reset_fusion_vm(install_client)
end

def reset_fusion_vm(install_client)
  vm_list = get_running_fusion_vms()
  if vm_list.to_s.match(/#{install_client}/)
    fusion_vm_dir   = $fusion_dir+"/"+install_client+".vmwarevm"
    fusion_vmx_file = fusion_vm_dir+"/"+install_client+".vmx"
    message = "Stopping:\tVirtual Box VM "+install_client
    command = "'#{$vmrun_bin}' -T fusion reset '#{fusion_vmx_file}'"
    execute_command(message,command)
  else
    if $verbose_mode == 1
      puts "Information:\tVMware Fusion VM "+install_client+" not running"
    end
  end
  return
end

# Suspend VMware Fusion VM

def suspend_fusion_vm(install_client)
  vm_list = get_running_fusion_vms()
  if vm_list.to_s.match(/#{install_client}/)
    fusion_vm_dir   = $fusion_dir+"/"+install_client+".vmwarevm"
    fusion_vmx_file = fusion_vm_dir+"/"+install_client+".vmx"
    message = "Stopping:\tVirtual Box VM "+install_client
    command = "'#{$vmrun_bin}' -T fusion suspend '#{fusion_vmx_file}'"
    execute_command(message,command)
  else
    if $verbose_mode == 1
      puts "Information:\tVMware Fusion VM "+install_client+" not running"
    end
  end
  return
end

# Create VMware Fusion VM disk

def create_fusion_vm_disk(install_client,fusion_vm_dir,fusion_disk_file)
  if File.exist?(fusion_disk_file)
    puts "Warning:\tVMware Fusion VM disk '"+fusion_disk_file+"' already exists for "+install_client
    exit
  end
  check_dir_exists(fusion_vm_dir)
  vdisk_bin = "/Applications/VMware Fusion.app/Contents/Library/vmware-vdiskmanager"
  message   = "Creating:\tVMware Fusion disk '"+fusion_disk_file+"' for "+install_client
  command   = "cd '#{fusion_vm_dir}' ; '#{vdisk_bin}' -c -s '#{$default_vm_size}' -a LsiLogic -t 0 '#{fusion_disk_file}'"
  execute_command(message,command)
  return
end


# Check VMware Fusion VM exists

def check_fusion_vm_exists(install_client)
  set_vmrun_bin()
  fusion_vm_dir   = $fusion_dir+"/"+install_client+".vmwarevm"
  fusion_vmx_file = fusion_vm_dir+"/"+install_client+".vmx"
  if !File.exist?(fusion_vmx_file)
    if $verbose_mode == 1
      puts "Information:\tVMware Fusion VM "+install_client+" does not exist"
    end
    exists = "no"
  else
    if $verbose_mode == 1
      puts "Information:\tVMware Fusion VM "+install_client+" exists"
    end
    exists = "yes"
  end
  return exists
end

# Check VMware Fusion VM doesn't exist

def check_fusion_vm_doesnt_exist(install_client)
  fusion_vm_dir    = $fusion_dir+"/"+install_client+".vmwarevm"
  fusion_vmx_file  = fusion_vm_dir+"/"+install_client+".vmx"
  fusion_disk_file = fusion_vm_dir+"/"+install_client+".vmdk"
  if File.exist?(fusion_vmx_file)
    puts "Information:\tVMware Fusion VM "+install_client+" already exists"
    exit
  end
  return fusion_vm_dir,fusion_vmx_file,fusion_disk_file
end

# Get a list of available VMware Fusion VMs

def get_available_fusion_vms()
  vm_list = []
  if File.directory?($fusion_dir) or File.symlink?($fusion_dir)
    vm_list = %x[find "#{$fusion_dir}/" -name "*.vmx"].split("\n")
  end
  return vm_list
end

# Get VMware Fusion Guest OS name

def get_fusion_guest_os(install_method,install_arch)
  install_os = eval"[get_#{install_method}_fusion_guest_os(install_arch)]"
  return install_os
end

# Get VMware Fusion Guest OS name

def get_ai_fusion_guest_os(install_arch)
  install_os = "solaris11-64"
  return install_os
end

# Configure a AI VMware Fusion VM

def configure_ai_fusion_vm(install_client,install_mac,install_arch,install_os,install_release,install_size,install_file,install_memory,install_cpu,install_network,install_share,install_mount)
  install_os = get_ai_fusion_guest_os(install_arch)
  configure_fusion_vm(install_client,install_mac,install_os,install_arch,install_file,install_memory,install_cpu,install_network,install_share,install_mount)
  return
end

# Get VMware Fusion Guest OS name

def get_js_fusion_guest_os(install_arch)
  install_os = "solaris10-64"
  return install_os
end

# Configure a Jumpstart VMware Fusion VM

def configure_js_fusion_vm(install_client,install_mac,install_arch,install_os,install_release,install_size,install_file,install_memory,install_cpu,install_network,install_share,install_mount)
  install_os = get_js_fusion_guest_os(install_arch)
  configure_fusion_vm(install_client,install_mac,install_os,install_arch,install_file,install_memory,install_cpu,install_network,install_share,install_mount)
  return
end

# Get VMware Fusion Guest OS name

def get_ay_fusion_guest_os(install_arch)
  install_os = "sles11"
  if !install_arch.match(/i386/) and !install_arch.match(/64/)
    install_os = install_os+"-64"
  end
  return install_os
end

# configure an AutoYast (Suse) VMware Fusion VM

def configure_ay_fusion_vm(install_client,install_mac,install_arch,install_os,install_release,install_size,install_file,install_memory,install_cpu,install_network,install_share,install_mount)
  install_os = get_ay_fusion_guest_os(install_arch)
  configure_fusion_vm(install_client,install_mac,install_os,install_arch,install_file,install_memory,install_cpu,install_network,install_share,install_mount)
  return
end

# Get VMware Fusion Guest OS name

def get_nb_fusion_guest_os(install_arch)
  install_os = "freebsd"
  if !install_arch.match(/i386/) and !install_arch.match(/64/)
    install_os = install_os+"-64"
  end
  return install_os
end

# Configure a NetBSB VMware Fusion VM

def configure_nb_fusion_vm(install_client,install_mac,install_arch,install_os,install_release,install_size,install_file,install_memory,install_cpu,install_network,install_share,install_mount)
  install_os = get_nb_fusion_guest_os(install_arch)
  configure_fusion_vm(install_client,install_mac,install_os,install_arch,install_file,install_memory,install_cpu,install_network,install_share,install_mount)
  return
end

# Get VMware Fusion Guest OS name

def get_ob_fusion_guest_os(install_arch)
  install_os = "otherlinux-64"
  return install_os
end

# Configure an OpenBSD VMware Fusion VM

def configure_ob_fusion_vm(install_client,install_mac,install_arch,install_os,install_release,install_size,install_file,install_memory,install_cpu,install_network,install_share,install_mount)
  install_os = get_ob_fusion_guest_os(install_arch)
  configure_fusion_vm(install_client,install_mac,install_os,install_arch,install_file,install_memory,install_cpu,install_network,install_share,install_mount)
  return
end

# Get VMware Fusion Guest OS name

def get_ps_fusion_guest_os(install_arch)
  install_os = "ubuntu"
  if !install_arch.match(/i386/) and !install_arch.match(/64/)
    install_os = install_os+"-64"
  end
  return install_os
end

# Configure an Ubuntu VMware Fusion VM

def configure_ps_fusion_vm(install_client,install_mac,install_arch,install_os,install_release,install_size,install_file,install_memory,install_cpu,install_network,install_share,install_mount)
  install_os = get_ps_fusion_guest_os(install_arch)
  configure_fusion_vm(install_client,install_mac,install_os,install_arch,install_file,install_memory,install_cpu,install_network,install_share,install_mount)
  return
end

# Get VMware Fusion Guest OS name

def get_pe_fusion_guest_os(install_arch)
  install_os = "windows7srv-64"
  return install_os
end

# Configure a Windows VMware Fusion VM

def configure_pe_fusion_vm(install_client,install_mac,install_arch,install_os,install_release,install_size,install_file,install_memory,install_cpu,install_network,install_share,install_mount)
  install_os = get_pe_fusion_guest_os(install_arch)
  configure_fusion_vm(install_client,install_mac,install_os,install_arch,install_file,install_memory,install_cpu,install_network,install_share,install_mount)
  return
end

# Get VMware Fusion Guest OS name

def get_other_fusion_guest_os(install_arch)
  install_os = "otherguest"
  return install_os
end

# Configure another VMware Fusion VM

def configure_other_fusion_vm(install_client,install_mac,install_arch,install_os,install_release,install_size,install_file,install_memory,install_cpu,install_network,install_share,install_mount)
  install_os = get_other_fusion_guest_os(install_arch)
  configure_fusion_vm(install_client,install_mac,install_os,install_arch,install_file,install_memory,install_cpu,install_network,install_share,install_mount)
  return
end

# Get VMware Fusion Guest OS name

def get_ks_fusion_guest_os(install_arch)
  install_os = "rhel6"
  if install_arch.match(/64/)
    install_os = install_os+"-64"
  else
    if !install_arch.match(/i386/) and !install_arch.match(/64/)
      install_os = install_os+"-64"
    end
  end
  return install_os
end

# Configure a Kickstart VMware Fusion VM

def configure_ks_fusion_vm(install_client,install_mac,install_arch,install_os,install_release,install_size,install_file,install_memory,install_cpu,install_network,install_share,install_mount)
  install_os = get_ks_fusion_guest_os(install_arch)
  configure_fusion_vm(install_client,install_mac,install_os,install_arch,install_file,install_memory,install_cpu,install_network,install_share,install_mount)
  return
end

# Get VMware Fusion Guest OS name

def get_vs_fusion_guest_os(install_arch)
  install_os = "vmkernel5"
  return install_os
end

# Configure a ESX VMware Fusion VM

def configure_vs_fusion_vm(install_client,install_mac,install_arch,install_os,install_release,install_size,install_file,install_memory,install_cpu,install_network,install_share,install_mount)
  install_os = get_vs_fusion_guest_os(install_arch)
  configure_fusion_vm(install_client,install_mac,install_os,install_arch,install_file,install_memory,install_cpu,install_network,install_share,install_mount)
  return
end

# Check VMware Fusion is installed

def check_fusion_is_installed()
  install_status = "no"
  app_dir = "/Applications/VMware Fusion.app"
  if File.directory?(app_dir)
    install_status = "yes"
    set_fusion_dir()
  end
  return install_status
end

# check VMware Fusion NAT

def check_fusion_natd(if_name,install_network)
  check_fusion_is_installed()
  if install_network.match(/hostonly/)
    check_fusion_hostonly_network(if_name)
  end
  return
end

# Unconfigure a VMware Fusion VM

def unconfigure_fusion_vm(install_client)
  check_fusion_is_installed()
  exists = check_fusion_vm_exists(install_client)
  if exists.match(/yes/)
    stop_fusion_vm(install_client)
    fusion_vm_dir    = $fusion_dir+"/"+install_client+".vmwarevm"
    fusion_vmx_file  = fusion_vm_dir+"/"+install_client+".vmx"
    message          = "Deleting:\tVMware Fusion VM "+install_client
    command          = "'#{$vmrun_bin}' -T fusion deleteVM '#{fusion_vmx_file}'"
    execute_command(message,command)
    vm_dir   = install_client+".vmwarevm"
    message  = "Removing:\tVMware Fusion VM "+install_client+" directory"
    command  = "cd '#{$fusion_dir}' ; rm -rf '#{vm_dir}'"
    execute_command(message,command)
  else
    if $verbose_mode == 1
      puts "Warning:\tVMware Fusion VM "+install_client+" does not exist"
    end
  end
  return
end

# Create VMware Fusion VM vmx file

def create_fusion_vm_vmx_file(install_client,install_mac,install_os,fusion_vmx_file,install_file,install_memory,install_cpu,install_network,install_share,install_mount)
  vmx_info = populate_fusion_vm_vmx_info(install_client,install_mac,install_os,install_memory,install_file,install_network,install_share,install_mount)
  file = File.open(fusion_vmx_file,"w")
  vmx_info.each do |vmx_line|
    (vmx_param,vmx_value) = vmx_line.split(/\,/)
    if !vmx_value
      vmx_value = ""
    end
    output = vmx_param+" = \""+vmx_value+"\"\n"
    file.write(output)
  end
  file.close
  if $verbose_mode == 1
    puts "Information:\tVMware Fusion VM "+install_client+" configuration:"
    system("cat '#{fusion_vmx_file}'")
  end
  return
end

# Create ESX VM vmx file

def create_fusion_vm_esx_file(install_client,local_vmx_file,fixed_vmx_file)
  vmx_info = []
  old_vmx_info = File.readlines(local_vmx_file)
  old_vmx_info.each do |line|
    vmx_line = line.chomp()
    (vmx_param,vmx_value) = vmx_line.split(/\=/)
    vmx_param = vmx_param.gsub(/\s+/,"")
    vmx_value = vmx_value.gsub(/^\s+/,"")
    vmx_value = vmx_value.gsub(/"/,"")
    vmx_line  = vmx_param+","+vmx_value
    case vmx_line
    when /virtualHW\.version/
      vmx_info.push("virtualHW.version,11")
    else
      if !vmx_param.match(/^serial|^shared|^hgfs/)
        vmx_info.push(vmx_line)
      end
    end
  end
  file = File.open(fixed_vmx_file,"w")
  vmx_info.each do |vmx_line|
    (vmx_param,vmx_value) = vmx_line.split(/\,/)
    if !vmx_value
      vmx_value = ""
    end
    output = vmx_param+" = \""+vmx_value+"\"\n"
    file.write(output)
  end
  file.close
  if $verbose_mode == 1
    puts "Information:\tVMware Fusion VM "+install_client+" configuration:"
    system("cat '#{fixed_vmx_file}'")
  end
  return
end

# Configure a VMware Fusion VM

def configure_fusion_vm(install_client,install_mac,install_os,install_arch,install_file,install_memory,install_cpu,install_network,install_share,install_mount)
  check_fusion_is_installed()
  (fusion_vm_dir,fusion_vmx_file,fusion_disk_file) = check_fusion_vm_doesnt_exist(install_client)
  check_dir_exists(fusion_vm_dir)
  if !install_mac.match(/[0-9]/)
    install_mac = generate_mac_address()
  end
  create_fusion_vm_vmx_file(install_client,install_mac,install_os,fusion_vmx_file,install_file,install_memory,install_cpu,install_network,install_share,install_mount)
  if !install_file.match(/ova$/)
    create_fusion_vm_disk(install_client,fusion_vm_dir,fusion_disk_file)
  end
  puts
  puts "Information:\tClient:     "+install_client+" created with MAC address "+install_mac
  puts
  return
end

# Populate VMware Fusion VM vmx information

def populate_fusion_vm_vmx_info(install_client,install_mac,install_os,install_memory,install_file,install_network,install_share,install_mount)
  version  = get_fusion_version()
  version  = version.split(".")[0]
  version  = version.to_i
  vmx_info = []
  vmx_info.push(".encoding,UTF-8")
  vmx_info.push("config.version,8")
  if version > 6
    if version > 7
      if version >= 8
        vmx_info.push("virtualHW.version,12")
      else
        vmx_info.push("virtualHW.version,11")
      end
    end
  else
    vmx_info.push("virtualHW.version,10")
  end
  vmx_info.push("vcpu.hotadd,FALSE")
  vmx_info.push("scsi0.present,TRUE")
  if install_os.match(/windows7srv-64/)
    vmx_info.push("scsi0.virtualDev,lsisas1068")
  else
    vmx_info.push("scsi0.virtualDev,lsilogic")
  end
  vmx_info.push("memsize,#{install_memory}")
  vmx_info.push("mem.hotadd,FALSE")
  vmx_info.push("scsi0:0.present,TRUE")
  vmx_info.push("scsi0:0.fileName,#{install_client}.vmdk")
  if install_file.match(/[a-z]/)
    vmx_info.push("ide0.present,TRUE")
    vmx_info.push("ide0:0.present,TRUE")
    vmx_info.push("ide0:0.deviceType,cdrom-image")
    vmx_info.push("ide0:0.filename,#{install_file}")
  else
    #vmx_info.push("ide0:0.deviceType,none")
    #vmx_info.push("ide0:0.filename,")
  end
  vmx_info.push("ide0:0.startConnected,TRUE")
  vmx_info.push("ide0:0.autodetect,TRUE")
  vmx_info.push("sata0:1.present,FALSE")
  vmx_info.push("floppy0.fileType,device")
  vmx_info.push("floppy0.fileName,")
  vmx_info.push("floppy0.clientDevice,FALSE")
  vmx_info.push("ethernet0.present,TRUE")
  vmx_info.push("ethernet0.connectionType,#{install_network}")
  vmx_info.push("ethernet0.virtualDev,e1000")
  vmx_info.push("ethernet0.wakeOnPcktRcv,FALSE")
  vmx_info.push("ethernet0.addressType,static")
  vmx_info.push("ethernet0.linkStatePropagation.enable,TRUE")
  vmx_info.push("usb.present,TRUE")
  vmx_info.push("ehci.present,TRUE")
  vmx_info.push("ehci.pciSlotNumber,35")
  vmx_info.push("sound.present,TRUE")
  if install_os.match(/windows7srv-64/)
    vmx_info.push("sound.virtualDev,hdaudio")
  end
  vmx_info.push("sound.fileName,-1")
  vmx_info.push("sound.autodetect,TRUE")
  vmx_info.push("mks.enable3d,TRUE")
  vmx_info.push("pciBridge0.present,TRUE")
  vmx_info.push("pciBridge4.present,TRUE")
  vmx_info.push("pciBridge4.virtualDev,pcieRootPort")
  vmx_info.push("pciBridge4.functions,8")
  vmx_info.push("pciBridge5.present,TRUE")
  vmx_info.push("pciBridge5.virtualDev,pcieRootPort")
  vmx_info.push("pciBridge5.functions,8")
  vmx_info.push("pciBridge6.present,TRUE")
  vmx_info.push("pciBridge6.virtualDev,pcieRootPort")
  vmx_info.push("pciBridge6.functions,8")
  vmx_info.push("pciBridge7.present,TRUE")
  vmx_info.push("pciBridge7.virtualDev,pcieRootPort")
  vmx_info.push("pciBridge7.functions,8")
  vmx_info.push("vmci0.present,TRUE")
  vmx_info.push("hpet0.present,TRUE")
  vmx_info.push("usb.vbluetooth.startConnected,FALSE")
  vmx_info.push("tools.syncTime,TRUE")
  vmx_info.push("displayName,#{install_client}")
  vmx_info.push("guestOS,#{install_os}")
  vmx_info.push("nvram,#{install_client}.nvram")
  vmx_info.push("virtualHW.productCompatibility,hosted")
  vmx_info.push("tools.upgrade.policy,upgradeAtPowerCycle")
  vmx_info.push("powerType.powerOff,soft")
  vmx_info.push("powerType.powerOn,soft")
  vmx_info.push("powerType.suspend,soft")
  vmx_info.push("powerType.reset,soft")
  vmx_info.push("extendedConfigFile,#{install_client}.vmxf")
  vmx_info.push("uuid.bios,56")
  vmx_info.push("uuid.location,56")
  vmx_info.push("replay.supported,FALSE")
  vmx_info.push("replay.filename,")
  vmx_info.push("pciBridge0.pciSlotNumber,17")
  vmx_info.push("pciBridge4.pciSlotNumber,21")
  vmx_info.push("pciBridge5.pciSlotNumber,22")
  vmx_info.push("pciBridge6.pciSlotNumber,23")
  vmx_info.push("pciBridge7.pciSlotNumber,24")
  vmx_info.push("scsi0.pciSlotNumber,16")
  vmx_info.push("usb.pciSlotNumber,32")
  vmx_info.push("ethernet0.pciSlotNumber,33")
  vmx_info.push("sound.pciSlotNumber,34")
  vmx_info.push("vmci0.pciSlotNumber,36")
  if version >= 8
    vmx_info.push("sata0.pciSlotNumber,-1")
  else
    vmx_info.push("sata0.pciSlotNumber,37")
  end
  if install_os.match(/windows7srv-64/)
    vmx_info.push("scsi0.sasWWID,50 05 05 63 9c 8f c0 c0")
  end
  vmx_info.push("ethernet0.generatedAddressOffset,0")
  vmx_info.push("vmci0.id,-1176557972")
  vmx_info.push("vmotion.checkpointFBSize,134217728")
  vmx_info.push("cleanShutdown,TRUE")
  vmx_info.push("softPowerOff,FALSE")
  vmx_info.push("usb:1.speed,2")
  vmx_info.push("usb:1.present,TRUE")
  vmx_info.push("usb:1.deviceType,hub")
  vmx_info.push("usb:1.port,1")
  vmx_info.push("usb:1.parent,-1")
  vmx_info.push("checkpoint.vmState,")
  vmx_info.push("sata0:1.startConnected,FALSE")
  vmx_info.push("usb:0.present,TRUE")
  vmx_info.push("usb:0.deviceType,hid")
  vmx_info.push("usb:0.port,0")
  vmx_info.push("usb:0.parent,-1")
  vmx_info.push("ethernet0.address,#{install_mac}")
  vmx_info.push("floppy0.present,FALSE")
  vmx_info.push("serial0.present,TRUE")
  vmx_info.push("serial0.fileType,pipe")
  vmx_info.push("serial0.yieldOnMsrRead,TRUE")
  vmx_info.push("serial0.startConnected,TRUE")
  vmx_info.push("serial0.fileName,/tmp/#{install_client}")
  vmx_info.push("scsi0:0.redo,")
  if install_os.match(/vmkernel/)
    vmx_info.push("monitor.virtual_mmu,hardware")
    vmx_info.push("monitor.virtual_exec,hardware")
    vmx_info.push("vhv.enable,TRUE")
    vmx_info.push("monitor_control.restrict_backdoor,TRUE")
    vmx_info.push("numvcpus,2")
  end
  vmx_info.push("isolation.tools.hgfs.disable,FALSE")
  vmx_info.push("hgfs.mapRootShare,TRUE")
  vmx_info.push("hgfs.linkRootShare,TRUE")
  if version >= 8
    vmx_info.push("acpi.smbiosVersion2.7,FALSE")
    vmx_info.push("numa.autosize.vcpu.maxPerVirtualNode,1")
    vmx_info.push("numa.autosize.cookie,10001")
    vmx_info.push("migrate.hostlog,#{install_client}-#{install_mac}.hlog")
  end
  if install_share.match(/[a-z,A-Z]/)
    vmx_info.push("sharedFolder0.present,TRUE")
    vmx_info.push("sharedFolder0.enabled,TRUE")
    vmx_info.push("sharedFolder0.readAccess,TRUE")
    vmx_info.push("sharedFolder0.writeAccess,TRUE")
    vmx_info.push("sharedFolder0.hostPath,#{install_share}")
    vmx_info.push("sharedFolder0.guestName,#{install_mount}")
    vmx_info.push("sharedFolder0.expiration,never")
    vmx_info.push("sharedFolder.maxNum,1")
  end
  return vmx_info
end
