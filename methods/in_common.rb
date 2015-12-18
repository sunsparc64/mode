
# Code common to all services

# Get install type from file

def get_install_type_from_file(install_file)
  case install_file.downcase
  when /vcsa/
    install_type = "vcsa"
  else
    install_type = File.extname(install_file).downcase.split(/\./)[1]
  end
  return install_type
end

# Check password

def check_password(install_password)
  if !install_password.match(/[A-Z]/)
    puts "Warning:\tPassword does not contain and upper case character"
    exit
  end
  if !install_password.match(/[0-9]/)
    puts "Warning:\tPassword does not contain a number"
    exit
  end
  return
end

# Check ovftool is installed

def check_ovftool_exists()
  if $os_name.match(/Darwin/)
    check_osx_ovftool()
  end
  return
end

# Detach DMG

def detach_dmg(tmp_dir)
  %x[sudo hdiutil detach "#{tmp_dir}"]
  return
end

# Attach DMG

def attach_dmg(ovftool_dmg)
  tmp_dir = %x[sudo sh -c 'echo Y | hdiutil attach "#{pkg_file}" |tail -1 |cut -f3-'].chomp
  if !tmp_dir.match(/[A-z]/)
    tmp_dir = %x[ls -rt /Volumes |grep "#{app_name}" |tail -1].chomp
    tmp_dir = "/Volumes/"+tmp_dir
  end
  if $werbose_mode == 1
    puts "Information:\tDMG mounted on "+tmp_dir
  end
  return tmp_dir
end

# Check OSX ovftool

def check_osx_ovftool()
  ovftool_bin = "/Applications/VMware OVF Tool/ovftool"
  if !File.exist?(ovftool_bin)
    puts "Warning:\tOVF Tool not installed"
    message = "Fetching "+$ovftool_dmg_url+" to "+ovftool_dmg
    command = "wget #{$ovftool_dmg_url} -O #{ovftool_dmg}"
    execute_command(message,command)
    puts "Information:\tInstalling OVF Tool"
    ovftool_dmg = $ovftool_dmg_url.split(/\?/)[0]
    ovftool_dmg = File.basename(ovftool_dmg)
    tmp_dir  = attach_dmg(ovftool_dmg)
    pkg_file = tmp_dir+"/VMware OVF Tool.pkg"
    message = "Information:\tInstalling package "+pkg_file
    command = "/usr/sbin/installer -pkg #{pkg_bin} -target /"
    execute_command(message,command)
    detach_dmg(tmp_dir)
  end
  return
end

# SCP file to remote host

def scp_file(install_server,install_serveradmin,install_serverpassword,local_file,remote_file)
  if $verbose_mode == 1
    puts "Information:\tCopying file \""+local_file+"\" to \""+install_server+":"+remote_file+"\""
  end
  Net::SCP.start(install_server,install_serveradmin,:password => install_serverpassword, :paranoid => false) do |scp|
    scp.upload! local_file, remote_file
  end
  return
end

# Execute SSH command

def execute_ssh_command(install_server,install_serveradmin,install_serverpassword,command)
  if $verbose_mode == 1
    puts "Information:\tExecuting command \""+command+"\" on server "+install_server
  end
  Net::SSH.start(install_server,install_serveradmin,:password => install_serverpassword, :paranoid => false) do |ssh|
    ssh.exec!(command)
  end
  return
end

# Get client config

