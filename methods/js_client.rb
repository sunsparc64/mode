
# Jumpstart client routines

# Create sysid file

def create_js_sysid_file(install_client,sysid_file)
  tmp_file = "/tmp/sysid_"+install_client
  file=File.open(tmp_file,"w")
  $q_order.each do |key|
    if $q_struct[key].type == "output"
      if $q_struct[key].parameter == ""
        output = $q_struct[key].value+"\n"
      else
        output = $q_struct[key].parameter+"="+$q_struct[key].value+"\n"
      end
    end
    file.write(output)
  end
  file.close
  message = "Information:\tCreating configuration file "+sysid_file+" for "+install_client
  command = "cp #{tmp_file} #{sysid_file} ; rm #{tmp_file}"
  execute_command(message,command)
  print_contents_of_file("",sysid_file)
  return
end

# Create machine file

def create_js_machine_file(install_client,machine_file)
  tmp_file = "/tmp/machine_"+install_client
  file=File.open(tmp_file,"w")
  $q_order.each do |key|
    if $q_struct[key].type == "output"
      if $q_struct[key].parameter == ""
        output = $q_struct[key].value+"\n"
      else
        output = $q_struct[key].parameter+" "+$q_struct[key].value+"\n"
      end
    end
    file.write(output)
  end
  file.close
  message = "Information:\tCreating configuration file "+machine_file+" for "+install_client
  command = "cp #{tmp_file} #{machine_file} ; rm #{tmp_file}"
  execute_command(message,command)
  print_contents_of_file("",machine_file)
  return
end

# Get rules karch line

def create_js_rules_file(install_client,client_karch,rules_file)
  tmp_file   = "/tmp/rule_"+install_client
  if client_karch.match(/sun4/)
    karch_line = "karch "+client_karch+" - machine."+install_client+" -"
  else
    if client_karch.match(/packer/)
      karch_line = "any - - profile finish"
    else
      karch_line = "any - - machine."+install_client+" -"
    end
  end
  file       = File.open(tmp_file,"w")
  file.write("#{karch_line}\n")
  file.close
  message = "Information:\tCreating configuration file "+rules_file+" for "+install_client
  command = "cp #{tmp_file} #{rules_file} ; rm #{tmp_file}"
  execute_command(message,command)
  print_contents_of_file("",rules_file)
  return karch_line
end

# List jumpstart clients

def list_js_clients()
  list_clients("js")
  return
end

def create_rules_ok_file(install_client,client_dir)
  rules_file    = client_dir+"/rules"
  rules_ok_file = rules_file+".ok"
  if File.exist?(rules_ok_file)
    message = "Information:\tRemoving existing rules.ok file for client "+install_client
    command = "rm #{rules_ok_file}"
    output  = execute_command(message,command)
  end
  message   = "Information:\tChecking sum for rules file for "+install_client
  if $os_name.match(/SunOS/)
    command   = "sum #{rules_file} | awk '{print $1}'"
  else
    command   = "cksum -o 2 #{rules_file} | awk '{print $1}'"
  end
  output    = execute_command(message,command)
  rules_sum = output.chomp.split(/ /)[0]
  message   = "Information:\tCopying rules file"
  command   = "cd #{client_dir}; cp rules rules.ok"
  execute_command(message,command)
  output    = "# version=2 checksum=#{rules_sum}"
  message   = "Information:\tCreating rules file "+rules_ok_file
  command   = "echo '#{output}' >> #{rules_ok_file}"
  execute_command(message,command)
  print_contents_of_file("",rules_ok_file)
  return
end

# Create finish script

