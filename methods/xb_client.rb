# Code for *BSD and other PXE clients (e.g. CoreOS)

# List BSD clients

def list_xb_clients()
  return
end

# Configure client PXE boot

def configure_xb_pxe_client(install_client,client_ip,install_mac,client_arch,install_service,publisherhost)
  os_version    = install_service.split(/_/)[1..2].join(".")
  tftp_pxe_file = install_mac.gsub(/:/,"")
  tftp_pxe_file = tftp_pxe_file.upcase
  tmp_file      = "/tmp/pxecfg"
  if install_service.match(/openbsd/)
    tftp_pxe_file = "01"+tftp_pxe_file+".pxeboot"
    test_file     = $tftp_dir+"/"+tftp_pxe_file
    pxeboot_file  = install_service+"/"+os_version+"/"+client_arch.gsub(/x86_64/,"amd64")+"/pxeboot"
  else
    tftp_pxe_file = "01"+tftp_pxe_file+".pxelinux"
    test_file     = $tftp_dir+"/"+tftp_pxe_file
    pxeboot_file  = install_service+"/isolinux/pxelinux.0"
  end
  if File.symlink?(test_file)
    message = "Information:\tRemoving old PXE boot file "+test_file
    command = "rm #{test_file}"
    execute_command(message,command)
  end
  message = "Information:\tCreating PXE boot file for "+install_client+" with MAC address "+install_mac
  command = "cd #{$tftp_dir} ; ln -s #{pxeboot_file} #{tftp_pxe_file}"
  execute_command(message,command)
  if install_service.match(/coreos/)
    ldlinux_file = $tftp_dir+"/"+install_service+"/isolinux/ldlinux.c32"
    ldlinux_link = $tftp_dir+"/ldlinux.c32"
    if !File.exist?(ldlinux_link)
      message = "Information:\tCopying file #{ldlinux_file} #{ldlinux_link}"
      command = "cp #{ldlinux_file} #{ldlinux_link}"
      execute_command(message,command)
    end
    client_dir   = $client_base_dir+"/"+install_service+"/"+install_client
    client_file  = client_dir+"/"+install_client+".yml"
    client_url   = "http://"+publisherhost+"/clients/"+install_service+"/"+install_client+"/"+install_client+".yml"
    pxe_cfg_dir  = $tftp_dir+"/pxelinux.cfg"
    pxe_cfg_file = install_mac.gsub(/:/,"-")
    pxe_cfg_file = "01-"+pxe_cfg_file
    pxe_cfg_file = pxe_cfg_file.downcase
    pxe_cfg_file = pxe_cfg_dir+"/"+pxe_cfg_file
    vmlinuz_file = "/"+install_service+"/coreos/vmlinuz"
    initrd_file  = "/"+install_service+"/coreos/cpio.gz"
    file         = File.open(tmp_file,"w")
    file.write("default coreos\n")
    file.write("prompt 1\n")
    file.write("timeout 3\n")
    file.write("label coreos\n")
    file.write("  menu default\n")
    file.write("  kernel #{vmlinuz_file}\n")
    file.write("  append initrd=#{initrd_file} cloud-config-url=#{client_url}\n")
    file.close
    message = "Information:\tCreating PXE configuration file "+pxe_cfg_file
    command = "cp #{tmp_file} #{pxe_cfg_file} ; rm #{tmp_file}"
    execute_command(message,command)
    print_contents_of_file("",pxe_cfg_file)
  end
  return
end

# Unconfigure BSD client

def unconfigure_xb_client(install_client,install_mac,install_service)
  unconfigure_xb_pxe_client(install_client)
  unconfigure_xb_dhcp_client(install_client)
  return
end

# Configure DHCP entry

def configure_xb_dhcp_client(install_client,install_mac,client_ip,client_arch,install_service)
  add_dhcp_client(install_client,install_mac,client_ip,client_arch,install_service)
  return
end

# Unconfigure DHCP client

def unconfigure_xb_dhcp_client(install_client)
  remove_dhcp_client(install_client)
  return
end

# Unconfigure client PXE boot

def unconfigure_xb_pxe_client(install_client)
  install_mac=get_install_mac(install_client)
  if !install_mac
    handle_output("Warning:\tNo MAC Address entry found for #{install_client}")
    exit
  end
  tftp_pxe_file = install_mac.gsub(/:/,"")
  tftp_pxe_file = tftp_pxe_file.upcase
  tftp_pxe_file = "01"+tftp_pxe_file+".pxeboot"
  tftp_pxe_file = $tftp_dir+"/"+tftp_pxe_file
  if File.exist?(tftp_pxe_file)
    message = "Information:\tRemoving PXE boot file "+tftp_pxe_file+" for "+install_client
    command = "rm #{tftp_pxe_file}"
    output  = execute_command(message,command)
  end
  unconfigure_xb_dhcp_client(install_client)
  return
end

# Output CoreOS client configuration file

def output_coreos_client_profile(install_client,install_service)
  client_dir = $client_base_dir+"/"+install_service+"/"+install_client
  check_dir_exists(client_dir)
  output_file  = client_dir+"/"+install_client+".yml"
  root_crypt   = $q_struct["root_crypt"].value
  admin_group  = $q_struct["admin_group"].value
  admin_user   = $q_struct["admin_user"].value
  admin_crypt  = $q_struct["admin_crypt"].value
  admin_home   = $q_struct["admin_home"].value
  admin_uid    = $q_struct["admin_uid"].value
  admin_gid    = $q_struct["admin_gid"].value
  client_ip    = $q_struct["ip"].value
  client_nic   = $q_struct["nic"].value
  network_ip   = client_ip.split(".")[0..2].join(".")+".0"
  broadcast_ip = client_ip.split(".")[0..2].join(".")+".255"
  gateway_ip   = client_ip.split(".")[0..2].join(".")+".254"
  file = File.open(output_file,"w")
  file.write("\n")
  file.write("network-interfaces: |\n")
  file.write("  iface #{client_nic} inet static\n")
  file.write("  address #{client_ip}\n")
  file.write("  network #{network_ip}\n")
  file.write("  netmask #{$default_netmask}\n")
  file.write("  broadcast #{broadcast_ip}\n")
  file.write("  gateway #{gateway_ip}\n")
  file.write("\n")
  file.write("hostname: #{install_client}\n")
  file.write("\n")
  file.write("users:\n")
  file.write("  - name: root\n")
  file.write("    passwd: #{root_crypt}\n")
  file.write("  - name: #{admin_user}\n")
  file.write("    passwd: #{admin_crypt}\n")
  file.write("    groups: sudo\n")
  file.write("\n")
  return output_file
end

# Configure BSD client

def configure_xb_client(install_client,install_arch,install_mac,install_ip,install_model,publisherhost,install_service,
                        install_file,install_memory,install_cpu,install_network,install_license,install_mirror,install_type)
  repo_version_dir = $repo_base_dir+"/"+install_service
  if !File.directory?(repo_version_dir)
    handle_output("Warning:\tService #{install_service} does not exist")
    handle_output("")
    list_xb_services()
    exit
  end
  if install_service.match(/coreos/)
    populate_coreos_questions(install_service,install_client,install_ip)
    process_questions(install_service)
    output_coreos_client_profile(install_client,install_service)
  end
  configure_xb_pxe_client(install_client,install_ip,install_mac,install_arch,install_service,publisherhost)
  configure_xb_dhcp_client(install_client,install_mac,install_ip,install_arch,install_service)
  add_hosts_entry(install_client,install_ip)
  return
end
