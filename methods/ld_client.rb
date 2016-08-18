# Guest Domain support code

# Check Guest Domain is running

def check_gdom_is_running(install_client)
  message = "Information:\tChecking Guest Domain "+install_client+" is running"
  command = "ldm list-bindings #{install_client} |grep '^#{install_client}'"
  output  = execute_command(message,command)
  if !output.match(/active/)
    handle_output("Warning:\tGuest Domain #{install_client} is not running")
    exit
  end
  return
end

# Check Guest Domain isn't running

def check_gdom_isnt_running(install_client)
  message = "Information:\tChecking Guest Domain "+install_client+" is running"
  command = "ldm list-bindings #{install_client} |grep '^#{install_client}'"
  output  = execute_command(message,command)
  if output.match(/active/)
    handle_output("Warning:\tGuest Domain #{install_client} is already running")
    exit
  end
  return
end

# Get Guest domain MAC

def get_gdom_mac(install_client)
  message    = "Information:\tGetting guest domain "+install_client+" MAC address"
  command    = "ldm list-bindings #{install_client} |grep '#{$default_gdom_vnet}' |awk '{print $5}'"
  output     = execute_command(message,command)
  client_mac = output.chomp
  return client_mac
end

# List available LDoms

def list_gdoms()
  if $os_info.match(/SunOS/)
    if $os_rel.match(/10|11/)
      if $os_info.match(/sun4v/)
        ldom_type    = "Guest Domain"
        ldom_command = "ldm list |grep -v NAME |grep -v primary |awk '{print $1}'"
        list_doms(ldom_type,ldom_command)
      else
        if $verbose_mode == 1
          handle_output("") 
          handle_output("Warning:\tThis service is only available on the Sun4v platform")
          handle_output("") 
        end
      end
    else
      if $verbose_mode == 1
        handle_output("") 
        handle_output("Warning:\tThis service is only available on Solaris 10 or later")
        handle_output("") 
      end
    end
  else
    if $verbose_mode == 1
      handle_output("") 
      handle_output("Warning:\tThis service is only available on Solaris")
      handle_output("") 
    end
  end
  return
end

def list_gdom_vms()
  list_gdoms()
  return
end

def list_all_gdom_vms()
  list_gdoms()
  return
end

# Create Guest domain disk