def create_js_finish_file(install_client,output_file)
  passwd_crypt = get_password_crypt($default_admin_password) 
  file_array   = []
  file_array.push("#!/bin/sh")
  file_array.push("")
  file_array.push("ADMINUSER='#{$default_admin_user}'")
  file_array.push("")
  file_array.push("# Selecting host name")
  file_array.push("echo '#{install_client}' > /a/etc/nodename")
  file_array.push("")
  file_array.push("# Allowing root SSH")
  file_array.push("cat /a/etc/ssh/sshd_config | sed -e 's/PermitRootLogin\\ .*$/PermitRootLogin yes/g' > /tmp/sshd_config.$$")
  file_array.push("cat /tmp/sshd_config.$$ > /a/etc/ssh/sshd_config")
  file_array.push("")
  file_array.push("# Allow simple passwords")
  file_array.push("cat /a/etc/default/passwd | sed -e 's/^#NAMECHECK=.*$/NAMECHECK=NO/g' \\")
  file_array.push("    -e 's/^#MINNONALPHA=.*$/MINNONALPHA=0/g' > /tmp/passwd.$$")
  file_array.push("cat /tmp/passwd.$$ > /a/etc/default/passwd")
  file_array.push("")
  file_array.push("# Create user and group")
  file_array.push("")
  file_array.push("chroot /a /usr/sbin/groupadd ${ADMINUSER}")
  file_array.push("chroot /a /usr/sbin/useradd -m -d /export/home/${ADMINUSER} -s /usr/bin/bash -g ${ADMINUSER} ${ADMINUSER}")
  file_array.push("")
  file_array.push("# Create password")
  file_array.push("PASSWD=`perl -e 'print crypt($ARGV[0], substr(rand(data),2));' #{$default_admin_password}`")
  file_array.push("cat /a/etc/shadow | sed -e 's#^'${ADMINUSER}':UP:#'${ADMINUSER}':'${PASSWD}'#g'  > /tmp/shadow.$$")
  file_array.push("cat /tmp/shadow.$$ > /a/etc/shadow")
  file_array.push("")
  file_array.push("# Install 'Primary Administrator' profile")
  file_array.push("")
  file_array.push("cat /cdrom/Solaris_10/Product/SUNWwbcor/reloc/etc/security/auth_attr >> /a/etc/security/auth_attr")
  file_array.push("cat /cdrom/Solaris_10/Product/SUNWwbcor/reloc/etc/security/exec_attr >> /a/etc/security/exec_attr")
  file_array.push("cat /cdrom/Solaris_10/Product/SUNWwbcor/reloc/etc/security/prof_attr >> /a/etc/security/prof_attr")
  file_array.push("")
  file_array.push("# Assign it to admin")
  file_array.push("chroot /a /usr/sbin/usermod -P'Primary Administrator' ${ADMINUSER}")
  file = File.open(output_file,"w")
  file_array.each do |line|
    line = line+"\n"
    file.write(line)
  end
  file.close()
  print_contents_of_file("",output_file)
  return
end

# Check Jumpstart config

def check_js_config(install_client,client_dir,repo_version_dir,os_version)
  file_name     = "check"
  check_script  = repo_version_dir+"/Solaris_"+os_version+"/Misc/jumpstart_sample/"+file_name
  if !File.exist?("#{client_dir}/check")
    message = "Information:\tCopying check script "+check_script+" to "+client_dir
    command = "cd #{client_dir} ; cp -p #{check_script} ."
    output  = execute_command(message,command)
  end
  create_rules_ok_file(install_client,client_dir)
  return
end

# Remove client

def remove_js_client(install_client,repo_version_dir,install_service)
  remove_dhcp_client(install_client)
  return
end

# Configure client PXE boot

def configure_js_pxe_client(install_client,install_mac,install_arch,install_service,repo_version_dir,publisher_host)
  if install_arch.match(/i386/)
    tftp_pxe_file = install_mac.gsub(/:/,"")
    tftp_pxe_file = tftp_pxe_file.upcase
    tftp_pxe_file = "01"+tftp_pxe_file+".bios"
    test_file     = $tftp_dir+"/"+tftp_pxe_file
    if !File.exist?(test_file)
      pxegrub_file = install_service+"/boot/grub/pxegrub"
      message      = "Information:\tCreating PXE boot file for "+install_client+" with MAC address "+install_mac
      command      = "cd #{$tftp_dir} ; ln -s #{pxegrub_file} #{tftp_pxe_file}"
      execute_command(message,command)
    end
    pxe_cfg_file = install_mac.gsub(/:/,"")
    pxe_cfg_file = "01"+pxe_cfg_file.upcase
    pxe_cfg_file = "menu.lst."+pxe_cfg_file
    pxe_cfg_file = $tftp_dir+"/"+pxe_cfg_file
    sysid_dir    = $client_base_dir+"/"+install_service+"/"+install_client
    install_url  = publisher_host+":"+repo_version_dir
    sysid_url    = publisher_host+":"+sysid_dir
    tmp_file     = "/tmp/pxe_"+install_client
    file         = File.open(tmp_file,"w")
    file.write("default 0\n")
    file.write("timeout 3\n")
    file.write("title Oracle Solaris\n")
    if $text_mode == 1
      if $serial_mode == 1
        file.write("\tkernel$ #{install_service}/boot/multiboot kernel/$ISADIR/unix - install nowin -B console=ttya,keyboard-layout=US-English,install_media=#{install_url},install_config=#{sysid_url},sysid_config=#{sysid_url}\n")
      else
        file.write("\tkernel$ #{install_service}/boot/multiboot kernel/$ISADIR/unix - install nowin -B keyboard-layout=US-English,install_media=#{install_url},install_config=#{sysid_url},sysid_config=#{sysid_url}\n")
      end
    else
      file.write("\tkernel$ #{install_service}/boot/multiboot kernel/$ISADIR/unix - install -B keyboard-layout=US-English,install_media=#{install_url},install_config=#{sysid_url},sysid_config=#{sysid_url}\n")
    end
    file.write("\tmodule$ #{install_service}/boot/$ISADIR/x86.miniroot\n")
    file.close
    message = "Information:\tCreating PXE boot config file "+pxe_cfg_file
    command = "cp #{tmp_file} #{pxe_cfg_file} ; rm #{tmp_file}"
    execute_command(message,command)
    print_contents_of_file("",pxe_cfg_file)
  end
  return