def get_client_config(install_client,install_service,install_method,install_config)
  if !install_service.match(/[a-z]/)
    install_service = get_install_service(install_client)
  end
  if !install_method.match(/[a-z]/)
    install_method  = get_install_method(install_client,install_service)
  end
  client_dir      = get_client_dir(install_client)
  config_file     = ""
  config_prefix   = client_dir+"/"+install_client
  case install_config
  when /config|cfg|ks|Kickstart/
    config_file = config_prefix+".cfg"
  when /post/
    case method
    when /ps/
      config_file = config_prefix+"_post.sh"
    end
  when /first/
    case method
    when /ps/
      config_file = config_prefix+"_first_boot.sh"
    end
  end
  if File.exist?(config_file)
    file_data = %x[cat #{config_file}]
    puts file_data
  end
  return
end

# Get client install service for a client

def get_install_service(install_client)
  client_dir      = get_client_dir(install_client)
  install_service = client_dir.split(/\//)[-2]
  return install_service
end

# Get install method from service

def get_install_method(install_client,install_service)
  if !install_service.match(/[a-z]/)
    get_install_service(install_client)
  end
  service_dir = $repo_base_dir+"/"+install_service
  if File.directory?(service_dir) or File.symlink?(service_dir)
    if $verbose_mode == 1
      puts "Information:\tFound directory "+service_dir
      puts "Information:\tDetermining service type"
    end
  else
    puts "Warning:\tService "+install_service+" does not exist"
  end
  install_method = ""
  test_file = service_dir+"/vmware-esx-base-osl.txt"
  if File.exist?(test_file)
    install_method = "vs"
  else
    test_file = service_dir+"/repodata"
    if File.exist?(test_file)
      install_method = "ks"
    else
      test_dir = service_dir+"/preseed"
      if File.directory?(test_dir)
        install_method = "ps"
      end
    end
  end
  return install_method
end

# Unconfigure a server

def unconfigure_server(install_service)
  install_method = get_install_method(install_service)
  if install_method.match(/[a-z]/)
    eval"[unconfigure_#{install_method}_server(install_service)]"
  else
    puts "Warning:\tCould not determine service type for "+install_service
  end
  return
end

# list OS install ISOs

def list_os_isos(install_os)
  case install_os
  when /linux/
    search_string = "CentOS|OracleLinux|SUSE|SLES|SL|Fedora|ubuntu|debian"
  when /sol/
    search_string = "sol"
  when /esx|vmware|vsphere/
    search_string = "VMvisor"
  else
    list_all_isos()
    return
  end
  eval"[list_#{install_os}_isos(search_string)]"
  return
end

# List all isos

def list_all_isos()
  $valid_method_list.each do |install_method|
    eval"[list_#{install_method}_isos()]"
  end
  return
end

# Get install method from service name

def get_install_method_from_service(install_service)
  case install_service
  when /vmware/
    install_method = "vs"
  when /centos|oel|rhel|fedora|sl/
    install_method = "ks"
  when /ubuntu|debian/
    install_method = "ps"
  when /suse|sles/
    install_method = "ay"
  when /sol_6|sol_7|sol_8|sol_9|sol_10/
    install_method = "js"
  when /sol_11/
    install_method = "ai"
  end
  return install_method
end

# Get install service from ISO file name

def get_install_service_from_file(install_file)
  install_service = ""
  service_name    = ""
  service_version = ""
  case install_file
  when /vCenter-Server-Appliance|VCSA/
    service_name    = "vcsa"
    service_version = install_file.split(/-/)[3..4].join(".").gsub(/\./,"_").gsub(/_iso/,"")
  when /VMvisor-Installer/
    service_name    = "vsphere"
    service_version = install_file.split(/-/)[4..5].join(".").gsub(/\./,"_").gsub(/_iso/,"")
  when /CentOS/
    service_name    = "centos"
    service_version = install_file.split(/-/)[1..2].join(".").gsub(/\./,"_").gsub(/_iso/,"")
  when /Fedora-Server/
    service_name    = "fedora"
    service_version = install_file.split(/-/)[-1].gsub(/\./,"_").gsub(/_iso/,"_")
    service_arch    = install_file.split(/-/)[-2].gsub(/\./,"_").gsub(/_iso/,"_")
    service_version = service_version+"_"+service_arch
  when /OracleLinux/
    service_name    = "oel"
    service_version = install_file.split(/-/)[1..2].join(".").gsub(/\./,"_").gsub(/R|U/,"")
    service_arch    = install_file.split(/-/)[-2]
    service_version = service_version+"_"+service_arch
  when /openSUSE/
    service_name    = "opensuse"
    service_version = install_file.split(/-/)[1].gsub(/\./,"_").gsub(/_iso/,"")
    service_arch    = install_file.split(/-/)[-1].gsub(/\./,"_").gsub(/_iso/,"")
    service_version = service_version+"_"+service_arch
  when /rhel/
    service_name    = "rhel"
    service_version = install_file.split(/-/)[2..3].join(".").gsub(/\./,"_").gsub(/_iso/,"")
  end
  install_service = service_name+"_"+service_version.gsub(/__/,"_")
  return install_service
end

# Get Install method from ISO file name

def get_install_method_from_iso(install_file)
  if install_file.match(/\//)
    install_file = File.basename(install_file)
  end
  case install_file
  when /VMware-VMvisor/
    install_method = "vs"
  when /CentOS|OracleLinux|^SL|Fedora|rhel/
    install_method = "ks"
  when /ubuntu|debian/
    install_method = "ps"
  when /SUSE|SLES/
    install_method = "ay"
  when /sol-6|sol-7|sol-8|sol-9|sol-10/
    install_method = "js"
  when /sol-11/
    install_method = "ai"
  end
  return install_method
end

# Configure a service

def configure_server(install_method,install_arch,publisher_host,publisher_port,install_service,install_file)
  if !install_method.match(/[A-z]/)
    if !install_file.match(/[A-z]/)
      puts "Warning:\tCould not determine service name"
      exit
    else
      install_method = get_install_method_from_iso(install_file)
    end
  end    
  eval"[configure_#{install_method}_server(install_arch,publisher_host,publisher_port,install_service,install_file)]"
  return
end

# Generate MAC address

def generate_mac_address()
  install_mac = (1..6).map{"%0.2X"%rand(256)}.join(":")
  return install_mac
end

# List all services

def list_all_services()
  $valid_method_list.each do |install_method|
    eval"[list_#{install_method}_services()]"
  end
  puts
  return
end

# Check IP validity

def check_ip(install_ip)
  invalid_ip = 0
  ip_fields  = install_ip.split(/\./)
  if !ip_fields.length == 4
    invalid_ip = 1
  end
  ip_fields.each do |ip_field|
    if ip_field.match(/[A-z]/) or ip_field.to_i > 255
      invalid_ip = 1
    end
  end
  if invalid_ip == 1
    puts "Warning:\tInvalid IP Address"
    exit
  end
  return
end

# Check hostname validity

def check_hostname(install_client)
  install_client = install_client.split()
  install_client.each do |char|
    if !char.match(/[A-z]||[0-9]|-/)
      puts "Invalid hostname: "+client_name.join()
      exit
    end
  end
end

# Get ISO list

def get_iso_list(install_os,install_method,install_release,install_arch)
  search_string = ""
  iso_list = check_iso_base_dir(search_string)
  case install_os.downcase
  when /oel|oraclelinux/
    install_os = "OracleLinux"
  when /sles/
    install_os = "SLES"
  when /centos/
    install_os = "CentOS"
  when /suse/
    install_os = "openSUSE"
  when /ubuntu/
    install_os = "ubuntu"
  when /debian/
    install_os = "debian"
  when /fedora/
    install_os = "Fedora"
  when /scientific|sl/
    install_os = "SL"
  when /redhat|rhel/
    install_os = "rhel"
  when /sol/
    install_os = "sol"
  when /^linux/
    install_os = "CentOS|OracleLinux|SLES|openSUSE|ubuntu|debian|Fedora|rhel|SL"
  when /vmware|vsphere|esx/
    install_os = "VMware-VMvisor"
  end
  case install_method
  when /kick|ks/
    install_method = "CentOS|OracleLinux|Fedora|rhel|SL|VMware"
  when /jump|js/
    install_method = "sol-10"
  when /ai/
    install_method = "sol-11"
  when /yast|ay/
    install_method = "SLES|openSUSE"
  when /preseed|ps/
    install_method = "debian|ubuntu"
  end
  if install_release.match(/[0-9]/)
    case install_os
    when "OracleLinux"
      if install_release.match(/\./) 
        (major,minor)   = install_release.split(/\./)
        install_release = "-R"+major+"-U"+minor
      else
        install_release = "-R"+install_release
      end
    when /sol/
      if install_release.match(/\./)
        (major,minor)   = install_release.split(/\./)
        if install_release.match(/^10/)
          install_release = major+"-u"+minor
        else
          install_release = major+"_"+minor
        end
      end
      install_release = "-"+install_release
    else
      install_release = "-"+install_release
    end
  end
  if install_arch.match(/[A-z]/)
    if install_os.match(/sol/)
      install_arch = install_arch.gsub(/i386|x86_64/,"x86")
    end
    if install_os.match(/ubuntu/)
      install_arch = install_arch.gsub(/x86_64/,"amd64")
    else
      install_arch = install_arch.gsub(/amd64/,"x86_64")
    end
  end
  [ install_os, install_method, install_release, install_arch ].each do |search_string|
    if search_string.match(/[A-z]|[0-9]/)
      iso_list = iso_list.grep(/#{search_string}/)
    end
  end
  return iso_list
end

# List ISOs

def list_isos(install_os,install_method,install_release,install_arch)
  puts
  iso_list = get_iso_list(install_os,install_method,install_release,install_arch)
  iso_list.each do |iso_file|
    puts iso_file
  end
  puts
  return
end

# Connect to virtual serial port

def connect_to_virtual_serial(install_client,install_vm)
  puts
  puts "Connecting to serial port of "+install_client
  puts
  puts "To disconnect from this session use CTRL-Q"
  puts
  puts "If you wish to re-connect to the serial console of this machine,"
  puts "run the following command:"
  puts
  puts $script+" --action=console --vm="+install_vm+" --client="+install_client
  puts
  puts "or:"
  puts
  puts "socat UNIX-CONNECT:/tmp/"+install_client+" STDIO,raw,echo=0,escape=0x11,icanon=0"
  puts
  puts
  system("socat UNIX-CONNECT:/tmp/#{install_client} STDIO,raw,echo=0,escape=0x11,icanon=0")
  return
end

# Set some VMware ESXi VM defaults

def configure_vmware_esxi_defaults()
  $default_vm_mem      = "4096"
  $default_vm_vcpu     = "2"
  $client_os           = "ESXi"
  $vbox_disk_type      = "ide"
  return
end

# Set some VMware vCenter defaults

def configure_vmware_vcenter_defaults()
  $default_vm_mem      = "4096"
  $default_vm_vcpu     = "2"
  $client_os           = "ESXi"
  $vbox_disk_type      = "ide"
  return
end

# Get client directory

def get_client_dir(install_client)
  message    = "Information:\tFinding client configuration directory for #{install_client}"
  command    = "find #{$client_base_dir} -name #{install_client} |grep '#{install_client}$'"
  client_dir = execute_command(message,command).chomp
  if $verbose_mode == 1
    if File.directory?(client_dir)
      puts "Information:\tNo client directory found for "+install_client
    else
      puts "Information:\tClient directory found "+client_dir
    end
  end
  return client_dir
end

# Delete client directory

def delete_client_dir(install_client)
  client_dir = get_client_dir(install_client)
  if File.directory?(client_dir)
    if client_dir.match(/[a-z]/)
      if $os_name.match(/SunOS/)
        destroy_zfs_fs(client_dir)
      else
        message = "Information:\tRemoving client configuration files for #{install_client}"
        command = "rm #{client_dir}/*"
        execute_command(message,command)
        message = "Information:\tRemoving client configuration directory #{client_dir}"
        command = "rmdir #{client_dir}"
        execute_command(message,command)
      end
    end
  end
  return
end

# List ks clients

def list_clients(service_type)
  puts
  puts "Available "+service_type+" Clients:"
  puts
  if service_type.match(/Kickstart/)
    search_string = "centos|redhat|rhel|scientific|fedora"
  end
  if service_type.match(/Preseed/)
    search_string = "debian|ubuntu"
  end
  if service_type.match(/ESX/)
    search_string = "vmware"
  end
  if service_type.match(/AutoYast/)
    search_string = "suse|sles"
  end
  service_list = Dir.entries($repo_base_dir)
  service_list.each do |service_name|
    if service_name.match(search_string)
      repo_version_dir = $client_base_dir+"/"+service_name
      client_list      = Dir.entries(repo_version_dir)
      client_list.each do |client_dir|
        if client_dir.match(/[A-z]|[0-9]/)
          client_name = File.basename(client_dir)
          puts client_name+" [ service = "+service_name+" ] "
        end
      end
    end
  end
  puts
  return
end

# List appliances

def list_ovas()
  file_list = Dir.entries($iso_base_dir)
  puts
  puts "Virtual Appliances:"
  puts
  file_list.each do |file_name|
    if file_name.match(/ova$/)
      puts file_name
    end
  end
  puts
end

# Check directory ownership

def check_dir_owner(dir_name,uid)
  test_uid = File.stat(dir_name).uid
  if test_uid != uid.to_i
    message = "Information:\tChanging ownership of "+dir_name+" to "+uid.to_s
    command = "sudo sh -c 'chown -R #{uid.to_s} #{dir_name}'"
    execute_command(message,command)
  end
  return
end

# Print contents of file

def print_contents_of_file(file_name)
  if $verbose_mode == 1
    if File.exist?(file_name)
      puts
      puts "Information:\tContents of file "+file_name
      puts
      system("cat '#{file_name}'")
      puts
    else
      puts "Warning:\tFile "+file_name+" does not exist"
    end
  end
  return
end

# Add NFS export

def add_nfs_export(export_name,export_dir,publisher_host)
  network_address  = publisher_host.split(/\./)[0..2].join(".")+".0"
  if $os_name.match(/SunOS/)
    if $os_rel.match(/11/)
      message  = "Enabling:\tNFS share on "+export_dir
      command  = "zfs set sharenfs=on #{$default_zpool}#{export_dir}"
      output   = execute_command(message,command)
      message  = "Setting:\tNFS access rights on "+export_dir
      command  = "zfs set share=name=#{export_name},path=#{export_dir},prot=nfs,anon=0,sec=sys,ro=@#{network_address}/24 #{$default_zpool}#{export_dir}"
      output   = execute_command(message,command)
    else
      dfs_file = "/etc/dfs/dfstab"
      message  = "Checking:\tCurrent NFS exports for "+export_dir
      command  = "cat #{dfs_file} |grep '#{export_dir}' |grep -v '^#'"
      output   = execute_command(message,command)
      if !output.match(/#{export_dir}/)
        backup_file(dfs_file)
        export  = "share -F nfs -o ro=@#{network_address},anon=0 #{export_dir}"
        message = "Adding:\tNFS export for "+export_dir
        command = "echo '#{export}' >> #{dfs_file}"
        execute_command(message,command)
        message = "Refreshing:\tNFS exports"
        command = "shareall -F nfs"
        execute_command(message,command)
      end
    end
  else
    dfs_file = "/etc/exports"
    message  = "Checking:\tCurrent NFS exports for "+export_dir
    command  = "cat #{dfs_file} |grep '#{export_dir}' |grep -v '^#'"
    output   = execute_command(message,command)
    if !output.match(/#{export_dir}/)
      if $os_name.match(/Darwin/)
        export = "#{export_dir} -alldirs -maproot=root -network #{network_address} -mask #{$default_netmask}"
      else
        export = "#{export_dir} #{network_address}/24(ro,no_root_squash,async,no_subtree_check)"
      end
      message = "Adding:\tNFS export for "+export_dir
      command = "echo '#{export}' >> #{dfs_file}"
      execute_command(message,command)
      message = "Refreshing:\tNFS exports"
      if $os_name.match(/Darwin/)
        command = "nfsd stop ; nfsd start"
      else
        command = "/sbin/exportfs -a"
      end
      execute_command(message,command)
    end
  end
  return
end

# Remove NFS export

def remove_nfs_export(export_dir)
  if $os_name.match(/SunOS/)
    message = "Disabling:\tNFS share on "+export_dir
    command = "zfs set sharenfs=off #{$default_zpool}#{export_dir}"
    execute_command(message,command)
  else
    dfs_file = "/etc/exports"
    message  = "Checking:\tCurrent NFS exports for "+export_dir
    command  = "cat #{dfs_file} |grep '#{export_dir}' |grep -v '^#'"
    output   = execute_command(message,command)
    if output.match(/#{export_dir}/)
      backup_file(dfs_file)
      tmp_file = "/tmp/dfs_file"
      message  = "Removing:\tExport "+export_dir
      command  = "cat #{dfs_file} |grep -v '#{export_dir}' > #{tmp_file} ; cat #{tmp_file} > #{dfs_file} ; rm #{tmp_file}"
      execute_command(message,command)
      if $os_name.match(/Darwin/)
        message  = "Restarting:\tNFS daemons"
        command  = "nfsd stop ; nfsd start"
        execute_command(message,command)
      else
        message  = "Restarting:\tNFS daemons"
        command  = "service nfsd restart"
        execute_command(message,command)
      end
    end
  end
  return
end

# Check we are running on the right architecture

def check_same_arch(client_arch)
  if !$os_arch.match(/#{client_arch}/)
    puts "Warning:\tSystem and Zone Architecture do not match"
    exit
  end
  return
end

# Delete file

def delete_file(file_name)
  if File.exist?(file_name)
    message = "Removing:\tFile "+file_name
    command = "rm #{file_name}"
    execute_command(message,command)
  end
end

# Get root password crypt

def get_root_password_crypt()
  password = $q_struct["root_password"].value
  result   = get_password_crypt(password)
  return result
end

# Get account password crypt

def get_admin_password_crypt()
  password = $q_struct["admin_password"].value
  result   = get_password_crypt(password)
  return result
end

# Check SSH keys

def check_ssh_keys()
  ssh_key = $home_dir+"/.ssh/id_rsa.pub"
  if !File.exist?(ssh_key)
    if $verbose_mode == 1
      puts "Generating:\tPublic SSH key file "+ssh_key
    end
    system("ssh-keygen -t rsa")
  end
  return
end

# Check IPS tools installed on OS other than Solaris

def check_ips()
  if $os_name.match(/Darwin/)
    check_osx_ips()
  end
  return
end

# Check Apache enabled

def check_apache_config()
  if $os_name.match(/Darwin/)
    service = "apache"
    check_osx_service_is_enabled(service)
  end
  return
end

# Process ISO file to get details

def get_linux_version_info(iso_file_name)
  iso_info     = File.basename(iso_file_name)
  iso_info     = iso_info.split(/-/)
  linux_distro = iso_info[0]
  linux_distro = linux_distro.downcase
  if linux_distro.match(/oraclelinux/)
    linux_distro = "oel"
  end
  if linux_distro.match(/centos|ubuntu|sles|sl|oel|rhel/)
    if linux_distro.match(/sles/)
      if iso_info[2] == "Server"
        iso_version = iso_info[1]+".0"
      else
        iso_version = iso_info[1]+"."+iso_info[2]
        iso_version = iso_version.gsub(/SP/,"")
      end
    else
      if linux_distro.match(/sl$/)
        iso_version = iso_info[1].split(//).join(".")
        if iso_version.length == 1
          iso_version = iso_version+".0"
        end
      else
        if linux_distro.match(/oel|rhel/)
          if iso_file_name =~ /-rc-/
            iso_version = iso_info[1..3].join(".")
            iso_version = iso_version.gsub(/server/,"")
          else
            iso_version = iso_info[1..2].join(".")
            iso_version = iso_version.gsub(/[A-z]/,"")
          end
          iso_version = iso_version.gsub(/^\./,"")
        else
          iso_version = iso_info[1]
        end
      end
    end
    case iso_file_name
    when /i[3-6]86/
      iso_arch = "i386"
    when /x86_64/
      iso_arch = "x86_64"
    else
      if linux_distro.match(/centos|sl$/)
        iso_arch = iso_info[2]
      else
        if linux_distro.match(/sles|oel/)
          iso_arch = iso_info[4]
        else
          iso_arch = iso_info[3]
          iso_arch = iso_arch.split(/\./)[0]
          if iso_arch.match(/amd64/)
            iso_arch = "x86_64"
          else
            iso_arch = "i386"
          end
        end
      end
    end
  else
    if linux_distro.match(/fedora/)
      iso_version = iso_info[1]
      iso_arch    = iso_info[2]
    else
      iso_version = iso_info[2]
      iso_arch    = iso_info[3]
    end
  end
  return linux_distro,iso_version,iso_arch
end

# Check DHCPd config

def check_dhcpd_config(publisher_host)
  get_default_host()
  network_address   = $default_host.split(/\./)[0..2].join(".")+".0"
  broadcast_address = $default_host.split(/\./)[0..2].join(".")+".255"
  gateway_address   = $default_host.split(/\./)[0..2].join(".")+".254"
  output = ""
  if File.exist?($dhcpd_file)
    message = "Checking:\tDHCPd config for subnet entry"
    command = "cat #{$dhcpd_file} | grep 'subnet #{network_address}'"
    output  = execute_command(message, command)
  end
  if !output.match(/subnet/) and !output.match(/#{network_address}/)
    tmp_file    = "/tmp/dhcpd"
    backup_file = $dhcpd_file+".premode"
    file = File.open(tmp_file,"w")
    file.write("\n")
    if $os_name.match(/SunOS|Linux/)
      file.write("default-lease-time 900;\n")
      file.write("max-lease-time 86400;\n")
    end
    if $os_name.match(/Linux/)
      file.write("option space pxelinux;\n")
      file.write("option pxelinux.magic code 208 = string;\n")
      file.write("option pxelinux.configfile code 209 = text;\n")
      file.write("option pxelinux.pathprefix code 210 = text;\n")
      file.write("option pxelinux.reboottime code 211 = unsigned integer 32;\n")
      file.write("option architecture-type code 93 = unsigned integer 16;\n")
    end
    file.write("\n")
    if $os_name.match(/SunOS/)
      file.write("authoritative;\n")
      file.write("\n")
      file.write("option arch code 93 = unsigned integer 16;\n")
      file.write("option grubmenu code 150 = text;\n")
      file.write("\n")
      file.write("log-facility local7;\n")
      file.write("\n")
      file.write("class \"PXEBoot\" {\n")
      file.write("  match if (substring(option vendor-class-identifier, 0, 9) = \"PXEClient\");\n")
      file.write("  if option arch = 00:00 {\n")
      file.write("    filename \"default-i386/boot/grub/pxegrub2\";\n")
      file.write("  } else if option arch = 00:07 {\n")
      file.write("    filename \"default-i386/boot/grub/grub2netx64.efi\";\n")
      file.write("  }\n")
      file.write("}\n")
      file.write("\n")
      file.write("class \"SPARC\" {\n")
      file.write("  match if not (substring(option vendor-class-identifier, 0, 9) = \"PXEClient\");\n")
      file.write("  filename \"http://#{publisher_host}:5555/cgi-bin/wanboot-cgi\";\n")
      file.write("}\n")
      file.write("\n")
      file.write("allow booting;\n")
      file.write("allow bootp;\n")
    end
    if $os_name.match(/Linux/)
      file.write("class \"pxeclients\" {\n")
      file.write("  match if substring (option vendor-class-identifier, 0, 9) = \"PXEClient\";\n")
      file.write("  if option architecture-type = 00:07 {\n")
      file.write("    filename \"uefi/shim.efi\";\n")
      file.write("  } else {\n")
      file.write("    filename \"pxelinux/pxelinux.0\";\n")
      file.write("  }\n")
      file.write("}\n")
    end
    file.write("\n")
    if $os_name.match(/SunOS|Linux/)
      file.write("subnet #{network_address} netmask #{$default_netmask} {\n")
      file.write("  option broadcast-address #{broadcast_address};\n")
      file.write("  option routers #{gateway_address};\n")
      file.write("  next-server #{$default_host};\n")
      file.write("}\n")
    end
    file.write("\n")
    file.close
    if File.exist?($dhcpd_file)
      message = "Archiving DHCPd configuration file "+$dhcpd_file+" to "+backup_file
      command = "cp #{$dhcpd_file} #{backup_file}"
      execute_command(message,command)
    end
    message = "Creating DHCPd configuration file "+$dhcpd_file
    command = "cp #{tmp_file} #{$dhcpd_file}"
    execute_command(message,command)
    if $os_name == "SunOS" and $os_rel == "5.11"
      message = "Setting\tDHCPd listening interface to "+$default_net
      command = "svccfg -s svc:/network/dhcp/server:ipv4 setprop config/listen_ifnames = astring: #{$default_net}"
      execute_command(message,command)
      message = "Refreshing\tDHCPd service"
      command = "svcadm refresh svc:/network/dhcp/server:ipv4"
      execute_command(message,command)
    end
    restart_dhcpd()
  end
  return
end

# Check package is installed

def check_rhel_package(package)
  message = "Checking:\t"+package+" is installed"
  command = "rpm -q #{package}"
  output  = execute_command(message,command)
  if !output.match(/#{package}/)
    message = "installing:\t"+package
    command = "yum -y install #{package}"
    execute_command(message,command)
  end
  return
end

# Check firewall is enabled

def check_rhel_service(service)
  message = "Checking:\t"+service+" is installed"
  command = "service #{service} status |grep dead"
  output  = execute_command(message,command)
  if output.match(/dead/)
    message = "Enabling:\t"+service
    if $os_rel.match(/^7/)
      command = "systemctl enable #{service}.service"
      command = "systemctl start #{service}.service"
    else
      command = "chkconfig --level 345 #{service} on"
    end
    execute_command(message,command)
  end
  return
end  

# Check service is enabled

def check_rhel_firewall(service,port_info)
  if $os_rel.match(/^7/)
    message = "Information:\tChecking firewall configuration for "+service
    command = "firewall-cmd --list-services |grep #{service}"
    output  = execute_command(message,command)
    if !output.match(/#{service}/)
      message = "Information:\tAdding firewall rule for "+service
      command = "firewall-cmd --add-service=#{service} --permanent"
      execute_command(message,command)
    end
    if port_info.match(/[0-9]/)
      message = "Information:\tChecking firewall configuration for "+port_info
      command = "firewall-cmd --list-all |grep #{port_info}"
      output  = execute_command(message,command)
      if !output.match(/#{port_info}/)
        message = "Information:\tAdding firewall rule for "+port_info
        command = "firewall-cmd --zone=public --add-port=#{port_info} --permanent"
        execute_command(message,command)
      end
    end
  else
    if port_info.match(/[0-9]/)
      (port_no,protocol) = port_info.split(/\//)
      message = "Information:\tChecking firewall configuration for "+service+" on "+port_info
      command = "iptables --list-rules |grep #{protocol} |grep #{port_no}"
      output  = execute_command(message,command)
      if !output.match(/#{protocol}/)
        message = "Information:\tAdding firewall rule for "+service
        command = "iptables -I INPUT -p #{protocol} --dport #{port_no} -j ACCEPT ; service iptables save"
        execute_command(message,command)
      end
    end
  end
  return
end

# Check httpd enabled on Centos / Redhat

def check_yum_xinetd()
  check_rhel_package("xinetd")
  check_rhel_firewall("xinetd","")
  check_rhel_service("xinetd")
  return
end

# Check TFTPd enabled on CentOS / RedHat

def check_yum_tftpd()
  check_dir_exists($tftp_dir)
  check_rhel_package("tftp-server")
  check_rhel_firewall("tftp","")
  check_rhel_service("tftp")
  return
end

# Check DHCPd enabled on CentOS / RedHat

def check_yum_dhcpd()
  check_rhel_package("dhcp")
  check_rhel_firewall("dhcp","69/udp")
  check_rhel_service("dhcpd")
  return
end

# Check httpd enabled on Centos / Redhat

def check_yum_httpd()
  check_rhel_package("httpd")
  check_rhel_firewall("http","80/tcp")
  check_rhel_service("httpd")
  return
end

# Check TFTPd enabled on Debian / Ubuntu

def check_apt_tftpd()
  message    = "Checking:\tTFTPd is installed"
  command    = "dpkg -l tftpd |grep '^ii'"
  output     = execute_command(message,command)
  if !output.match(/tftp/)
    message = "installing:\tTFTPd"
    command = "apt-get -y install tftpd"
    execute_command(message,command)
  end
  return
end

# Check DHCPd enabled on Debian / Ubuntu

def check_apt_dhcpd()
  message = "Checking:\tDHCPd is installed"
  command = "dpkg -l isc-dhcp-server |grep '^ii'"
  output  = execute_command(message,command)
  if !output.match(/dhcp/)
    message = "installing:\tDHCPd"
    command = "yum -y install isc-dhcp-server"
    execute_command(message,command)
    message = "Enabling:\tDHCPd"
    command = "chkconfig dhcpd on"
    execute_command(message,command)
  end
  return
end

# Restart a service

def restart_service(service)
  refresh_service(service)
  return
end

# Restart xinetd

def restart_xinetd()
  service = "xinetd"
  service = get_service_name(service)
  refresh_service(service)
  return
end

# Restart tftpd

def restart_tftpd()
  service = "tftp"
  service = get_service_name(service)
  refresh_service(service)
  return
end

# Check tftpd config for Linux(turn on in xinetd config file /etc/xinetd.d/tftp)

def check_tftpd_config()
  if $os_name.match(/Linux/)
    tftpd_file = "/etc/xinetd.d/tftp"
    tmp_file   = "/tmp/tftp"
    if $os_info.match(/Ubuntu|Debian/)
      check_apt_tftpd
    else
      check_yum_tftpd
    end
    check_dir_exists($tftp_dir)
    if File.exist?(tftpd_file)
      disable_test =%x[cat #{tftpd_file} |grep disable |awk -F= '{print $2}']
    else
      disable_test = "yes"
    end
    if disable_test.match(/yes/)
      if File.exist?(tftpd_file)
        message = "Information:\tBacking up "+tftpd_file+" to "+tftpd_file+".premode"
        command = "cp #{tftpd_file} #{tftpd_file}.premode"
        execute_command(message,command)
      end
      file=File.open(tmp_file,"w")
      file.write("service tftp\n")
      file.write("{\n")
      file.write("\tprotocol        = udp\n")
      file.write("\tport            = 69\n")
      file.write("\tsocket_type     = dgram\n")
      file.write("\twait            = yes\n")
      file.write("\tuser            = root\n")
      if $os_name.match(/Ubuntu|Debian/)
        file.write("\tserver          = /usr/sbin/in.tftpd\n")
        file.write("\tserver_args     = /tftpboot\n")
      else
        file.write("\tserver          = /usr/sbin/in.tftpd\n")
        file.write("\tserver_args     = /var/lib/tftpboot -s\n")
      end
      file.write("\tdisable         = no\n")
      file.write("}\n")
      file.close
      message = "Creating:\tTFTPd configuration file "+tftpd_file
      command = "cp #{tmp_file} #{tftpd_file} ; rm #{tmp_file}"
      execute_command(message,command)
      restart_xinetd()
      restart_tftpd()
    end
  end
  return
end

# Check tftpd directory

def check_tftpd_dir()
  if $os_name.match(/SunOS/)
    old_tftp_dir = "/tftpboot"
    if !File.symlink?(old_tftp_dir)
      File.symlink($tftp_dir,old_tftp_dir)
    end
    message = "Checking:\tTFTPd service boot directory configuration"
    command = "svcprop -p inetd_start/exec svc:network/tftp/udp6"
    output  = execute_command(message,command)
    if !output.match(/netboot/)
      message = "Setting:\tTFTPd boot directory to "+$tftp_dir
      command = "svccfg -s svc:network/tftp/udp6 setprop inetd_start/exec = astring: '(\"/usr/sbin/in.tftpd\\ -s\\ /etc/netboot\")'"
      execute_command(message,command)
    end
  end
  return
end

# Check tftpd

def check_tftpd()
  check_tftpd_dir()
  if $os_name.match(/SunOS/)
    enable_service("svc:/network/tftp/udp6:default")
  end
  if $os_name.match(/Darwin/)
    check_osx_tftpd()
  end
  return
end

# Get client IP

def get_client_ip(client_name)
  hosts_file = "/etc/hosts"
  message    = "Getting:\tClient IP for "+client_name
  command    = "cat #{hosts_file} |grep '#{client_name}$' |awk '{print $1}'"
  output     = execute_command(message,command)
  client_ip  = output.chomp
  return client_ip
end

# Add hosts entry

def add_hosts_entry(client_name,client_ip)
  hosts_file = "/etc/hosts"
  message    = "Checking:\tHosts file for "+client_name
  command    = "cat #{hosts_file} |grep -v '^#' |grep '#{client_name}' |grep '#{client_ip}'"
  output     = execute_command(message,command)
  if !output.match(/#{client_name}/)
    backup_file(hosts_file)
    message = "Adding:\t\tHost "+client_name+" to "+hosts_file
    command = "echo \"#{client_ip}\\t#{client_name}.local\\t#{client_name}\\t# #{$default_admin_user}\" >> #{hosts_file}"
    output  = execute_command(message,command)
    if $os_name.match(/Darwin/)
      pfile   = "/Library/LaunchDaemons/homebrew.mxcl.dnsmasq.plist"
      if File.exist?(pfile)
        service = "dnsmasq"
        service = get_service_name(service)
        refresh_service(service)
      end
    end
  end
  return
end

# Remove hosts entry

def remove_hosts_entry(client_name,client_ip)
  tmp_file   = "/tmp/hosts"
  hosts_file = "/etc/hosts"
  message    = "Checking:\tHosts file for "+client_name
  if client_ip.match(/[0-9]/)
    command = "cat #{hosts_file} |grep -v '^#' |grep '#{client_name}' |grep '#{client_ip}'"
  else
    command = "cat #{hosts_file} |grep -v '^#' |grep '#{client_name}'"
  end
  output = execute_command(message,command)
  copy   = []
  if output.match(/#{client_name}/)
    file_info=IO.readlines(hosts_file)
    file_info.each do |line|
      if !line.match(/#{client_name}/)
        if client_ip.match(/[0-9]/)
          if !line.match(/^#{client_ip}/)
            copy.push(line)
          end
        else
          copy.push(line)
        end
      end
    end
    File.open(tmp_file,"w") {|file| file.puts copy}
    message = "Updating:\tHosts file "+hosts_file
    if $os_name.match(/Darwin/)
      command = "sudo sh -c 'cp #{tmp_file} #{hosts_file} ; rm #{tmp_file}'"
    else
      command = "cp #{tmp_file} #{hosts_file} ; rm #{tmp_file}"
    end
    execute_command(message,command)
  end
  return
end

# Add host to DHCP config

def add_dhcp_client(client_name,install_mac,client_ip,client_arch,service_name)
  if !install_mac.match(/:/)
    install_mac = install_mac[0..1]+":"+install_mac[2..3]+":"+install_mac[4..5]+":"+install_mac[6..7]+":"+install_mac[8..9]+":"+install_mac[10..11]
  end
  tmp_file = "/tmp/dhcp_"+client_name
  if !client_arch.match(/sparc/)
    tftp_pxe_file = install_mac.gsub(/:/,"")
    tftp_pxe_file = tftp_pxe_file.upcase
    if service_name.match(/sol/)
      suffix = ".bios"
    else
      if service_name.match(/bsd/)
        suffix = ".pxeboot"
      else
        suffix = ".pxelinux"
      end
    end
    tftp_pxe_file = "01"+tftp_pxe_file+suffix
  else
    tftp_pxe_file = "http://#{$default_host}:5555/cgi-bin/wanboot-cgi"
  end
  message = "Checking:\fIf DHCPd configuration contains "+client_name
  command = "cat #{$dhcpd_file} | grep '#{client_name}'"
  output  = execute_command(message,command)
  if !output.match(/#{client_name}/)
    backup_file($dhcpd_file)
    file = File.open(tmp_file,"w")
    file_info=IO.readlines($dhcpd_file)
    file_info.each do |line|
      file.write(line)
    end
    file.write("\n")
    file.write("host #{client_name} {\n")
    file.write("  fixed-address #{client_ip};\n")
    file.write("  hardware ethernet #{install_mac};\n")
    if service_name.match(/[A-z]/)
      file.write("  filename \"#{tftp_pxe_file}\";\n")
    end
    file.write("}\n")
    file.close
    message = "Updating:\tDHCPd file "+$dhcpd_file
    command = "cp #{tmp_file} #{$dhcpd_file} ; rm #{tmp_file}"
    execute_command(message,command)
    restart_dhcpd()
  end
  check_dhcpd()
  check_tftpd()
  return
end

# Remove host from DHCP config

def remove_dhcp_client(client_name)
  found     = 0
  copy      = []
  file_info = IO.readlines($dhcpd_file)
  file_info.each do |line|
    if line.match(/^host #{client_name}/)
      found=1
    end
    if found == 0
      copy.push(line)
    end
    if found == 1 and line.match(/\}/)
      found=0
    end
  end
  File.open($dhcpd_file,"w") {|file| file.puts copy}
  return
end

# Backup file

def backup_file(file_name)
  date_string = get_date_string()
  backup_file = File.basename(file_name)+"."+date_string
  backup_file = $backup_dir+backup_file
  message     = "Archiving:\tFile "+file_name+" to "+backup_file
  command     = "cp #{file_name} #{backup_file}"
  execute_command(message,command)
  return
end

# Wget a file

def wget_file(file_url,file_name)
  if $download_mode == 1
    file_dir = File.dirname(file_name)
    check_dir_exists(file_dir)
    message  = "Fetching:\tURL "+file_url+" to "+file_name
    command  = "wget #{file_url} -O #{file_name}"
    execute_command(message,command)
  end
  return
end
# Find client MAC

def get_install_mac(client_name)
  ethers_file = "/etc/ethers"
  output      = ""
  found       = 0
  if File.exist?(ethers_file)
    message    = "Checking:\tFile "+ethers_file+" for "+client_name+" MAC address"
    command    = "cat #{ethers_file} |grep '#{client_name} '|awk '{print $2}'"
    install_mac = execute_command(message,command)
    install_mac = install_mac.chomp
  end
  if !output.match(/[0-9]/)
    file=IO.readlines($dhcpd_file)
    file.each do |line|
      line=line.chomp
      if line.match(/#{client_name}/)
        found=1
      end
      if found == 1
        if line.match(/ethernet/)
          install_mac = line.split(/ ethernet /)[1]
          install_mac = install_mac.gsub(/\;/,"")
          return install_mac
        end
      end
    end
  end
  return install_mac
end

# Check if a directory exists
# If not create it

def check_dir_exists(dir_name)
  output  = ""
  if !File.directory?(dir_name) and !File.symlink?(dir_name)
    if dir_name.match(/[A-z]/)
      message = "Information:\tCreating: "+dir_name
      command = "mkdir -p '#{dir_name}'"
      output  = execute_command(message,command)
    end
  end
  return output
end

# Check a filesystem / directory exists

def check_fs_exists(dir_name)
  output = ""
  if $os_name.match(/SunOS/)
    output = check_zfs_fs_exists(dir_name)
  else
    check_dir_exists(dir_name)
  end
  return output
end

# Check if a ZFS filesystem exists
# If not create it

def check_zfs_fs_exists(dir_name)
  output = ""
  if !File.directory?(dir_name)
    if $os_name.match(/SunOS/)
      if dir_name.match(/clients/)
        root_dir = dir_name.split(/\//)[0..-2].join("/")
        if !File.directory?(root_dir)
          check_zfs_fs_exists(root_dir)
        end
      end
      if dir_name.match(/ldoms|zones/)
        zfs_name = $default_dpool+dir_name
      else
        zfs_name = $default_zpool+dir_name
      end
      if dir_name.match(/vmware_|openbsd_|coreos_/) or $os_rel > 10
        service_name = File.basename(dir_name)
        mount_dir    = $tftp_dir+"/"+service_name
        if !File.directory?(mount_dir)
          Dir.mkdir(mount_dir)
        end
      else
        mount_dir = dir_name
      end
      message      = "Information:\tCreating "+dir_name+" with mount point "+mount_dir
      command      = "zfs create -o mountpoint=#{mount_dir} #{zfs_name}"
      execute_command(message,command)
      if dir_name.match(/vmware_|openbsd_|coreos_/) or $os_rel > 10
        message = "Information:\tSymlinking "+mount_dir+" to "+dir_name
        command = "ln -s #{mount_dir} #{dir_name}"
        execute_command(message,command)
      end
    else
      check_dir_exists(dir_name)
    end
  end
  return output
end

# Destroy a ZFS filesystem

def destroy_zfs_fs(dir_name)
  output = ""
  if dir_name.match(/ldoms|zones/)
    zfs_name = $default_dpool+dir_name
  else
    zfs_name = $default_zpool+dir_name
  end
  zfs_list = %x[zfs list |grep -v NAME |awk '{print $1}' |grep "^#{zfs_name}$"]
  if zfs_list.match(/#{zfs_name}/)
    if $destroy_fs !~ /y|n/
      while $destroy_fs !~ /y|n/
        print "Destroy ZFS filesystem "+zfs_name+" [y/n]: "
        $destroy_fs = gets.chomp
      end
    end
    if $destroy_fs == "y"
      if File.directory?(dir_name)
        message = "Warning:\tDestroying "+dir_name
        command = "zfs destroy -r #{zfs_name}"
        output  = execute_command(message,command)
      end
    end
  end
  if File.directory?(dir_name)
    Dir.rmdir(dir_name)
  end
  return output
end

# Routine to execute command
# Prints command if verbose switch is on
# Does not execute cerver/client import/create operations in test mode

def execute_command(message,command)
  output  = ""
  execute = 0
  if $verbose_mode == 1
    if message.match(/[A-z|0-9]/)
      puts message
    end
  end
  if $test_mode == 1
    if !command.match(/create|update|import|delete|svccfg|rsync|cp|touch|svcadm|VBoxManage|vmrun/)
      execute = 1
    end
  else
    execute = 1
  end
  if execute == 1
    if $id != 0
      if !command.match(/brew |hg|pip|VBoxManage|netstat/)
        if $use_sudo != 0
          command = "sudo sh -c '"+command+"'"
        end
      end
    end
    if $verbose_mode == 1
      puts "Executing:\t"+command
    end
    if $execute_host == "localhost"
      output = %x[#{command}]
    else
      Net::SSH.start(hostname, username, :password => password, :paranoid => false) do |ssh_session|
        output = ssh_session.exec!(command)
      end
    end
  end
  if $verbose_mode == 1
    if output.length > 1
      if !output.match(/\n/)
        puts "Output:\t\t"+output
      else
        multi_line_output = output.split(/\n/)
        multi_line_output.each do |line|
          puts "Output:\t\t"+line
        end
      end
    end
  end
  return output
end

# Convert current date to a string that can be used in file names

def get_date_string()
  time        = Time.new
  time        = time.to_a
  date        = Time.utc(*time)
  date_string = date.to_s.gsub(/\s+/,"_")
  date_string = date_string.gsub(/:/,"_")
  date_string = date_string.gsub(/-/,"_")
  if $verbose_mode == 1
    puts "Information:\tSetting date string to "+date_string
  end
  return date_string
end

# Create an encrypted password field entry for a give password

def get_password_crypt(password)
  crypt = UnixCrypt::MD5.build(password)
  return crypt
end

# Restart DHCPd

def restart_dhcpd()
  if $os_name.match(/SunOS/)
    function         = "refresh"
    smf_service_name = "svc:/network/dhcp/server:ipv4"
    output           = handle_smf_service(function,smf_service_name)
  else
    service_name = "dhcpd"
    refresh_service(service_name)
  end
  return output
end

# Check DHPCPd is running

def check_dhcpd()
  message = "Checking:\tDHCPd is running"
  if $os_name.match(/SunOS/)
    command = "svcs -l svc:/network/dhcp/server:ipv4"
    output  = execute_command(message,command)
    if output.match(/disabled/)
      function         = "enable"
      smf_service_name = "svc:/network/dhcp/server:ipv4"
      output           = handle_smf_service(function,smf_service_name)
    end
    if output.match(/maintenance/)
      function         = "refresh"
      smf_service_name = "svc:/network/dhcp/server:ipv4"
      output           = handle_smf_service(function,smf_service_name)
    end
  end
  if $os_name.match(/Darwin/)
    command = "ps aux |grep '/usr/local/bin/dhcpd' |grep -v grep"
    output  = execute_command(message,command)
    if !output.match(/dhcp/)
      service = "dhcp"
      check_osx_service_is_enabled(service)
      service_name = "dhcp"
      refresh_service(service_name)
    end
    check_osx_tftpd()
  end
  return output
end

# Get service basename

def get_service_base_name(service_name)
  service_name = service_name.gsub(/_i386|_x86_64|_sparc/,"")
  return service_name
end

# Get service name

def get_service_name(service_name)
  if $os_name.match(/SunOS/)
    if service_name.match(/apache/)
      service_name = "svc:/network/http:apache22"
    end
    if service_name.match(/dhcp/)
      service_name = "svc:/network/dhcp/server:ipv4"
    end
  end
  if $os_name.match(/Darwin/)
    if service_name.match(/apache/)
      service_name = "org.apache.httpd"
    end
    if service_name.match(/dhcp/)
      service_name = "homebrew.mxcl.isc-dhcp"
    end
    if service_name.match(/dnsmasq/)
      service_name = "homebrew.mxcl.dnsmasq"
    end
    if service_name.match(/^puppet$/)
      service_name = "com.puppetlabs.puppet.plist"
    end
    if service_name.match(/^puppetmaster$/)
      service_name = "com.puppetlabs.puppetmaster.plist"
    end
  end
  if $os_name.match(/RedHat|CentOS|SuSE|Ubuntu/)
  end
  return service_name
end

# Enable service

def enable_service(service_name)
  service_name = get_service_name(service_name)
  if $os_name.match(/SunOS/)
    output = enable_smf_service(service_name)
  end
  if $os_name.match(/Darwin/)
    output = enable_osx_service(service_name)
  end
  if $os_name.match(/Linux/)
    output = enable_linux_service(service_name)
  end
  return output
end

# Disable service

def disable_service(service_name)
  service_name = get_service_name(service_name)
  if $os_name.match(/SunOS/)
    output = disable_smf_service(service_name)
  end
  if $os_name.match(/Darwin/)
    output = disable_osx_service(service_name)
  end
  return output
end

# Refresh / Restart service

def refresh_service(service_name)
  service_name = get_service_name(service_name)
  if $os_name.match(/SunOS/)
    output = refresh_smf_service(service_name)
  end
  if $os_name.match(/Darwin/)
    output = refresh_osx_service(service_name)
  end
  if $os_name.match(/Linux/)
    restart_linux_service(service_name)
  end
  return output
end

# Calculate route

def get_ipv4_default_route(client_ip)
  octets             = client_ip.split(/\./)
  octets[3]          = "254"
  ipv4_default_route = octets.join(".")
  return ipv4_default_route
end

# Create a ZFS filesystem for ISOs if it doesn't exist
# Eg /export/isos
# This could be an NFS mount from elsewhere
# If a directory already exists it will do nothing
# It will check that there are ISOs in the directory
# If none exist it will exit

def check_iso_base_dir(search_string)
  iso_list = []
  if $verbose_mode == 1
    puts "Checking:\t"+$iso_base_dir
  end
  check_fs_exists($iso_base_dir)
  message  = "Getting:\t"+$iso_base_dir+" contents"
  if search_string.match(/[A-z]/)
    command  = "ls #{$iso_base_dir}/*.iso |egrep \"#{search_string}\" |grep -v '2.iso' |grep -v 'supp-server'"
  else
    command  = "ls #{$iso_base_dir}/*.iso |grep -v '2.iso' |grep -v 'supp-server'"
  end
  iso_list = execute_command(message,command)
  if search_string.match(/sol_11/)
    if !iso_list.grep(/full/)
      puts "Warning:\tNo full repository ISO images exist in "+$iso_base_dir
      if $test_mode != 1
        exit
      end
    end
  end
  iso_list = iso_list.split(/\n/)
  return iso_list
end

# Check client architecture

def check_client_arch(client_arch,opt)
  if !client_arch.match(/i386|sparc|x86_64/)
    if opt["F"] or opt["O"]
      if opt["A"]
        puts "Information:\tSetting architecture to x86_64"
        client_arch = "x86_64"
      end
    end
    if opt["n"]
      service_name = opt["n"]
      service_arch = service_name.split("_")[-1]
      if service_arch.match(/i386|sparc|x86_64/)
        client_arch = service_arch
      end
    end
  end
  if !client_arch.match(/i386|sparc|x86_64/)
    puts "Warning:\tInvalid architecture specified"
    puts "Warning:\tUse -a i386, -a x86_64 or -a sparc"
    exit
  end
  return client_arch
end

# Check client MAC

def check_install_mac(install_mac)
  if !install_mac.match(/:/)
    if install_mac.length != 12
      puts "Warning:\tInvalid MAC address"
      exit
    else
      chars       = install_mac.split(//)
      install_mac = chars[0..1].join+":"+chars[2..3].join+":"+chars[4..5].join+":"+chars[6..7].join+":"+chars[8..9].join+":"+chars[10..11].join
    end
  end
  macs = install_mac.split(":")
  if macs.length != 6
    puts "Warning:\tInvalid MAC address"
    exit
  end
  macs.each do |mac|
    if mac =~ /[G-Z]|[g-z]/ or mac.length != 2
      puts "Warning:\tInvalid MAC address"
      exit
    end
  end
  return install_mac
end

# Check install IP

def check_install_ip(install_ip)
  ips = install_ip.split(".")
  if ips.length != 4
    puts "Warning:\tInvalid IP Address"
    exit
  end
  ips.each do |ip|
    if ip =~ /[A-z]/ or ip.length > 3 or ip.to_i > 254
      puts "Warning:\tInvalid IP Address"
      exit
    end
  end
  return
end


# Add apache proxy

def add_apache_proxy(publisher_host,publisher_port,service_base_name)
  if $os_name.match(/SunOS/)
    apache_config_file = "/etc/apache2/2.2/httpd.conf"
  end
  if $os_name.match(/Darwin/)
    apache_config_file = "/etc/apache2/httpd.conf"
  end
  if $os_name.match(/Linux/)
    apache_config_file = "/etc/httpd/conf/httpd.conf"
  end
  apache_check = %x[cat #{apache_config_file} |grep #{service_base_name}]
  if !apache_check.match(/#{service_base_name}/)
    message = "Archiving:\t"+apache_config_file+" to "+apache_config_file+".no_"+service_base_name
    command = "cp #{apache_config_file} #{apache_config_file}.no_#{service_base_name}"
    execute_command(message,command)
    message = "Adding:\t\tProxy entry to "+apache_config_file
    command = "echo 'ProxyPass /"+service_base_name+" http://"+publisher_host+":"+publisher_port+" nocanon max=200' >>"+apache_config_file
    execute_command(message,command)
    service_name = "apache"
    enable_service(service_name)
    refresh_service(service_name)
  end
  return
end

# Remove apache proxy

def remove_apache_proxy(service_base_name)
  if $os_name.match(/SunOS/)
    apache_config_file = "/etc/apache2/2.2/httpd.conf"
  end
  if $os_name.match(/Darwin/)
    apache_config_file = "/etc/apache2/httpd.conf"
  end
  if $os_name.match(/Linux/)
    apache_config_file = "/etc/httpd/conf/httpd.conf"
  end
  message      = "Checking:\tApache confing file "+apache_config_file+" for "+service_base_name
  command      = "cat #{apache_config_file} |grep '#{service_base_name}'"
  apache_check = execute_command(message,command)
  if apache_check.match(/#{service_base_name}/)
    restore_file = apache_config_file+".no_"+service_base_name
    if File.exist?(restore_file)
      message = "Restoring:\t"+restore_file+" to "+apache_config_file
      command = "cp #{restore_file} #{apache_config_file}"
      execute_command(message,command)
      service_name = "apache"
      refresh_service(service_name)
    end
  end
end

# Add apache alias

def add_apache_alias(service_base_name)
  if service_base_name.match(/^\//)
    apache_alias_dir  = service_base_name
    service_base_name = File.basename(service_base_name)
  else
    apache_alias_dir = $repo_base_dir+"/"+service_base_name
  end
  if $os_name.match(/SunOS/)
    apache_config_file = "/etc/apache2/2.2/httpd.conf"
  end
  if $os_name.match(/Darwin/)
    apache_config_file = "/etc/apache2/httpd.conf"
  end
  if $os_name.match(/Linux/)
    apache_config_file = "/etc/httpd/conf/httpd.conf"
    if $os_info.match(/CentOS|RedHat/)
      apache_doc_root = "/var/www/html"
      apache_doc_dir  = apache_doc_root+"/"+service_base_name
    end
  end
  if $os_name.match(/SunOS/)
    tmp_file     = "/tmp/httpd.conf"
    message      = "Checking:\tApache confing file "+apache_config_file+" for "+service_base_name
    command      = "cat #{apache_config_file} |grep '/#{service_base_name}'"
    apache_check = execute_command(message,command)
    if !apache_check.match(/#{service_base_name}/)
      message = "Archiving:\tApache config file "+apache_config_file+" to "+apache_config_file+".no_"+service_base_name
      command = "cp #{apache_config_file} #{apache_config_file}.no_#{service_base_name}"
      execute_command(message,command)
      if $verbose_mode == 1
        puts "Adding:\t\tDirectory and Alias entry to "+apache_config_file
      end
      message = "Copying:\tApache config file so it can be edited"
      command = "cp #{apache_config_file} #{tmp_file} ; chown #{$id} #{tmp_file}"
      execute_command(message,command)
      output = File.open(tmp_file,"a")
      output.write("<Directory #{apache_alias_dir}>\n")
      if service_base_name.match(/oel/)
        output.write("Options Indexes FollowSymLinks\n")
      else
        output.write("Options Indexes\n")
      end
      output.write("Allow from #{$default_apache_allow}\n")
      output.write("</Directory>\n")
      output.write("Alias /#{service_base_name} #{apache_alias_dir}\n")
      output.close
      message = "Updating:\tApache config file"
      command = "cp #{tmp_file} #{apache_config_file} ; rm #{tmp_file}"
      execute_command(message,command)
    end
    if $os_name.match(/SunOS|Linux/)
      if $os_name.match(/Linux/)
        service_name = "httpd"
      else
        service_name = "apache"
      end
      enable_service(service_name)
      refresh_service(service_name)
    end
    if $os_name.match(/Linux/)
      if $os_info.match(/RedHat/)
        if $os_ver.match(/^7|^6\.7/)
          httpd_p = "httpd_sys_rw_content_t"
          message = "Information:\tFixing permissions on "+$client_base_dir
          command = "chcon -R -t #{httpd_p} #{$client_base_dir}"
          execute_command(message,command)
        end
      end
    end
  end
  return
end

# Remove apache alias

def remove_apache_alias(service_base_name)
  remove_apache_proxy(service_base_name)
end

# Mount full repo isos under iso directory
# Eg /export/isos
# An example full repo file name
# /export/isos/sol-11_1-repo-full.iso
# It will attempt to mount them
# Eg /cdrom
# If there is something mounted there already it will unmount it

def mount_iso(iso_file)
  puts "Information:\tProcessing: "+iso_file
  output  = check_dir_exists($iso_mount_dir)
  message = "Checking:\tExisting mounts"
  command = "df |awk '{print $1}' |grep '^#{$iso_mount_dir}$'"
  output  = execute_command(message,command)
  if output.match(/[A-z]/)
    message = "Information:\tUnmounting: "+$iso_mount_dir
    command = "umount "+$iso_mount_dir
    output  = execute_command(message,command)
  end
  message = "Information:\tMounting ISO "+iso_file+" on "+$iso_mount_dir
  if $os_name.match(/SunOS/)
    command = "mount -F hsfs "+iso_file+" "+$iso_mount_dir
  end
  if $os_name.match(/Darwin/)
    command = "sudo hdiutil attach -nomount #{iso_file} |head -1 |awk '{print $1}'"
    if $verbose_mode == 1
      puts "Executing:\t"+command
    end
    disk_id = %x[#{command}]
    disk_id = disk_id.chomp
    command = "sudo mount -t cd9660 "+disk_id+" "+$iso_mount_dir
  end
  if $os_name.match(/Linux/)
    command = "mount -t iso9660 -o loop "+iso_file+" "+$iso_mount_dir
  end
  output = execute_command(message,command)
  if iso_file.match(/sol/)
    if iso_file.match(/\-ga\-/)
      iso_test_dir = $iso_mount_dir+"/boot"
    else
      iso_test_dir = $iso_mount_dir+"/repo"
    end
  else
    case iso_file
    when /SLES/
      iso_test_dir = $iso_mount_dir+"/suse"
    when /CentOS|SL/
      iso_test_dir = $iso_mount_dir+"/repodata"
    when /rhel|OracleLinux|Fedora/
      iso_test_dir = $iso_mount_dir+"/Packages"
    when /VCSA/
      iso_test_dir = $iso_mount_dir+"/vcsa"
    when /VM/
      iso_test_dir = $iso_mount_dir+"/upgrade"
    when /install|FreeBSD/
      iso_test_dir = $iso_mount_dir+"/etc"
    when /coreos/
      iso_test_dir = $iso_mount_dir+"/coreos"
    else
      iso_test_dir = $iso_mount_dir+"/install"
    end
  end
  if !File.directory?(iso_test_dir) and !iso_file.match(/DVD2\.iso|2of2\.iso|repo-full/)
    puts "Warning:\tISO did not mount, or this is not a repository ISO"
    puts "Warning:\t"+iso_test_dir+" does not exit"
    if $test_mode != 1
      umount_iso()
      exit
    end
  end
  return
end

# Check ISO mounted for OS X based server

def check_osx_iso_mount(mount_dir,iso_file)
  check_dir_exists(mount_dir)
  test_dir = mount_dir+"/boot"
  if !File.directory?(test_dir)
    message = "Mounting:\ISO "+iso_file+" on "+mount_dir
    command = "hdiutil mount #{iso_file} -mountpoint #{mount_dir}"
    output  = execute_command(message,command)
  end
  return output
end

# Copy repository from ISO to local filesystem

def copy_iso(iso_file,repo_version_dir)
  if $verbose_mode == 1
    puts "Checking:\tIf we can copy data from full repo ISO"
  end
  if iso_file.match(/sol/)
    iso_test_dir = $iso_mount_dir+"/repo"
    if File.directory?(iso_test_dir)
      iso_repo_dir = iso_test_dir
    else
      iso_test_dir = $iso_mount_dir+"/publisher"
      if File.directory?(iso_test_dir)
        iso_repo_dir = $iso_mount_dir
      else
        puts "Warning:\tRepository source directory does not exist"
        if $test_mode != 1
          exit
        end
      end
    end
    test_dir = repo_version_dir+"/publisher"
  else
    iso_repo_dir = $iso_mount_dir
    case iso_file
    when /CentOS|rhel|OracleLinux|Fedora/
      test_dir = repo_version_dir+"/isolinux"
    when /VCSA/
      test_dir = repo_version_dir+"/vcsa"
    when /VM/
      test_dir = repo_version_dir+"/upgrade"
    when /install|FreeBSD/
      test_dir = repo_version_dir+"/etc"
    when /coreos/
      test_dir = repo_version_dir+"/coreos"
    when /SLES/
      test_dir = repo_version_dir+"/suse"
    else
      test_dir = repo_version_dir+"/install"
    end
  end
  if !File.directory?(repo_version_dir) and !File.symlink?(repo_version_dir) and !iso_file.match(/2\.iso/)
    puts "Warning:\tRepository directory "+repo_version_dir+" does not exist"
    if $test_mode != 1
      exit
    end
  end
  if !File.directory?(test_dir) or iso_file.match(/DVD2\.iso|2of2\.iso/)
    if iso_file.match(/sol/)
      if !File.directory?(iso_repo_dir)
        puts "Warning:\tRepository source directory "+iso_repo_dir+" does not exist"
        if $test_mode != 1
          exit
        end
      end
      message = "Copying:\t"+iso_repo_dir+" contents to "+repo_version_dir
      command = "rsync -a #{iso_repo_dir}/* #{repo_version_dir}"
      output  = execute_command(message,command)
      if $os_name.match(/SunOS/)
        message = "Rebuilding:\tRepository in "+repo_version_dir
        command = "pkgrepo -s #{repo_version_dir} rebuild"
        output  = execute_command(message,command)
      end
    else
      check_dir_exists(test_dir)
      message = "Copying:\t"+iso_repo_dir+" contents to "+repo_version_dir
      command = "rsync -a #{iso_repo_dir}/* #{repo_version_dir}"
      if repo_version_dir.match(/sles_12/) 
        if !iso_file.match(/2\.iso/)
          output  = execute_command(message,command)
        end
      else
        puts message
        output  = execute_command(message,command)
      end
    end
  end
  return
end

# Unmount ISO

def umount_iso()
  if $os_name.match(/Darwin/)
    command = "df |grep '#{$iso_mount_dir}$' |head -1 |awk '{print $1}'"
    if $verbose_mode == 1
      puts "Executing:\t"+command
    end
    disk_id = %x[#{command}]
    disk_id = disk_id.chomp
  end
  if $os_name.match(/Darwin/)
    message = "Detaching:\tISO device "+disk_id
    command = "sudo hdiutil detach #{disk_id}"
    execute_command(message,command)
  else
    message = "Unmounting:\tISO mounted on "+$iso_mount_dir
    command = "umount #{$iso_mount_dir}"
    execute_command(message,command)  
  end
  return
end

# Clear a service out of maintenance mode

def clear_service(service_name)
  message    = "Checking:\tStatus of service "+service_name
  command    = "sleep 5 ; svcs -a |grep '#{service_name}' |awk '{print $1}'"
  output     = execute_command(message,command)
  if output.match(/maintenance/)
    message    = "Clearing:\tService "+service_name
    command    = "svcadm clear #{service_name}"
    output     = execute_command(message,command)
  end
  return
end


# Occassionally DHCP gets stuck if it's restart to often
# Clear it out of maintenance mode

def clear_solaris_dhcpd()
  service_name = "svc:/network/dhcp/server:ipv4"
  clear_service(service_name)
  return
end