def create_gdom_disk(install_client)
  client_disk = $q_struct["gdom_disk"].value
  disk_size   = $q_struct["gdom_size"].value
  disk_size   = disk_size.downcase
  vds_disk    = install_client+"_vdisk0"
  if !client_disk.match(/\/dev/)
    if !File.exists?(client_disk)
      message = "Information:\tCreating guest domain disk "+client_disk+" for client "+install_client
      command = "mkfile -n #{disk_size} #{client_disk}"
      output = execute_command(message,command)
    end
  end
  message = "Information:\tChecking Virtual Disk Server device doesn't already exist"
  command = "ldm list-services |grep 'primary-vds0' |grep '#{vds_disk}'"
  output = execute_command(message,command)
  if !output.match(/#{install_client}/)
    message = "Information:\tAdding disk device to Virtual Disk Server"
    command = "ldm add-vdsdev #{client_disk} #{vds_disk}@primary-vds0"
    output = execute_command(message,command)
  end
  return
end

# Check Guest domain doesn't exist

def check_gdom_doesnt_exist(install_client)
  message = "Information:\tChecking guest domain "+install_client+" doesn't exist"
  command = "ldm list |grep #{install_client}"
  output  = execute_command(message,command)
  if output.match(/#{install_client}/)
    handle_output("Warning:\tGuest domain #{install_client} already exists")
    exit
  end
  return
end

# Check Guest domain doesn't exist

def check_gdom_exists(install_client)
  message = "Information:\tChecking guest domain "+install_client+" exist"
  command = "ldm list |grep #{install_client}"
  output  = execute_command(message,command)
  if !output.match(/#{install_client}/)
    handle_output("Warning:\tGuest domain #{install_client} doesn't exist")
    exit
  end
  return
end

# Start Guest domain

def start_gdom(install_client)
  message = "Information:\tStarting guest domain "+install_client
  command = "ldm start-domain #{install_client}"
  execute_command(message,command)
  return
end

# Stop Guest domain

def stop_gdom(install_client)
  message = "Information:\tStopping guest domain "+install_client
  command = "ldm stop-domain #{install_client}"
  execute_command(message,command)
  return
end

# Bind Guest domain

def bind_gdom(install_client)
  message = "Information:\tBinding guest domain "+install_client
  command = "ldm bind-domain #{install_client}"
  execute_command(message,command)
  return
end

# Unbind Guest domain

def unbind_gdom(install_client)
  message = "Information:\tUnbinding guest domain "+install_client
  command = "ldm unbind-domain #{install_client}"
  execute_command(message,command)
  return
end

# Remove Guest domain

def remove_gdom(install_client)
  message = "Information:\tRemoving guest domain "+install_client
  command = "ldm remove-domain #{install_client}"
  execute_command(message,command)
  return
end

# Remove Guest domain disk

def remove_gdom_disk(install_client)
  vds_disk = install_client+"_vdisk0"
  message = "Information:\tRemoving disk "+vds_disk+" from Virtual Disk Server"
  command = "ldm remove-vdisk #{vds_disk} #{install_client}"
  execute_command(message,command)
  return
end

# Delete Guest domain disk

def delete_gdom_disk(install_client)
  gdom_dir    = $ldom_base_dir+"/"+install_client
  client_disk = gdom_dir+"/vdisk0"
  message = "Information:\tRemoving disk "+client_disk
  command = "rm #{client_disk}"
  execute_command(message,command)
  return
end

# Delete Guest domain directory

def delete_gdom_dir(install_client)
  gdom_dir    = $ldom_base_dir+"/"+install_client
  destroy_zfs_fs(gdom_dir)
  return
end

# Create Guest domain

def create_gdom(install_client)
  memory   = $q_struct["gdom_memory"].value
  vcpu     = $q_struct["gdom_vcpu"].value
  vds_disk = install_client+"_vdisk0"
  message = "Information:\tCreating guest domain "+install_client
  command = "ldm add-domain #{install_client}"
  execute_command(message,command)
  message = "Information:\tAdding vCPUs to Guest domain "+install_client
  command = "ldm add-vcpu #{vcpu} #{install_client}"
  execute_command(message,command)
  message = "Information:\tAdding memory to Guest domain "+install_client
  command = "ldm add-memory #{memory} #{install_client}"
  execute_command(message,command)
  message = "Information:\tAdding network to Guest domain "+install_client
  command = "ldm add-vnet #{$default_gdom_vnet} primary-vsw0 #{install_client}"
  execute_command(message,command)
  message = "Information:\tAdding isk to Guest domain "+install_client
  command = "ldm add-vdisk vdisk0 #{vds_disk}@primary-vds0 #{install_client}"
  execute_command(message,command)
  return
end

# Configure Guest domain

def configure_gdom(install_client,install_ip,install_mac,install_arch,install_os,install_release,publisher_host,install_file,install_service)
  service_name = ""
  check_dpool()
  check_gdom_doesnt_exist(install_client)
  if !File.directory?($ldom_base_dir)
    check_fs_exists($ldom_base_dir)
    message = "Information:\tSetting mount point for "+$ldom_base_dir
    command = "zfs set mountpoint=#{$ldom_base_dir} #{$default_zpool}#{$ldom_base_dir}"
    execute_command(message,command)
  end
  gdom_dir = $ldom_base_dir+"/"+install_client
  if !File.directory?(gdom_dir)
    check_fs_exists(gdom_dir)
    message = "Information:\tSetting mount point for "+gdom_dir
    command = "zfs set mountpoint=#{gdom_dir} #{$default_zpool}#{gdom_dir}"
    execute_command(message,command)
  end
  populate_gdom_questions(install_client)
  process_questions(install_service)
  create_gdom_disk(install_client)
  create_gdom(install_client)
  bind_gdom(install_client)
  return
end

def configure_gdom_client(install_client,install_ip,install_mac,install_arch,install_os,install_release,publisher_host,install_file,install_service)
  configure_gdom(install_client,install_ip,install_mac,install_arch,install_os,install_release,publisher_host,install_file,install_service)
  return
end

def configure_ldom_client(install_client,install_ip,install_mac,install_arch,install_os,install_release,publisher_host,install_file,install_service)
  configure_gdom(install_client,install_ip,install_mac,install_arch,install_os,install_release,publisher_host,install_file,install_service)
  return
end

# Unconfigure Guest domain

def unconfigure_gdom(install_client)
  check_gdom_exists(install_client)
  stop_gdom(install_client)
  unbind_gdom(install_client)
  remove_gdom_disk(install_client)
  remove_gdom(install_client)
  delete_gdom_disk(install_client)
  delete_gdom_dir(install_client)
  return
end

# Boot Guest Domain

def boot_gdom_vm(install_client,install_type)
  check_gdom_exists(install_client) 
  check_gdom_isnt_running(install_client)
  start_gdom(install_client)
  return
end

# Stop Guest Domain

def stop_gdom_vm(install_client)
  check_gdom_exists(install_client) 
  check_gdom_is_running(install_client)
  stop_gdom(install_client)
  return
end

# Get Guest Domain Console Port

def get_gdom_console_port(install_client)
  message  = "Information:\tDetermining Virtual Console Port for Guest Domain "+install_client
  command  = "ldm list-bindings #{install_client} |grep vcc |awk '{print $3}'"
  vcc_port = execute_command(message,command)
  return vcc_port
end


# Connect to Guest Domain Console

def connect_to_gdom_console(install_client)
  check_cdom_vntsd()
  check_gdom_exists(install_client)
  check_gdom_is_running(install_client)
  vcc_port = get_gdom_console_port(install_client)
  vcc_port = vcc_port.chomp
  handle_output("") 
  handle_output("To connect to console of Guest Domain #{install_client} type the following command: ")
  handle_output("") 
  handle_output("telnet localhost #{vcc_port}")
  handle_output("") 
  return
end

# Set Guest Domain value

def set_gdom_value(instal_client,install_param,install_value)
  check_gdom_exists(install_client)
  message = "Information:\tSetting "+install_param+" for Guest Domain "+install_client+" to "+install_value
  if install_param.match(/autoboot|auto-boot/)
    install_param = "auto-boot\?"
  end
  command = "ldm set-variable #{install_param}=#{install_value} #{install_client}"
  execute_command(message,command)
  return
end

