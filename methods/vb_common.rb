# VirtualBox VM support code

def fix_vbox_mouse_integration()
  message = "Information:\tDisabling VirtualBox Mouse Integration Message"
  command = "VBoxManage setextradata global GUI/SuppressMessages remindAboutAutoCapture,confirmInputCapture,remindAboutMouseIntegrationOn,remindAboutWrongColorDepth,confirmGoingFullscreen,remindAboutMouseIntegrationOff,remindAboutMouseIntegration"
  execute_command(message,command)
  return
end

# Import Packer VirtualBox image

def import_packer_vbox_vm(install_client,install_vm)
  (exists,images_dir) = check_packer_vm_image_exists(install_client,install_vm)
  if exists.match(/no/)
    puts "Warning:\tPacker VirtualBox VM image for "+install_client+" does not exist"
    exit
  end
  ovf_file = images_dir+"/"+install_client+".ovf"
  if File.exist?(ovf_file)
    message = "Information:\tImporting OVF file for Packer VirtualBox VM "+install_client
    command = "VBoxManage import '#{ovf_file}'"
    execute_command(message,command)
  else
    puts "Warning:\tOVF file for Packer VirtualBox VM "+install_client+" does not exist"
    exit
  end
  return
end

# Show Fusion VM config

def show_vbox_vm(install_client)
  exists = check_vbox_vm_exists(install_client)
  if exists.match(/yes/)
    %x[VBoxManage showvminfo '#{install_client}']
  else
    puts "Warning:\tVirtualBox VM "+install_client+" does not exist"
    exit
  end
  return
end

# Set VirtualBox VM Parameter

