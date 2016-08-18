
# Solaris Zones support code

# Check we are on Solaris 10 or later

def check_zone_is_installed()
  if $os_name.match(/SunOS/)
    if $os_rel.split(/\./)[0].to_i > 10
      exists = "yes"
    else
      exists = "no"
    end
  else
    exists = "no"
  end
  return exists
end

# List zone services

def list_zone_services()
  os_version = $os_rel.split(/\./)[1]
  os_branded = os_version.to_i-1
  os_branded = os_branded.to_s
  handle_output("Supported containers:")
  handle_output("") 
  handle_output("Solaris #{os_version} (native)")
  handle_output("Solaris #{os_branded} (branded)")
  return
end

def get_zone_image_info(image_file)
  image_info    = image_file.split(/\-/)
  image_os      = image_info[0].split(//)[0..2].join
  image_version = image_info[1].gsub(/u/,".")
  image_arch    = image_info[2]
  if image_arch.match(/x86/)
    image_arch = "i386"
  end
  install_service = image_os+"_"+image_version.gsub(/\./,"_")+"_"+image_arch
  return image_version,image_arch,install_service
end

# List zone ISOs/Images

def list_zone_isos()
  iso_list = Dir.entries($iso_base_dir).grep(/solaris/)
  if iso_list.length > 0
    if $output_format.match(/html/)
      handle_output("<h1>Available branded zone images:</h1>")
      handle_output("<table border=\"1\">")
      handle_output("<tr>")
      handle_output("<th>Image File</th>")
      handle_output("<th>Distribution</th>")
      handle_output("<th>Architecture</th>")
      handle_output("<th>Service Name</th>")
      handle_output("</tr>")
    else
      handle_output("Available branded zone images:")
      handle_output("") 
    end
    if $os_arch.match(/sparc/)
      search_arch = $os_arch
    else
      search_arch = "x86"
    end
    iso_list.each do |image_file|
      image_file = image_file.chomp
      if image_file.match(/^solaris/) and image_file.match(/bin$/)
        if image_file.match(/#{search_arch}/)
          (image_version,image_arch,install_service) = get_zone_image_info(image_file)
          if $output_format.match(/html/)
            handle_output("<tr>")
            handle_output("<td>#{$iso_base_dir}/#{image_file}</td>")
            handle_output("<td>Solaris</td>")
            handle_output("<td>#{image_version}</td>")
            handle_output("<td>#{install_service}</td>")
            handle_output("</tr>")
          else
            handle_output("Image file:\t#{$iso_base_dir}/#{image_file}")
            handle_output("Distribution:\tSolaris")
            handle_output("Version:\t#{image_version}")
            handle_output("Architecture:\t#{image_arch}")
            handle_output("Service Name\t#{install_service}")
          end
        end
      end
    end
    if $output_format.match(/html/)
      handle_output("</table>")
    else
      handle_output("")
    end
  end
  return
end

# List available zones

def list_zones()
  handle_output("Available Zones:")
  handle_output("") 
  message = ""
  command = "zoneadm list |grep -v global"
  output  = execute_command(message,command)
  handle_output(output)
  return
end

# List zones

def list_zone_vms(install_type)
  list_zones()
  return
end

# Print branded zone information

def print_branded_zone_info()
  branded_url = "http://www.oracle.com/technetwork/server-storage/solaris11/vmtemplates-zones-1949718.html"
  branded_dir = "/export/isos"
  handle_output("Warning:\tBranded zone templates not found")
  handle_output("Information:\tDownload them from #{branded_url}")
  handle_output("Information:\tCopy them to #{branded_dir}")
  handle_output("") 
  return
end

# Check branded zone support is installed

def check_branded_zone_pkg()
  if $os_rel.match(/11/)
    message = "Information:\tChecking branded zone support is installed"
    command = "pkg info pkg:/system/zones/brand/brand-solaris10 |grep Version |awk '{print $2}'"
    output  = execute_command(message,command)
    if !output.match(/[0-9]/)
      message = "Information:\tInstalling branded zone packages"
      command = "pkg install pkg:/system/zones/brand/brand-solaris10"
      execute_command(message,command)
    end
  end
  return
end

# Standard zone post install

def standard_zone_post_install(install_client,client_rel)
  zone_dir = $zone_base_dir+"/"+install_client
  if File.directory?(zone_dir)
    client_dir    = zone_dir+"/root"
    tmp_file      = "/tmp/zone_"+install_client
    admin_username = $q_struct["admin_username"].value
    admin_uid      = $q_struct["admin_uid"].value
    admin_gid      = $q_struct["admin_gid"].value
    admin_crypt    = $q_struct["admin_crypt"].value
    root_crypt    = $q_struct["root_crypt"].value
    admin_fullname = $q_struct["admin_description"].value
    admin_home     = $q_struct["admin_home"].value
    admin_shell    = $q_struct["admin_shell"].value
    passwd_file   = client_dir+"/etc/passwd"
    shadow_file   = client_dir+"/etc/shadow"
    message = "Checking:\tUser "+admin_username+" doesn't exist"
    command = "cat #{passwd_file} | grep -v '#{admin_username}' > #{tmp_file}"
    execute_command(message,command)
    message   = "Adding:\tUser "+admin_username+" to "+passwd_file
    admin_info = admin_username+":x:"+admin_uid+":"+admin_gid+":"+admin_fullname+":"+admin_home+":"+admin_shell
    command = "echo '#{admin_info}' >> #{tmp_file} ; cat #{tmp_file} > #{passwd_file} ; rm #{tmp_file}"
    execute_command(message,command)
    print_contents_of_file("",passwd_file)
    info = IO.readlines(shadow_file)
    file = File.open(tmp_file,"w")
    info.each do |line|
      field = line.split(":")
      if field[0] != "root" and field[0] != "#{admin_username}"
        file.write(line)
      end
      if field[0].match(/root/)
        field[1] = root_crypt
        copy = field.join(":")
        file.write(copy)
      end
    end
    output = admin_username+":"+admin_crypt+":::99999:7:::\n"
    file.write(output)
    file.close
    message = "Information:\tCreating shadow file"
    command = "cat #{tmp_file} > #{shadow_file} ; rm #{tmp_file}"
    execute_command(message,command)
    print_contents_of_file("",shadow_file)
    client_home = client_dir+admin_home
    message = "Information:\tCreating SSH directory for "+admin_username
    command = "mkdir -p #{client_home}/.ssh ; cd #{client_dir}/export/home ; chown -R #{admin_uid}:#{admin_gid} #{admin_username}"
    execute_command(message,command)
    # Copy admin user keys
    rsa_file = admin_home+"/.ssh/id_rsa.pub"
    dsa_file = admin_home+"/.ssh/id_dsa.pub"
    key_file = client_home+"/.ssh/authorized_keys"
    if File.exists?(key_file)
      system("rm #{key_file}")
    end
    [rsa_file,dsa_file].each do |pub_file|
      if File.exists?(pub_file)
        message = "Information:\tCopying SSH public key "+pub_file+" to "+key_file
        command = "cat #{pub_file} >> #{key_file}"
        execute_command(message,command)
      end
    end
    message = "Information:\tCreating SSH directory for root"
    command = "mkdir -p #{client_dir}/root/.ssh ; cd #{client_dir} ; chown -R 0:0 root"
    execute_command(message,command)
    # Copy root keys
    rsa_file = "/root/.ssh/id_rsa.pub"
    dsa_file = "/root/.ssh/id_dsa.pub"
    key_file = client_dir+"/root/.ssh/authorized_keys"
    if File.exists?(key_file)
      system("rm #{key_file}")
    end
    [rsa_file,dsa_file].each do |pub_file|
      if File.exists?(pub_file)
        message = "Information:\tCopying SSH public key "+pub_file+" to "+key_file
        command = "cat #{pub_file} >> #{key_file}"
        execute_command(message,command)
      end
    end
    # Fix permissions
    message = "Information:\tFixing SSH permissions for "+admin_username
    command = "cd #{client_dir}/export/home ; chown -R #{admin_uid}:#{admin_gid} #{admin_username}"
    execute_command(message,command)
    message = "Information:\tFixing SSH permissions for root "
    command = "cd #{client_dir} ; chown -R 0:0 root"
    execute_command(message,command)
    # Add sudoers entry
    sudoers_file = client_dir+"/etc/sudoers"
    message = "Information:\tCreating sudoers file "+sudoers_file
    command = "cat #{sudoers_file} |grep -v '^#includedir' > #{tmp_file} ; cat #{tmp_file} > #{sudoers_file}"
    execute_command(message,command)
    message = "Information:\tAdding sudoers include to "+sudoers_file
    command = "echo '#includedir /etc/sudoers.d' >> #{sudoers_file} ; rm #{tmp_file}"
    execute_command(message,command)
    sudoers_dir  = client_dir+"/etc/sudoers.d"
    check_dir_exists(sudoers_dir)
    sudoers_file = sudoers_dir+"/"+admin_username
    message = "Information:\tCreating sudoers file "+sudoers_file
    command = "echo '#{admin_username} ALL=(ALL) NOPASSWD:ALL' > #{sudoers_file}"
    execute_command(message,command)
  else
    handle_output("Warning:\tZone #{install_client} doesn't exist")
    exit
  end
  return
end

# Branded zone post install

def branded_zone_post_install(install_client,client_rel)
  zone_dir = $zone_base_dir+"/"+install_client
  if File.directory?(zone_dir)
    client_dir = zone_dir+"/root"
    var_dir    = "/var/tmp"
    tmp_dir    = client_dir+"/"+var_dir
    post_file  = tmp_dir+"/postinstall.sh"
    tmp_file   = "/tmp/zone_"+install_client
    pkg_name   = "pkgutil.pkg"
    pkg_url    = $local_opencsw_mirror+"/"+pkg_name
    pkg_file   = tmp_dir+"/"+pkg_name
    wget_file(pkg_url,pkg_file)
    file = File.open(tmp_file,"w")
    file.write("#!/usr/bin/bash\n")
    file.write("\n")
    file.write("# Post install script\n")
    file.write("\n")
    file.write("cd #{var_dir} ; echo y |pkgadd -d pkgutil.pkg CSWpkgutil\n")
    file.write("export PATH=/opt/csw/bin:$PATH\n")
    file.write("pkutil -i CSWwget\n")
    file.write("\n")
    file.close
    message = "Information:\tCreating post install script "+post_file
    command = "cp #{tmp_file} #{post_file} ; rm #{tmp_file}"
    execute_command(message,command)
  else
    handle_output("Warning:\tZone #{install_client} doesn't exist")
    exit
  end
  return
end

# Create branded zone

def create_branded_zone(image_file,install_ip,zone_nic,install_client,client_rel)
  check_branded_zone_pkg()
  if Files.exists?(image_file)
    message = "Information:\tInstalling Branded Zone "+install_client
    command = "cd /tmp ; #{image_file} -p #{$zone_base_dir} -i #{zone_nic} -z #{install_client} -f"
    execute_command(message,command)
  else
    handle_output("Warning:\tImage file #{image_file} doesn't exist")
  end
  standard_zone_post_install(install_client,client_rel)
  branded_zone_post_install(install_client,client_rel)
  return
end

# Check zone doesn't exist

def check_zone_doesnt_exist(install_client)
  message = "Information:\tChecking Zone "+install_client+" doesn't exist"
  command = "zoneadm list -cv |awk '{print $2}' |grep '#{install_client}'"
  output  = execute_command(message,command)
  return output
end

# Create zone config

def create_zone_config(install_client,install_ip)
  virtual  = 0
  zone_nic = $q_struct["ipv4_interface_name"].value
  gateway  = $q_struct["ipv4_default_route"].value
  zone_nic = zone_nic.split(/\//)[0]
  zone_status = check_zone_doesnt_exist(install_client)
  if !zone_status.match(/#{install_client}/)
    if $os_arch.match(/i386/)
      message = "Information:\tChecking Platform"
      command = "prtdiag -v |grep 'VMware'"
      output  = execute_command(message,command)
      if output.match(/VMware/)
        virtual = 1
      end
    end
    zone_dir = $zone_base_dir+"/"+install_client
    zone_file = "/tmp/zone_"+install_client
    file = File.open(tmp_file,"w")
    file.write("create -b\n")
    file.write("set brand=solaris\n")
    file.write("set zonepath=#{zone_dir}\n")
    file.write("set autoboot=false\n")
    if virtual == 1
      file.write("set ip-type=shared\n")
      file.write("add net\n")
      file.write("set address=#{install_ip}/24\n")
      file.write("set configure-allowed-address=true\n")
      file.write("set physical=#{zone_nic}\n")
      file.write("set defrouter=#{gateway}\n")
    else
      file.write("set ip-type=exclusive\n")
      file.write("add anet\n")
      file.write("set linkname=#{zone_nic}\n")
      file.write("set lower-link=auto\n")
      file.write("set configure-allowed-address=false\n")
      file.write("set mac-address=random\n")
    end
    file.write("end\n")
    file.close
    print_contents_of_file("",zone_file)
  end
  return zone_file
end

# Install zone

def install_zone(install_client,zone_file)
  message = "Information:\tCreating Solaris "+client_rel+" Zone "+install_client+" in "+zone_dir
  command = "zonecfg -z #{install_client} -f #{zone_file}"
  execute_command(message,command)
  message = "Information:\tInstalling Zone "+install_client
  command = "zoneadm -z #{install_client} install"
  execute_command(message,command)
  system("rm #{zone_file}")
  return
end

# Create zone

def create_zone(install_client,install_ip,zone_dir,client_rel,image_file,install_service)
  virtual = 0
  message = "Information:\tChecking Platform"
  command = "prtdiag -v |grep 'VMware'"
  output  = execute_command(message,command)
  if output.match(/VMware/)
    virtual = 1
  end
  if install_service.match(/[a-z,A-Z]/)
    image_info    = install_service.split(/_/)
    image_version = image_info[1]+"u"+image_info[2]
    image_arch    = image_info[3]
    if image_arch.match(/i386/)
      image_arch = "x86"
    end
    image_file = "solaris-"+image_version+"-"+image_arch+".bin"
  end
  if $os_rel.match(/11/) and client_rel.match(/10/)
    if $os_arch.match(/i386/)
      branded_file = branded_dir+"solaris-10u11-x86.bin"
    else
      branded_file = branded_dir+"solaris-10u11-sparc.bin"
    end
    check_fs_exists(branded_dir)
    if !File.exists(branded_file)
      print_branded_zone_info()
    end
    create_branded_zone(image_file,install_ip,zone_nic,install_client,client_rel)
  else
    if !image_file.match(/[a-z,A-Z]/)
      zone_file = create_zone_config(install_client,install_ip)
      install_zone(install_client,zone_file)
      standard_zone_post_install(install_client,client_rel)
    else
      if !File.exists?(image_file)
        print_branded_zone_info()
      end
      create_zone_config(install_client,install_ip)
      if $os_rel.match(/11/) and virtual == 1
        handle_output("Warning:\tCan't create branded zones with exclusive IPs in VMware")
        exit
      else
        create_branded_zone(image_file,install_ip,zone_nic,install_client,client_rel)
      end
    end
  end
  if $serial_mode == 1
    boot_zone(install_client)
  end
  add_hosts_entry(install_client,install_ip)
  return
end

# Halt zone

def halt_zone(install_client)
  message = "Information:\tHalting Zone "+install_client
  command = "zoneadm -z #{install_client} halt"
  execute_command(message,command)
  return
end

# Delete zone

def unconfigure_zone(install_client)
  halt_zone(install_client)
  message = "Information:\tUninstalling Zone "+install_client
  command = "zoneadm -z #{install_client} uninstall -F"
  execute_command(message,command)
  message = "Information:\tDeleting Zone "+install_client+" configuration"
  command = "zonecfg -z #{install_client} delete -F"
  execute_command(message,command)
  if $yes_to_all == 1
    zone_dir = $zone_base_dir+"/"+install_client
    destroy_zfs_fs(zone_dir)
  end
  install_ip = get_install_ip(install_client)
  remove_hosts_entry(install_client,install_ip)
  return
end

# Get zone status

def get_zone_status(install_client)
  message = "Information:\tChecking Zone "+install_client+" isn't running"
  command = "zoneadm list -cv |grep ' #{install_client} ' |awk '{print $3}'"
  output  = execute_command(message,command)
  return output
end

# Boot zone

def boot_zone(install_client)
  message = "Information:\tBooting Zone "+install_client
  command = "zoneadm -z #{install_client} boot"
  execute_command(message,command)
  if $serial_mode == 1
    system("zlogin #{install_client}")
  end
  return
end

# Shutdown zone

def stop_zone(install_client)
  status  = get_zone_status(install_client)
  if !status.match(/running/)
    message = "Information:\tStopping Zone "+install_client
    command = "zlogin #{install_client} shutdown -y -g0 -i 0"
    execute_command(message,command)
  end
  return
end



# Configure zone

def configure_zone(install_client,install_ip,client_mac,client_arch,client_os,client_rel,publisher_host,image_file,install_service)
  if client_arch.match(/[a-z,A-Z]/)
    check_same_arch(client_arch)
  end
  if !image_file.match(/[a-z,A-Z]/) and !install_service.match(/[a-z,A-Z]/)
    if !client_rel.match(/[0-9]/)
      client_rel = $os_rel
    end
  end
  if client_rel.match(/11/)
    populate_ai_client_profile_questions(install_ip,install_client)
    process_questions(install_service)
  else
    populate_js_client_profile_questions(install_ip,install_client)
    process_questions(install_service)
    if image_file.match(/[a-z,A-Z]/)
      (client_rel,client_arch,install_service) = get_zone_image_info(image_file)
      check_same_arch(client_arch)
    end
  end

  if !File.directory?($zone_base_dir)
    check_fs_exists($zone_base_dir)
    message = "Information:\tSetting mount point for "+$zone_base_dir
    command = "zfs set #{$default_zpool}#{$zone_base_dir} mountpoint=#{$zone_base_dir}"
    execute_command(message,command)
  end
  zone_dir = $zone_base_dir+"/"+install_client
  create_zone(install_client,install_ip,zone_dir,client_rel,image_file,install_service)
  return
end
