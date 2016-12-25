

# Code for creating client VMs for testing (e.g. VirtualBox)

# Handle VM install status

def handle_vm_install_status(install_vm,install_status)
  if install_status.match(/no/)
    handle_output("Warning:\tVirtualisation application does not exist for #{install_vm}")
    exit
  end
  return
end

# Try to get client VM type

def get_client_vm_type(install_client)
  install_vm = ""
  $valid_vm_list.each do |test_vm|
    exists = eval"[check_#{test_vm}_is_installed]"
    if exists.to_s.match(/yes/)
      exists = eval"[check_#{test_vm}_vm_exists(install_client)]"
      if exists.to_s.match(/yes/)
        install_vm = test_vm
        return install_vm
      end
    end
  end
  return install_vm
end

# Get Guest OS type

def get_guest_os(install_arch,install_method)
  install_os = eval"[get_#{install_vm}_guest_os(install_method,install_arch)]"
  return install_os
end

# Check VM network

def check_vm_network(install_vm,install_mode,install_network)
  check_local_config(install_mode)
  gw_if_name = get_osx_gw_if_name()
  if_name    = get_osx_vm_if_name(install_vm)
  eval"[check_#{install_vm}_natd(if_name,install_network)]"
  message = "Information:\tChecking "+if_name+" is configured"
  command = "ifconfig #{if_name} |grep inet"
  output  = execute_command(message,command)
  if !output.match(/#{$default_gateway}/)
    message = "Information:\tConfiguring "+if_name
    command = "sudo sh -c 'ifconfig #{if_name} inet #{$default_gateway} netmask #{$default_netmask} up'"
    execute_command(message,command)
  end
  return
end

# Control VM

def control_vm(install_vm,install_action,install_client,install_console)
  eval"[#{install_action}_#{install_vm}_vm(install_client)]"
  return
end

# Delete VM

def delete_vm(install_vm,install_client)
  eval"[unconfigure_#{install_vm}_vm(install_client)]"
  return
end

# Delete VM snapshot

def delete_vm_snapshot(install_vm,install_client,install_clone)
  eval"[delete_#{install_vm}_vm_snapshot(install_client,install_clone)]"
  return
end

#def create_vm(install_client,client_ip,install_mac,client_arch,install_os,client_rel,publisherhost,image_file,service_name)
#  eval"[configure_#{vfunct}(install_client,client_ip,install_mac,client_arch,install_os,client_rel,publisherhost,image_file,service_name)]"
#  return
#end

def create_vm(install_method,install_vm,install_client,install_mac,install_os,install_arch,install_release,install_size,install_file,install_memory,install_cpu,install_network,install_share,install_mount,install_ip)
  if install_vm.match(/fusion/) and install_mac.match(/[0-9]/)
    install_mac = check_fusion_vm_mac(install_mac)
  end
  if !install_method.match(/[a-z]/) and !install_os.match(/[a-z]/)
    if $verbose_mode == true
      handle_output("Warning:\tInstall method or OS not specified")
      handle_output("Information:\tSetting OS to other")
    end
    install_method = "other"
  end
  if install_file.match(/ova$/)
    if install_vm.match(/vbox/)
      eval"[configure_#{install_method}_#{install_vm}_vm(install_client,install_mac,install_arch,install_os,install_release,install_size,install_file,install_memory,install_cpu,install_network,install_share,install_mount)]"
    end
    eval"[import_#{install_vm}_ova(install_client,install_mac,install_ip,install_file)]"
  else
    eval"[configure_#{install_method}_#{install_vm}_vm(install_client,install_mac,install_arch,install_os,install_release,install_size,install_file,install_memory,install_cpu,install_network,install_share,install_mount)]"
  end
  return
end

# list VMs

def list_vms(install_vm,install_type)
  if !install_type
    install_type = "all"
  else
    if !install_type.match(/[a-z]/)
      install_type = "all"
    end
  end
  if install_vm.match(/[a-z]/)
    eval"[list_#{install_vm}_vms(install_type)]"
  else
    $valid_vm_list.each do |vm_type|
      case vm_type
      when /parallels/
        parallels_test = %x[which prlctl].chomp
        if parallels_test.match(/prlctl/) and !parallels_test.match(/no /)
          eval"[list_#{vm_type}_vms(install_type)]"
        end
      when /vbox/
        set_vboxmanage_bin()
        if $vboxmanage_bin.match(/[a-z]/)
          eval"[list_#{vm_type}_vms(install_type)]"
        end
      else
        eval"[list_#{vm_type}_vms(install_type)]"
      end
    end
  end
  return
end

# list VM

def list_vm(install_vm,install_os,install_method)
  if !install_os.match(/[a-z]/) and !install_method.match(/[a-z]/)
    eval"[list_all_#{install_vm}_vms()]"
  else
    if install_method.match(/[a-z]/)
      eval"[list_#{install_method}_#{install_vm}_vms()]"
    else
      [ "ks", "js", "ps", "ay", "ai" ].each do |install_method|
        eval"[list_#{install_method}_#{install_vm}_vms()]"
      end
    end
  end
  return
end

# List VM snaphots

def list_vm_snapshots(install_vm,install_os,install_method,install_client)
  if install_client.match(/[a-z]/)
    eval"[list_#{install_vm}_vm_snapshots(install_client)]"
  else
    if !install_os.match(/[a-z]/) and !install_method.match(/[a-z]/)
      eval"[list_all_#{install_vm}_vm_snapshots()]"
    end
  end
  return
end

# Catch all for listing VMs

def list_none_vms(install_type)
  return
end