def set_vbox_value(install_client,install_param,install_value)
  exists = check_vbox_vm_exists(install_client)
  if exists.match(/yes/)
    %x[VBoxManage modifyvm '#{install_client}' --#{install_param} #{install_value}]
  else
    puts "Warning:\tVirtualBox VM "+install_client+" does not exist"
    exit
  end
  return
end

# Get VirtualBox VM Parameter

def set_vbox_value(install_client,install_param)
  exists = check_vbox_vm_exists(install_client)
  if exists.match(/yes/)
    %x[VBoxManage showvminfo '#{install_client}' | grep '#{install_param}']
  else
    puts "Warning:\tVirtualBox VM "+install_client+" does not exist"
    exit
  end
  return
end

# Add shared folder to VM

def add_shared_folder_to_vbox_vm(install_client,install_share,install_mount)
  message = "Information:\tSharing \""+install_share+"\" to VM "+install_client+" as "+install_mount
  command = "VBoxManage sharedfolder add '#{install_client}' --name '#{install_mount}' --hostpath '#{install_share}'"
  execute_command(message,command)
  return
end

# Restore VirtualBox VM snapshot

def restore_vbox_vm_snapshot(install_client,install_clone)
  if install_clone.match(/[a-z,A-Z]/)
    message = "Information:\tRestoring snapshot "+install_clone+" for "+install_client 
    command = "VBoxManage snapshot '#{install_client}' restore '#{install_clone}'"
  else
    message = "Information:\tRestoring latest snapshot for "+install_client
    command = "VBoxManage snapshot '#{install_client}'' restorecurrent"
  end
  execute_command(message,command)
  return
end

# Attach file to VirtualBox VM

def attach_file_to_vbox_vm(install_client,install_file,install_type)
  message = "Information:\tAttaching CDROM to VM "+install_client
  command = "VBoxManage storagectl \"#{install_client}\" --name \"cdrom\" --add \"sata\" --controller \"IntelAHCI\""
  execute_command(message,command)
  if File.exist?($vbox_additions_iso)
    message = "Information:\tAttaching ISO "+install_file+" to VM "+install_client
    command = "VBoxManage storageattach \"#{install_client}\" --storagectl \"cdrom\" --port 0 --device 0 --type dvddrive --medium \"#{install_file}\""
    execute_command(message,command)
    if install_type.match(/boot/)
      command = "VBoxManage modifyvm \"#{install_client}\" --boot1 dvd"
      execute_command(message,command)
    end
  end
  return
end

# Delete VirtualBox VM snapshot

def delete_vbox_vm_snapshot(install_client,install_clone)
  clone_list = []
  if install_clone.match(/\*/) or install_clone.match(/all/)
    clone_list = get_vbox_vm_snapshots(install_client)
    clone_list = clone_list.split("\n")
  else
    clone_list[0] = install_clone
  end
  clone_list.each do |install_clone|
    fusion_vmx_file = get_fusion_vm_vmx_file(install_client)
    message = "Information:\tDeleting snapshot "+install_clone+" for Fusion VM "+install_client
    command = "VBoxManage snapshot '#{install_client}' delete '#{install_clone}'"
    execute_command(message,command)
  end
  return
end

# Get a list of VirtualBox VM snapshots for a client

def get_vbox_vm_snapshots(install_client)
  message = "Information:\tGetting a list of snapshots for VirtualBox VM "+install_client
  command = "VBoxManage snapshot '#{install_client}' list |cut -f2 -d: |cut -f1 -d'(' |sed 's/^ //g' |sed 's/ $//g'"
  output  = execute_command(message,command)
  return output
end

# List all VirtualBox VM snapshots

def list_all_vbox_vm_snapshots()
  vm_list = get_available_vbox_vms()
  vm_list.each do |line|
    install_client = line.split(/"/)[1]
    list_vbox_vm_snapshots(install_client)
  end
  return
end

# List VirtualBox VM snapshots

def list_vbox_vm_snapshots(install_client)
  snapshot_list = get_vbox_vm_snapshots(install_client)
  puts "Snapshots for "+install_client+":"
  puts snapshot_list 
  return
end

# Snapshot VirtualBox VM

def snapshot_vbox_vm(install_client,install_clone)
  exists = check_vbox_vm_exists(install_client)
  if exists.match(/no/)
    puts "Warning:\tVirtualBox VM "+install_client+" does not exist"
    exit
  end
  message = "Information:\tCloning VirtualBox VM "+install_client+" to "+install_clone
  command = "VBoxManage snapshot '#{install_client}' take '#{install_clone}'"
  execute_command(message,command)
  return
end

# Get a List of VirtualBox VMs

def get_available_vbox_vms()
  vm_list = []
  message = "Information:\tGetting list of VirtualBox VMs"
  command = "VBoxManage list vms |grep -v 'inaccessible'"
  output  = execute_command(message,command)
  vm_list = output.split("\n")
  return vm_list
end

# Get VirtualBox VM info

def get_vbox_vm_info(install_client,install_search)
  message = "Information:\tGetting value for "+install_search+" from VirtualBox VM "+install_client
  if install_search.match(/MAC/)
    command = "VBoxManage showvminfo \"#{install_client}\" |grep MAC |awk '{print $4}' |head -1"
  else
    command = "VBoxManage showvminfo \"#{install_client}\" |grep \"#{install_search}\" |cut -f2 -d:"
  end
  output  = execute_command(message,command)
  vm_info = output.chomp.gsub(/^\s+/,"")
  return vm_info
end

# Get VirtualBox VM OS

def get_vbox_vm_os(install_client)
  install_search = "^Guest OS"
  install_os     = get_vbox_vm_info(install_client,install_search)
  return install_os
end

# List all VMs

def list_all_vbox_vms()
  vm_list = get_available_vbox_vms()
  puts
  puts "VirtualBox VMs"
  puts
  vm_list.each do |line|
    install_client = line.split(/"/)[1]
    install_os     = get_vbox_vm_os(install_client)
    install_mac    = get_vbox_vm_mac(install_client)
    puts install_client+" os="+install_os+" mac="+install_mac
  end
  puts
  return
end

# List running VMs

def list_running_vbox_vms()
  set_vboxmanage_bin()
  if $vboxmanage_bin.match(/[a-z]/)
    vm_list = %x[VBoxManage list runningvms].split("\n")
    puts
    puts "Running VirtualBox VMs:"
    puts
    vm_list.each do |vm_name|
      vm_name = vm_name.split(/"/)[1]
      os_info = %x[VBoxManage showvminfo "#{vm_name}" |grep '^Guest OS' |cut -f2 -d:].chomp.gsub(/^\s+/,"")
      puts vm_name+"\t"+os_info
    end
    puts
  end
  return
end

# Set VirtualBox ESXi options

def configure_vmware_vbox_vm(install_client)
  modify_vbox_vm(install_client,"rtcuseutc","on")
  modify_vbox_vm(install_client,"vtxvpid","on")
  modify_vbox_vm(install_client,"vtxux","on")
  modify_vbox_vm(install_client,"hwvirtex","on")
  setextradata_vbox_vm(install_client,"VBoxInternal/Devices/pcbios/0/Config/DmiSystemVersion","None")
  setextradata_vbox_vm(install_client,"VBoxInternal/Devices/pcbios/0/Config/DmiBoardVendor","Intel Corporation")
  setextradata_vbox_vm(install_client,"VBoxInternal/Devices/pcbios/0/Config/DmiBoardProduct","440BX Desktop Reference Platform")
  setextradata_vbox_vm(install_client,"VBoxInternal/Devices/pcbios/0/Config/DmiSystemVendor","VMware, Inc.")
  setextradata_vbox_vm(install_client,"VBoxInternal/Devices/pcbios/0/Config/DmiSystemProduct","VMware Virtual Platform")
  setextradata_vbox_vm(install_client,"VBoxInternal/Devices/pcbios/0/Config/DmiBIOSVendor","Phoenix Technologies LTD")
  setextradata_vbox_vm(install_client,"VBoxInternal/Devices/pcbios/0/Config/DmiBIOSVersion","6.0")
  setextradata_vbox_vm(install_client,"VBoxInternal/Devices/pcbios/0/Config/DmiChassisVendor","No Enclosure")
  vbox_vm_uuid = get_vbox_vm_uuid(install_client)
  vbox_vm_uuid = "VMware-"+vbox_vm_uuid
  setextradata_vbox_vm(install_client,"VBoxInternal/Devices/pcbios/0/Config/DmiSystemSerial",vbox_vm_uuid)
  return
end

# Get VirtualBox UUID

def get_vbox_vm_uuid(install_client)
  install_search = "^UUID"
  install_uuid   = get_vbox_vm_info(install_client,install_search)
  return install_uuid
end

# Set VirtualBox ESXi options

def configure_vmware_esxi_vbox_vm(install_client)
  configure_vmware_esxi_defaults()
  modify_vbox_vm(install_client,"cpus",$default_vm_vcpu)
  configure_vmware_vbox_vm(install_client)
  return
end

# Set VirtualBox vCenter option

def configure_vmware_vcenter_vbox_vm(install_client)
  configure_vmware_vcenter_defaults()
  configure_vmware_vbox_vm(install_client)
  return
end

# Clone VirtualBox VM

def clone_vbox_vm(install_client,new_name,install_mac,client_ip)
  exists = check_vbox_vm_exists(install_client)
  if exists.match(/no/)
    puts "Warning:\tVirtualBox VM "+install_client+" does not exist"
    exit
  end
  message = "Information:\tCloning VM "+install_client+" to "+new_name
  command = "VBoxManage clonevm #{install_client} --name #{new_name} --register"
  execute_command(message,command)
  if client_ip.match(/[0-9]/)
    add_hosts_entry(new_name,client_ip)
  end
  if install_mac.match(/[0-9,a-z,A-Z]/)
    change_vbox_vm_mac(new_name,install_mac)
  end
  return
end

# Export OVA

def export_vbox_ova(install_client,ova_file)
  exists = check_vbox_vm_exists(install_client)
  if exists.match(/yes/)
    stop_vbox_vm(install_client)
    if !ova_file.match(/[0-9,a-z,A-Z]/)
      ova_file = "/tmp/"+install_client+".ova"
      puts "Warning:\tNo ouput file given"
      puts "Information:\tExporting VirtualBox VM "+install_client+" to "+ova_file
    end
    if !ova_file.match(/\.ova$/)
      ova_file = ova_file+".ova"
    end
    message = "Information:\tExporting VirtualBox VM "+install_client+" to "+ova_file
    command = "VBoxManage export \"#{install_client}\" -o \"#{ova_file}\""
    execute_command(message,command)
  else
    puts "Warning:\tVirtualBox VM "+install_client+"does not exist"
  end
  return
end

# Import OVA

def import_vbox_ova(install_client,install_mac,client_ip,ova_file)
  exists = check_vbox_vm_exists(install_client)
  if exists.match(/no/)
    exists = check_vbox_vm_config_exists(install_client)
  end
  if exists.match(/yes/)
    delete_vbox_vm_config(install_client)
  end
  if !ova_file.match(/\//)
    ova_file = $iso_base_dir+"/"+ova_file
  end
  if File.exist?(ova_file)
    if install_client.match(/[0-9,a-z,A-Z]/)
      install_dir  = get_vbox_vm_dir(install_client)
      message = "Information:\tImporting VirtualBox VM "+install_client+" from "+ova_file
      command = "VBoxManage import \"#{ova_file}\" --vsys 0 --vmname \"#{install_client}\" --unit 20 --disk \"#{install_dir}\""
      execute_command(message,command)
    else
      set_vboxmanage_bin()
      if $vboxmanage_bin.match(/[a-z]/)
        install_client = %x[VBoxManage import -n #{ova_file} |grep "Suggested VM name"].split(/\n/)[-1]
        if !install_client.match(/[0-9,a-z,A-Z]/)
          puts "Warning:\tCould not determine VM name for Virtual Appliance "+ova_file
          exit
        else
          install_client = install_client.split(/Suggested VM name /)[1].chomp
          message = "Information:\tImporting VirtualBox VM "+install_client+" from "+ova_file
          command = "VBoxManage import \"#{ova_file}\""
          execute_command(message,command)
        end
      end
    end
  else
    puts "Warning:\tVirtual Appliance "+ova_file+"does not exist"
  end
  if client_ip.match(/[0-9]/)
    add_hosts_entry(install_client,client_ip)
  end
  vbox_socket_name = add_socket_to_vbox_vm(install_client)
  add_serial_to_vbox_vm(install_client)
  if $default_vm_network.match(/bridged/)
    vbox_nic_name = get_bridged_vbox_nic()
    add_bridged_network_to_vbox_vm(install_client,vbox_nic_name)
  else
    if_name       = get_bridged_vbox_nic()
    vbox_nic_name = check_vbox_hostonly_network(if_name)
    add_nonbridged_network_to_vbox_vm(install_client,vbox_nic_name)
  end
  if !install_mac.match(/[0-9,a-z,A-Z]/)
    install_mac = get_vbox_vm_mac(install_client)
  else
    change_vbox_vm_mac(install_client,install_mac)
  end
  if ova_file.match(/VMware/)
    configure_vmware_vcenter_defaults()
    configure_vmware_vbox_vm(install_client)
  end
  puts "Warning:\tVirtual Appliance "+ova_file+" imported with VM name "+install_client+" and MAC address "+install_mac
  return
end

# List Linux KS VirtualBox VMs

def list_ks_vbox_vms()
  search_string = "RedHat"
  list_vbox_vms(search_string)
  return
end

# List Linux Preseed VirtualBox VMs

def list_ps_vbox_vms()
  search_string = "Ubuntu"
  list_vbox_vms(search_string)
end

# List Solaris Kickstart VirtualBox VMs

def list_js_vbox_vms()
  search_string = "OpenSolaris"
  list_vbox_vms(search_string)
  return
end

# List Solaris AI VirtualBox VMs

def list_ai_vbox_vms()
  search_string = "Solaris 11"
  list_vbox_vms(search_string)
  return
end

# List Linux Autoyast VirtualBox VMs

def list_ay_vbox_vms()
  search_string = "OpenSUSE"
  list_vbox_vms(search_string)
  return
end

# List vSphere VirtualBox VMs

def list_vs_vbox_vms()
  search_string = "Linux"
  list_vbox_vms(search_string)
  return
end

# Get/set VBoxManage path

def set_vboxmanage_bin()
  $vboxmanage_bin = %x[which VBoxManage].chomp
  if !$vboxmanage_bin.match(/VBoxManage/) or $vboxmanage_bin.match(/no VBoxManage/)
    puts "Warning:\tCould not find VBoxManage"
  end
  return
end

# Check VirtualBox VM exists

def check_vbox_vm_exists(install_client)
  message   = "Information:\tChecking VM "+install_client+" exists"
  command   = "VBoxManage list vms |grep -v 'inaccessible'"
  host_list = execute_command(message,command)
  if !host_list.match(install_client)
    if $verbose_mode == 1
      puts "Information:\tVirtualBox VM "+install_client+" does not exist"
    end
    exists = "no"
  else
    exists = "yes"
  end
  return exists
end

# Get VirtualBox bridged network interface

def get_bridged_vbox_nic()
  message  = "Information:\tChecking Bridged interfaces"
  command  = "VBoxManage list bridgedifs"
  nic_list = execute_command(message,command)
  if !nic_list.match(/[a-z,A-Z]/)
    nic_name = $default_net
  else
    nic_list=nic_list.split(/\n/)
    nic_list.each do |line|
      line=line.chomp
      if line.match(/#{$default_host_only_ip}/)
        return nic_name
      end
      if line.match(/^Name/)
        nic_name = line.split(/:/)[1].gsub(/\s+/,"")
      end
    end
  end
  return nic_name
end

# Add bridged network to VirtualBox VM

def add_bridged_network_to_vbox_vm(install_client,nic_name)
  message = "Information:\tAdding bridged network "+nic_name+" to "+install_client
  command = "VBoxManage modifyvm #{install_client} --nic1 bridged --bridgeadapter1 #{nic_name}"
  execute_command(message,command)
  return
end

# Add non-bridged network to VirtualBox VM

def add_nonbridged_network_to_vbox_vm(install_client,nic_name)
  message = "Information:\tAdding network "+nic_name+" to "+install_client
  if nic_name.match(/vboxnet/)
    command = "VBoxManage modifyvm #{install_client} --hostonlyadapter1 #{nic_name} ; VBoxManage modifyvm #{install_client} --nic1 hostonly"
  else
    command = "VBoxManage modifyvm #{install_client} --nic1 #{nic_name}"
  end
  execute_command(message,command)
  return
end

# Set boot priority to network

def set_vbox_vm_boot_priority(install_client)
  message = "Information:\tSetting boot priority for "+install_client+" to disk then network"
  command = "VBoxManage modifyvm #{install_client} --boot1 disk --boot2 net"
  execute_command(message,command)
  return
end

# Set boot device

def set_vbox_boot_device(install_client,install_type)
  message = "Information:\tSetting boot device for "+install_client+" to "+install_type
  command = "VBoxManage modifyvm #{install_client} --boot1 #{install_type}"
  execute_command(message,command)
  return
end

# Get VirtualBox VM OS

def get_vbox_vm_os(install_client)
  message   = "Information:\tGetting VirtualBox VM OS for "+install_client
  command   = "VBoxManage showvminfo #{install_client} |grep Guest |grep OS |head -1 |cut -f2 -d:"
  install_os = execute_command(message,command)
  install_os = install_os.gsub(/^\s+/,"")
  install_os = install_os.chomp
  return install_os
end

# List VirtualBox VMs

def list_vbox_vms(search_string)
  output_list = []
  vm_list     = get_available_vbox_vms()
  vm_list.each do |line|
    install_client = line.split(/"/)[1]
    install_mac    = get_vbox_vm_mac(install_client)
    install_os     = get_vbox_vm_os(install_client)
    output         = install_client+" os="+install_os+" mac="+install_mac
    if search_string
      if output.match(/#{search_string}/)
        output_list.push(output)
      end
    else
      output_list.push(output)
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

# Get VirtualBox VM directory

def get_vbox_vm_dir(install_client)
  message          = "Information:\tGetting VirtualBox VM directory"
  command          = "VBoxManage list systemproperties |grep 'Default machine folder' |cut -f2 -d':' |sed 's/^[         ]*//g'"
  vbox_vm_base_dir = execute_command(message,command)
  vbox_vm_base_dir = vbox_vm_base_dir.chomp
  if !vbox_vm_base_dir.match(/[a-z,A-Z]/)
    vbox_vm_base_dir=$home_dir+"/VirtualBox VMs"
  end
  vbox_vm_dir      = "#{vbox_vm_base_dir}/#{install_client}"
  return vbox_vm_dir
end

# Delete VirtualBox config file

def delete_vbox_vm_config(install_client)
  vbox_vm_dir = get_vbox_vm_dir(install_client)
  config_file = vbox_vm_dir+"/"+install_client+".vbox"
  if File.exist?(config_file)
    message = "Information:\tRemoving Virtualbox configuration file "+config_file
    command = "rm \"#{config_file}\""
    execute_command(message,command)
  end
  config_file = vbox_vm_dir+"/"+install_client+".vbox-prev"
  if File.exist?(config_file)
    message = "Information:\tRemoving Virtualbox configuration file "+config_file
    command = "rm \"#{config_file}\""
    execute_command(message,command)
  end
  return
end

# Check if VirtuakBox config file exists

def check_vbox_vm_config_exists(install_client)
  exists      = "no"
  vbox_vm_dir = get_vbox_vm_dir(install_client)
  config_file = vbox_vm_dir+"/"+install_client+".vbox"
  prev_file   = vbox_vm_dir+"/"+install_client+".vbox-prev"
  if File.exist?(config_file) or File.exist?(prev_file)
    exists = "yes"
  else
    exists = "no"
  end
  return exists
end

# Check VM doesn't exist

def check_vbox_vm_doesnt_exist(install_client)
  message   = "Checking:\tVM "+install_client+" doesn't exist"
  command   = "VBoxManage list vms"
  host_list = execute_command(message,command)
  if host_list.match(install_client)
    puts "Information:\tVirtualBox VM #{install_client} already exists"
    exit
  end
  return
end

# Routine to register VM

def register_vbox_vm(install_client,install_os)
  message = "Information:\tRegistering VM "+install_client
  command = "VBoxManage createvm --name \"#{install_client}\" --ostype \"#{install_os}\" --register"
  execute_command(message,command)
  return
end

# Get VirtualBox disk

def get_vbox_controller()
  if $vbox_disk_type =~/ide/
    vbox_controller = "PIIX4"
  end
  if $vbox_disk_type =~/sata/
    vbox_controller = "IntelAhci"
  end
  if $vbox_disk_type =~/scsi/
    vbox_controller = "LSILogic"
  end
  if $vbox_disk_type =~/sas/
    vbox_controller = "LSILogicSAS"
  end
  return vbox_controller
end

# Add controller to VM

def add_controller_to_vbox_vm(install_client,vbox_controller)
  message = "Information:\tAdding controller to VirtualBox VM"
  command = "VBoxManage storagectl \"#{install_client}\" --name \"#{$vbox_disk_type}\" --add \"#{$vbox_disk_type}\" --controller \"#{vbox_controller}\""
  execute_command(message,command)
  return
end

# Create Virtual Bpx VM HDD

def create_vbox_hdd(install_client,vbox_disk_name,vbox_disk_size)
  message = "Information:\tCreating VM hard disk for "+install_client
  command = "VBoxManage createhd --filename \"#{vbox_disk_name}\" --size \"#{vbox_disk_size}\""
  execute_command(message,command)
  return
end

def detach_file_from_vbox_vm(install_client,install_file,install_type)
  if install_file.match(/iso$/) or install_type.match(/iso|cdrom/)
    message = "Information:\tDetaching CDROM from "+install_client
    command = "VBoxManage storageattach \"#{install_client}\" --storagectl \"cdrom\" --port 0 --device 0 --type dvddrive --medium none"
    execute_command(message,command)
  end
  return
end

# Add hard disk to VirtualBox VM

def add_hdd_to_vbox_vm(install_client,vbox_disk_name)
  message = "Information:\tAttaching storage \"#{vbox_disk_name}\" of type \"#{$vbox_disk_type}\" to VM "+install_client
  command = "VBoxManage storageattach \"#{install_client}\" --storagectl \"#{$vbox_disk_type}\" --port 0 --device 0 --type hdd --medium \"#{vbox_disk_name}\""
  execute_command(message,command)
  return
end

# Add guest additions ISO

def add_tools_to_vbox_vm(install_client)
  message = "Information:\tAttaching CDROM \""+$vbox_additions_iso+"\" to VM "+install_client
  command = "VBoxManage storagectl \"#{install_client}\" --name \"cdrom\" --add \"sata\" --controller \"IntelAHCI\""
  execute_command(message,command)
  if File.exist?($vbox_additions_iso)
    message = "Information:\tAttaching ISO "+$vbox_additions_iso+" to VM "+install_client
    command = "VBoxManage storageattach \"#{install_client}\" --storagectl \"cdrom\" --port 1 --device 0 --type dvddrive --medium \"#{$vbox_additions_iso}\""
    execute_command(message,command)
  end
  return
end

# Add hard disk to VirtualBox VM

def add_cdrom_to_vbox_vm(install_client,install_file)
  message = "Information:\tAttaching CDROM \""+install_file+"\" to VM "+install_client
  command = "VBoxManage storagectl \"#{install_client}\" --name \"cdrom\" --add \"sata\" --controller \"IntelAHCI\""
  execute_command(message,command)
  if File.exist?($vbox_additions_iso)
    message = "Information:\tAttaching ISO "+$vbox_additions_iso+" to VM "+install_client
    command = "VBoxManage storageattach \"#{install_client}\" --storagectl \"cdrom\" --port 0 --device 0 --type dvddrive --medium \"#{install_file}\""
    execute_command(message,command)
  end
  return
end

# Add memory to Virtualbox VM

def add_memory_to_vbox_vm(install_client,install_memory)
  message = "Information:\tAdding memory to VM "+install_client
  command = "VBoxManage modifyvm \"#{install_client}\" --memory \"#{install_memory}\""
  execute_command(message,command)
  return
end

# Routine to add a socket to a VM

def add_socket_to_vbox_vm(install_client)
  socket_name = "/tmp/#{install_client}"
  message     = "Information:\tAdding serial controller to "+install_client
  command     = "VBoxManage modifyvm \"#{install_client}\" --uartmode1 server #{socket_name}"
  execute_command(message,command)
  return socket_name
end

# Routine to add serial to a VM

def add_serial_to_vbox_vm(install_client)
  message = "Information:\tAdding serial Port to "+install_client
  command = "VBoxManage modifyvm \"#{install_client}\" --uart1 0x3F8 4"
  execute_command(message,command)
  return
end

# Get VirtualBox Guest OS name

def get_vbox_guest_os(install_method,install_arch)
  install_os = eval"[get_#{install_method}_vbox_guest_os(install_arch)]"
  return install_os
end

# Get NT VirtualBox Guest OS name

def get_pe_vbox_guest_os(install_arch)
  install_os = "Windows2008"
  if install_arch.match(/64/)
    install_os = install_os+"_64"
  end
  return install_os
end

# Configure a NT Virtual Box VM

def configure_nt_vbox_vm(install_client,install_mac,install_arch,install_os,install_release,install_size,install_file,install_memory,install_cpu,install_network,install_share,install_mount)
  install_os = get_nt_vbox_guest_os(install_arch,install_release)
  configure_vbox_vm(install_client,install_mac,install_os,install_size,install_file,install_memory,install_cpu,install_network,install_share,install_mount)
  return
end

# Get AI VirtualBox Guest OS name

def get_ai_vbox_guest_os(install_arch)
  install_os = "Solaris11_64"
  return install_os
end

# Configure a AI Virtual Box VM

def configure_ai_vbox_vm(install_client,install_mac,install_arch,install_os,install_release,install_size,install_file,install_memory,install_cpu,install_network,install_share,install_mount)
  install_os = get_ai_vbox_guest_os(install_arch)
  configure_vbox_vm(install_client,install_mac,install_os,install_size,install_file,install_memory,install_cpu,install_network,install_share,install_mount)
  return
end

# Get Jumpstart VirtualBox Guest OS name

def get_js_vbox_guest_os(install_arch)
  install_os = "OpenSolaris_64"
  return install_os
end

# Configure a Jumpstart Virtual Box VM

def configure_js_vbox_vm(install_client,install_mac,install_arch,install_os,install_release,install_size,install_file,install_memory,install_cpu,install_network,install_share,install_mount)
  install_os = get_js_vbox_guest_os(install_arch)
  configure_vbox_vm(install_client,install_mac,install_os,install_size,install_file,install_memory,install_cpu,install_network,install_share,install_mount)
  return
end

# Get Kicktart VirtualBox Guest OS name

def get_ks_vbox_guest_os(install_arch)
  if install_arch.match(/i386/)
    install_os = "RedHat"
  else
    install_os = "RedHat_64"
  end
  return install_os
end

# Configure a RedHat or Centos Kickstart VirtualBox VM

def configure_ks_vbox_vm(install_client,install_mac,install_arch,install_os,install_release,install_size,install_file,install_memory,install_cpu,install_network,install_share,install_mount)
  install_os = get_ks_vbox_guest_os(install_arch)
  configure_vbox_vm(install_client,install_mac,install_os,install_size,install_file,install_memory,install_cpu,install_network,install_share,install_mount)
  return
end

# Get VirtualBox Guest OS name

def get_ps_vbox_guest_os(install_arch)
  if install_arch.match(/i386/)
    install_os = "Ubuntu"
  else
    install_os = "Ubuntu_64"
  end
  return install_os
end

# Configure a Preseed Ubuntu VirtualBox VM

def configure_ps_vbox_vm(install_client,install_mac,install_arch,install_os,install_release,install_size,install_file,install_memory,install_cpu,install_network,install_share,install_mount)
  install_os = get_ps_vbox_guest_os(install_arch)
  configure_vbox_vm(install_client,install_mac,install_os,install_size,install_file,install_memory,install_cpu,install_network,install_share,install_mount)
  return
end

# Get VirtualBox Guest OS name

def get_ay_vbox_guest_os(install_arch)
  if install_arch.match(/i386/)
    install_os = "OpenSUSE"
  else
    install_os = "OpenSUSE_64"
  end
  return install_os
end

# Configure a AutoYast SuSE VirtualBox VM

def configure_ay_vbox_vm(install_client,install_mac,install_arch,install_os,install_release,install_size,install_file,install_memory,install_cpu,install_network,install_share,install_mount)
  install_os = get_ay_vbox_guest_os(install_arch)
  configure_vbox_vm(install_client,install_mac,install_os,install_size,install_file,install_memory,install_cpu,install_network,install_share,install_mount)
  return
end

# Get OpenBSD VirtualBox Guest OS name

def get_ob_vbox_guest_os(install_arch)
  install_os = "Linux_64"
  return install_os
end

# Configure an OpenBSD VM

def configure_ob_vbox_vm(install_client,install_mac,install_arch,install_os,install_release,install_size,install_file,install_memory,install_cpu,install_network,install_share,install_mount)
  install_os = get_ob_vbox_guest_os(install_arch)
  configure_vbox_vm(install_client,install_mac,install_os,install_size,install_file,install_memory,install_cpu,install_network,install_share,install_mount)
  return
end

# Get NetBSD VirtualBox Guest OS name

def get_nb_vbox_guest_os(install_arch)
  if install_arch.match(/i386/)
    install_os = "NetBSD"
  else
    install_os = "NetBSD_64"
  end
  return install_os
end

# Configure a NetBSD VM

def configure_nb_vbox_vm(install_client,install_mac,install_arch,install_os,install_release,install_size,install_file,install_memory,install_cpu,install_network,install_share,install_mount)
  install_os = get_nb_vbox_guest_os(install_arch)
  configure_vbox_vm(install_client,install_mac,install_os,install_size,install_file,install_memory,install_cpu,install_network,install_share,install_mount)
  return
end

# Get vSphere VirtualBox Guest OS name

def get_vs_vbox_guest_os(install_arch)
  install_os = "Linux_64"
  return install_os
end

# Configure a ESX VirtualBox VM

def configure_vs_vbox_vm(install_client,install_mac,install_arch,install_os,install_release,install_size,install_file,install_memory,install_cpu,install_network,install_share,install_mount)
  install_os = get_vs_vbox_guest_os(install_arch)
  configure_vbox_vm(install_client,install_mac,install_os,install_size,install_file,install_memory,install_cpu,install_network,install_share,install_mount)
  return
end

# Get Other VirtualBox Guest OS name

def get_other_vbox_guest_os(install_arch)
  install_os = "Other"
  return install_os
end

# Configure a other VirtualBox VM

def configure_other_vbox_vm(install_client,install_mac,install_arch,install_os,install_release,install_size,install_file,install_memory,install_cpu,install_network,install_share,install_mount)
  install_os = get_other_vbox_guest_os(install_arch)
  configure_vbox_vm(install_client,install_mac,install_os,install_size,install_file,install_memory,install_cpu,install_network,install_share,install_mount)
  return
end

# Modify a VirtualBox VM parameter

def modify_vbox_vm(install_client,param_name,param_value)
  message = "Information:\tSetting VirtualBox Parameter "+param_name+" to "+param_value
  command = "VBoxManage modifyvm #{install_client} --#{param_name} #{param_value}"
  execute_command(message,command)
  return
end

def setextradata_vbox_vm(install_client,param_name,param_value)
  message = "Information:\tSetting VirtualBox Extradata "+param_name+" to "+param_value
  command = "VBoxManage setextradata #{install_client} \"#{param_name}\" \"#{param_value}\""
  execute_command(message,command)
  return
end

# Change VirtualBox VM Cores

def change_vbox_vm_cpu(install_client,client_cpus)
  message = "Information:\tSetting VirtualBox VM "+install_client+" CPUs to "+client_cpus
  command = "VBoxManage modifyvm #{install_client} --cpus #{client_cpus}"
  execute_command(message,command)
  return
end

# Change VirtualBox VM UTC

def change_vbox_vm_utc(install_client,client_utc)
  message = "Information:\tSetting VirtualBox VM "+install_client+" RTC to "+client_utc
  command = "VBoxManage modifyvm #{install_client} --rtcuseutc #{client_utc}"
  execute_command(message,command)
  return
end

# Change VirtualBox VM MAC address

def change_vbox_vm_mac(install_client,install_mac)
  message = "Setting:\tVirtualBox VM "+install_client+" MAC address to "+install_mac
  if install_mac.match(/:/)
    install_mac = install_mac.gsub(/:/,"")
  end
  command = "VBoxManage modifyvm #{install_client} --macaddress1 #{install_mac}"
  execute_command(message,command)
  return
end

# Boot VirtualBox VM

def boot_vbox_vm(install_client,install_type)
  exists = check_vbox_vm_exists(install_client)
  if exists.match(/no/)
    puts "VirtualBox VM "+install_client+" does not exist"
    exit
  end
  if install_type.match(/cdrom|net|dvd|disk/)
    install_type = install_type.gsub(/cdrom/,"dvd")
    set_vbox_boot_device(install_client,install_type)
  end
  message = "Starting:\tVM "+install_client
  if $text_mode == 1 or $serial_mode == 1
    puts
    puts "Information:\tBooting and connecting to virtual serial port of "+install_client
    puts
    puts "To disconnect from this session use CTRL-Q"
    puts
    puts "If you wish to re-connect to the serial console of this machine,"
    puts "run the following command"
    puts
    puts "socat UNIX-CONNECT:/tmp/#{install_client} STDIO,raw,echo=0,escape=0x11,icanon=0"
    puts
    set_vboxmanage_bin()
    if $vboxmanage_bin.match(/[a-z]/)
      %x[VBoxManage startvm #{install_client} --type headless ; sleep 1]
    end
  else
    command = "VBoxManage startvm #{install_client}"
    execute_command(message,command)
  end
  if $serial_mode == 1
    system("socat UNIX-CONNECT:/tmp/#{install_client} STDIO,raw,echo=0,escape=0x11,icanon=0")
  else
    puts
    puts "If you wish to connect to the serial console of this machine,"
    puts "run the following command"
    puts
    puts "socat UNIX-CONNECT:/tmp/#{install_client} STDIO,raw,echo=0,escape=0x11,icanon=0"
    puts
    puts "To disconnect from this session use CTRL-Q"
    puts
    puts
  end
  return
end

# Stop VirtualBox VM

def stop_vbox_vm(install_client)
  exists = check_vbox_vm_exists(install_client)
  if exists.match(/yes/)
    message = "Stopping:\tVM "+install_client
    command = "VBoxManage controlvm #{install_client} poweroff"
    execute_command(message,command)
  end
  return
end

# Get VirtualBox VM MAC address

def get_vbox_vm_mac(install_client)
  install_search = "MAC"
  install_mac    = get_vbox_vm_info(install_client,install_search)
  install_mac    = install_mac.chomp.gsub(/\,/,"")
  return install_mac
end

# Check VirtualBox hostonly network

def check_vbox_hostonly_network(if_name)
  message = "Information:\tChecking VirtualBox hostonly network exists"
  command = "VBoxManage list hostonlyifs |grep '^Name' |awk '{print $2}' |head -1"
  if_name = execute_command(message,command)
  if_name = if_name.chomp
  if !if_name.match(/vboxnet/)
    message = "information:\tPlumbing VirtualBox hostonly network"
    command = "VBoxManage hostonlyif create"
    execute_command(message,command)
    message = "Information:\tFinding VirtualBox hostonly network name"
    command = "VBoxManage list hostonlyifs |grep '^Name' |awk '{print $2}' |head -1"
    if_name = execute_command(message,command)
    if_name = if_name.chomp
    if_name = if_name.gsub(/'/,"")
    message = "Information:\tDisabling DHCP on "+if_name
    command = "VBoxManage dhcpserver remove --ifname #{if_name}"
    execute_command(message,command)
  end
  message = "Information:\tChecking VirtualBox hostonly network "+if_name+" has address "+$default_hostonly_ip
  command = "VBoxManage list hostonlyifs |grep 'IPAddress' |awk '{print $2}' |head -1"
  host_ip = execute_command(message,command)
  host_ip = host_ip.chomp
  if !host_ip.match(/#{$default_hostonly_ip}/)
    message = "Information:\tConfiguring VirtualBox hostonly network "+if_name+" with IP "+$default_hostonly_ip
    command = "VBoxManage hostonlyif ipconfig #{if_name} --ip #{$default_hostonly_ip} --netmask #{$default_netmask}"
    execute_command(message,command)
  end
  message = "Information:\tChecking VirtualBox DHCP Server is Disabled"
  command = "VBoxManage list dhcpservers"
  output  = execute_command(message,command)
  if output.match(/Enabled/)
    message = "Information:\tDisabling VirtualBox DHCP Server\t"
    command = "VBoxManage dhcpserver remove --netname HostInterfaceNetworking-#{if_name}"
  end
  if $os_name.match(/Darwin/)
    gw_if_name = get_osx_gw_if_name()
    if $os_rel.split(".")[0].to_i < 14
      check_osx_nat(gw_if_name,if_name)
    else
      check_osx_pfctl(gw_if_name,if_name)
    end
  else
    if $os_name.match(/Solaris/)
      message = "Information:\tChecking IPv4 Routing is Enabled"
      command = "routeadm |grep 'IPv4 routing'"
      output  = execute_command(message,command)
      if output.match(/disabled/)
        message = "Information:\tEnabling IPv4 Routing"
        command = "routeadm -e ipv4-routing -u"
        execute_command(message,command)
      end
      message = "Information:\tChecking IPv4 Forwarding is Enabled"
      command = "routeadm |grep 'IPv4 forwarding'"
      output  = execute_command(message,command)
      if output.match(/disabled/)
        message = "Information:\tEnabling IPv4 Forwarding"
        command = "routeadm -e ipv4-forwarding -u"
        execute_command(message,command)
      end
      message = "Information:\tChecking DHCP Server is listening on "+if_name
      command = "svccfg -s svc:/network/dhcp/server:ipv4 listprop config/listen_ifnames |grep #{if_name}"
      output  = execute_command(message,command)
      if !output.match(/#{if_name}/)
        message = "Information:\tSetting DHCP Server to listen on "+if_name
        command = "svccfg -s svc:/network/dhcp/server:ipv4 setprop config/listen_ifnames = astring: #{if_name} ; svcadm refresh svc:/network/dhcp/server:ipv4"
        execute_command(message,command)
      end
    end
  end
  return if_name
end

# Check VirtualBox is installed

def check_vbox_is_installed()
  install_status = "no"
  if $os_name.match(/Darwin/)
    app_dir = "/Applications/VirtualBox.app"
  else
    app_dir = "/usr/bin"
  end
  if File.directory?(app_dir)
    set_vboxmanage_bin()
    if $vboxmanage_bin.match(/[a-z]/)
      install_status = "yes"
      fix_vbox_mouse_integration()
    end
  end
  return install_status
end

# Add CPU to Virtualbox VM

def add_cpu_to_vbox_vm(install_client,install_cpu)
  if install_cpu.to_i > 1
    message = "Information:\tSetting number of CPUs to "+install_cpu
    command = "VBoxManage modifyvm \"#{install_client}\" --cpus #{install_cpu}"
    execute_command(message,command)
  end
  return
end

# Configure a VirtualBox VM

def configure_vbox_vm(install_client,install_mac,install_os,install_size,install_file,install_memory,install_cpu,install_network,install_share,install_mount)
  check_vbox_is_installed()
  if $default_vm_network.match(/hostonly/)
    if_name       = get_bridged_vbox_nic()
    vbox_nic_name = check_vbox_hostonly_network(if_name)
  end
  vbox_vm_dir      = get_vbox_vm_dir(install_client)
  vbox_disk_name   = vbox_vm_dir+"/"+install_client+".vdi"
  vbox_socket_name = "/tmp/#{install_client}"
  vbox_controller  = get_vbox_controller()
  check_vbox_vm_doesnt_exist(install_client)
  register_vbox_vm(install_client,install_os)
  add_controller_to_vbox_vm(install_client,vbox_controller)
  if !install_file.match(/ova$/)
    create_vbox_hdd(install_client,vbox_disk_name,install_size)
    add_hdd_to_vbox_vm(install_client,vbox_disk_name)
  end
  add_memory_to_vbox_vm(install_client,install_memory)
  vbox_socket_name = add_socket_to_vbox_vm(install_client)
  add_serial_to_vbox_vm(install_client)
  if $default_vm_network.match(/bridged/)
    vbox_nic_name = get_bridged_vbox_nic()
    add_bridged_network_to_vbox_vm(install_client,vbox_nic_name)
  else
    add_nonbridged_network_to_vbox_vm(install_client,vbox_nic_name)
  end
  set_vbox_vm_boot_priority(install_client)
  if install_file.match(/iso$/)
    add_cdrom_to_vbox_vm(install_client,install_file)
  end
  add_tools_to_vbox_vm(install_client)
  if install_mac.match(/[0-9]/)
    change_vbox_vm_mac(install_client,install_mac)
  else
    install_mac = get_vbox_vm_mac(install_client)
  end
  if install_os.match(/ESXi/)
    configure_vmware_esxi_vbox_vm(install_client)
  end
  add_cpu_to_vbox_vm(install_client,install_cpu)
  puts "Information:\tCreated VirtualBox VM "+install_client+" with MAC address "+install_mac
  return
end

# Check VirtualBox NATd

def check_vbox_natd(if_name,install_network)
  check_vbox_is_installed()
  if install_network.match(/hostonly/)
    check_vbox_hostonly_network(if_name)
  end
  return
end

# Unconfigure a Virtual Box VM

def unconfigure_vbox_vm(install_client)
  check_vbox_is_installed()
  exists = check_vbox_vm_exists(install_client)
  if exists.match(/no/)
    exists = check_vbox_vm_config_exists(install_client)
    if exists.match(/yes/)
      delete_vbox_vm_config(install_client)
    else
      puts "Warning:\tVirtualBox VM "+install_client+" does not exist"
      return
    end
  end
  stop_vbox_vm(install_client)
  sleep(5)
  message = "Information:\tDeleting VirtualBox VM "+install_client
  command = "VBoxManage unregistervm #{install_client} --delete"
  execute_command(message,command)
  delete_vbox_vm_config(install_client)
  return
end
