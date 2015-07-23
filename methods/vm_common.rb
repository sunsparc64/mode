
# Code for creating client VMs for testing (e.g. VirtualBox)

# Check VM network

def check_vm_network(install_vm,install_mode,install_network)
  check_local_config(install_mode)
  gw_if_name = get_osx_gw_if_name()
  if_name    = get_osx_vm_if_name(install_vm)
  eval"[check_#{install_vm}_natd(if_name,install_network)]"
  check_osx_nat(gw_if_name,if_name)
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

#def create_vm(install_client,client_ip,install_mac,client_arch,install_os,client_rel,publisher_host,image_file,service_name)
#  eval"[configure_#{vfunct}(install_client,client_ip,install_mac,client_arch,install_os,client_rel,publisher_host,image_file,service_name)]"
#  return
#end

def create_vm(install_method,install_vm,install_client,install_mac,install_os,install_arch,install_release,install_size,install_file,install_memory,install_cpu,install_network,install_share,install_mount,install_ip)
  if !install_method.match(/[a-z]/) and !install_os.match(/[a-z]/)
    if $verbose_mode == 1
      puts "Warning:\tInstall method or OS not specified"
      puts "Information:\tSetting OS to other"
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