end

# Configure DHCP client

def configure_js_dhcp_client(install_client,install_mac,install_ip,install_arch,install_service)
  add_dhcp_client(install_client,install_mac,install_ip,install_arch,install_service)
  return
end

# Unconfigure DHCP client

def unconfigure_js_dhcp_client(install_client)
  remove_dhcp_client(install_client)
  return
end

# Unconfigure client

def unconfigure_js_client(install_client,install_mac,install_service)
  if install_service.match(/[a-z,A-Z]/)
    repo_version_dir=$repo_base_dir+install_service
    if File.directory(repo_version_dir)
      remove_js_client(install_client,repo_version_dir,install_service)
    else
      handle_output("Warning:\tClient #{install_client} does not exist under service #{install_service}")
    end
  end
  service_list = Dir.entries($repo_base_dir)
  service_list.each do |temp_name|
    if temp_name.match(/sol/) and !temp_name.match(/sol_11/)
      repo_version_dir = $repo_base_dir+"/"+temp_name
      clients_dir      = repo_version_dir+"/clients"
      if File.directory?(clients_dir)
        client_list = Dir.entries(clients_dir)
        client_list.each do |dir_name|
          if dir_name.match(/#{install_client}/)
            remove_js_client(install_client,repo_version_dir,temp_name)
            return
          end
        end
      end
    end
  end
  install_ip = get_install_ip(install_client)
  remove_hosts_entry(install_client,install_ip)
  return
end

# Configure client

def configure_js_client(install_client,install_arch,install_mac,install_ip,install_model,publisher_host,install_service,
                        install_file,install_memory,install_cpu,install_network,install_license,install_mirror,install_type,install_vm)
  if !install_arch.match(/i386|sparc/)
    if install_file
      if install_file.match(/i386/)
        install_arch = "i386"
      else
        install_arch = "sparc"
      end
    end
    if install_service
      if install_service.match(/i386/)
        install_arch = "i386"
      else
        install_arch = "sparc"
      end
    end
  end
  if install_file.match(/flar/)
    if !File.exist?(image_file)
      handle_output("Warning:\tFlar file #{install_file} does not exist")
      exit
    else
      message = "Information:\tMaking sure file is world readable"
      command = "chmod 755 #{install_file}"
      execute_command(message,command)
    end
    export_dir  = Pathname.new(install_file)
    export_dir  = export_dir.dirname.to_s
    add_apache_alias(export_dir)
    if !install_service.match(/[a-z,A-Z]/)
      install_service = Pathname.new(install_file)
      install_service = install_service.basename.to_s.gsub(/\.flar/,"")
    end
  else
    if !install_service.match(/i386|sparc/)
      install_service = install_service+"_"+install_arch
    end
    if !install_service.match(/#{install_arch}/)
      handle_output("Information:\tService #{install_service} and Client architecture #{install_arch} do not match")
     exit
    end
    repo_version_dir=$repo_base_dir+"/"+install_service
    if !File.directory?(repo_version_dir)
      handle_output("Warning:\tService #{install_service} does not exist")
      handle_output("") 
      list_js_services()
      exit
    end
  end
  # Create clients directory
  clients_dir = $client_base_dir+"/"+install_service
  check_dir_exists(clients_dir)
  # Create client directory
  client_dir = clients_dir+"/"+install_client
  check_dir_exists(client_dir)
  # Get release information
  repo_version_dir = $repo_base_dir+"/"+install_service
  if $os_name.match(/Darwin/)
    check_osx_iso_mount(mount_dir,iso_file)
  end
  os_version = get_js_iso_version(repo_version_dir)
  os_update  = get_js_iso_update(repo_version_dir,os_version)
  # Populate sysid questions and process them
  populate_js_sysid_questions(install_client,install_ip,install_arch,install_model,os_version,os_update)
  process_questions(install_service)
  if install_arch.match(/i386/)
    install_karch = install_arch
  else
    install_karch = $q_struct["client_karch"].value
  end
  # Create sysid file
  sysid_file = client_dir+"/sysidcfg"
  create_js_sysid_file(install_client,sysid_file)
  # Populate machine questions
  populate_js_machine_questions(install_model,install_karch,publisher_host,install_service,os_version,os_update,install_file)
  process_questions(install_service)
  machine_file = client_dir+"/machine."+install_client
  create_js_machine_file(install_client,machine_file)
  # Create rules file
  rules_file = client_dir+"/rules"
  create_js_rules_file(install_client,install_karch,rules_file)
  configure_js_pxe_client(install_client,install_mac,install_arch,install_service,repo_version_dir,publisher_host)
  configure_js_dhcp_client(install_client,install_mac,install_ip,install_arch,install_service)
  check_js_config(install_client,client_dir,repo_version_dir,os_version)
  add_hosts_entry(install_client,install_ip)
  return
end
