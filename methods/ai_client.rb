
# Clienbt code for AI

# List AI services

def list_ai_clients()
  message = "Information:\tAvailable AI clients"
  command = "installadm list -p |grep -v '^--' |grep -v '^Service'"
  output  = execute_command(message,command)
  client_info = output.split(/\n/)
  if client_info.length > 0
    if $output_format.match(/html/)
      handle_output("<h1>Available AI clients:</h1>")
      handle_output("<table border=\"1\">")
      handle_output("<tr>")
      handle_output("<th>Client</th>")
      handle_output("<th>Service</th>")
      handle_output("</tr>")
    else
      handle_output("")
      handle_output("Available AI clients:")
      handle_output("")
    end
    install_service = ""
    install_client  = ""
    client_info.each do |line|
      if line.match(/^[a-z,A-Z]/)
        install_service = line
      else
        install_client = line
        install_client = install_client.gsub(/^\s+/,"")
        install_client = install_client.gsub(/\s+/," ")
        if $output_format.match(/html/)
          handle_output("<tr>")
          handle_output("<td>#{install_client}</td>")
          handle_output("<td>#{install_service}</td>")
          handle_output("</tr>")
        else
          handle_output("#{install_client} [ service = #{install_service} ]")
        end
      end
    end
    if $output_format.match(/html/)
      handle_output("</table>")
    end
  end
  handle_output("")
  return
end

# Get a list of valid shells

def get_valid_shells()
  vaild_shells = %x[ls /usr/bin |grep 'sh$' |awk '{print "/usr/bin/" $1 }']
  vaild_shells = vaild_shells.split("\n").join(",")
  return vaild_shells
end

# Make sure user ID is greater than 100

def check_valid_uid(answer)
  correct = 1
  if answer.match(/[a-z,A-Z]/)
    correct = 0
  else
    if Integer(answer) < 100
      correct = 0
      handle_output("UID must be greater than 100")
    end
  end
  return correct
end

# Make sure user group is greater than 10

def check_valid_gid(answer)
  correct = 1
  if answer.match(/[a-z,A-Z]/)
    correct = 0
  else
    if Integer(answer) < 10
      correct = 0
      handle_output("GID must be greater than 10")
    end
  end
  return correct
end

# Get the user home directory ZFS dataset name

def get_account_home_zfs_dataset()
  account_home_zfs_dataset = "/export/home/"+$q_struct["account_login"].value
  return account_home_zfs_dataset
end

# Get the user home directory mount point

def get_account_home_mountpoint()
  account_home_mountpoint = "/export/home/"+$q_struct["account_login"].value
  return account_home_mountpoint
end

# Import AI manifest
# This is done to change the default manifest so that it doesn't point
# to the Oracle one amongst other things
# Check the structs for settings and more information

def import_ai_manifest(output_file,install_service)
  date_string = get_date_string()
  arch_list   = []
  base_name   = get_service_base_name(install_service)
  if !install_service.match(/i386|sparc/) and !client_arch.match(/i386|sparc/)
    arch_list = ["i386","SPARC"]
  else
    if install_service.match(/i386/)
      arch_list.push("i386")
    else
      if install_service.match(/sparc/)
        arch_list.push("SPARC")
      end
    end
  end
  arch_list.each do |sys_arch|
    lc_arch = sys_arch.downcase
    backup  = $work_dir+"/"+base_name+"_"+lc_arch+"_orig_default.xml."+date_string
    message = "Information:\tArchiving service configuration for "+base_name+"_"+lc_arch+" to "+backup
    command = "installadm export -n #{base_name}_#{lc_arch} -m orig_default > #{backup}"
    output  = execute_command(message,command)
    message = "Information:\tValidating service configuration "+output_file
    command = "AIM_MANIFEST=#{output_file} ; export AIM_MANIFEST ; aimanifest validate"
    output  = execute_command(message,command)
    if output.match(/[a-z,A-Z,0-9]/)
      handle_output("AI manifest file #{output_file} does not contain a valid XML manifest")
      handle_output(output)
    else
      message = "Information:\tImporting "+output_file+" to service "+install_service+" as manifest named "+$default_manifest_name
      command = "installadm create-manifest -n #{base_name}_#{lc_arch} -m #{$default_manifest_name} -f #{output_file}"
      output  = execute_command(message,command)
      message = "Information:\tSetting default manifest for service "+install_service+" to "+$default_manifest_name
      command = "installadm set-service -o default-manifest=#{$default_manifest_name} #{base_name}_#{lc_arch}"
      output  = execute_command(message,command)
    end
  end
  return
end

# Import a profile and associate it with a client

def import_ai_client_profile(output_file,install_client,install_mac,install_service)
  message = "Information:\tCreating profile for client "+install_client+" with MAC address "+install_mac
  command = "installadm create-profile -n #{install_service} -f #{output_file} -p #{install_client} -c mac='#{install_mac}'"
  execute_command(message,command)
  return
end

# Code to change timeout and default menu entry in grub

def update_ai_client_grub_cfg(install_mac)
  copy        = []
  netboot_mac = install_mac.gsub(/:/,"")
  netboot_mac = "01"+netboot_mac
  netboot_mac = netboot_mac.upcase
  grub_file   = $tftp_dir+"/grub.cfg."+netboot_mac
  if $verbose_mode == 1
    handle_output("Updating:\tGrub config file #{grub_file}")
  end
  if File.exists?(grub_file)
    text=File.read(grub_file)
    text.each do |line|
      if line.match(/set timeout=30/)
        copy.push("set timeout=5")
        copy.push("set default=1")
      else
        copy.push(line)
      end
    end
    File.open(grub_file,"w") {|file| file.puts copy}
    print_contents_of_file(grub_file)
  end
end

# Main code to configure AI client services
# Called from main code

def configure_ai_client_services(client_arch,publisher_host,publisher_port,install_service)
  handle_output("")
  handle_output("You will be presented with a set of questions followed by the default output")
  handle_output("If you are happy with the default output simply hit enter")
  handle_output("")
  service_list = []
  # Populate questions for AI manifest
  populate_ai_manifest_questions(publisher_host,publisher_port)
  # Process questions
  process_questions(install_service)
  # Set name of AI manifest file to create and import
  if install_service.match(/i386|sparc/)
    service_list[0] = install_service
  else
    service_list[0] = install_service+"_i386"
    service_list[1] = install_service+"_sparc"
  end
  service_list.each do |temp_name|
    output_file = $work_dir+"/"+temp_name+"_ai_manifest.xml"
    # Create manifest
    create_ai_manifest(output_file)
    # Import AI manifest
    import_ai_manifest(output_file,temp_name)
  end
  return
end

# Fix entry for client so it is given a fixed IP rather than one from the range

def update_ai_client_dhcpd_entry(install_client,install_mac,install_ip)
  copy        = []
  install_mac = install_mac.gsub(/:/,"")
  install_mac = install_mac.upcase
  dhcp_file   = "/etc/inet/dhcpd4.conf"
  backup_file(dhcp_file)
  text = File.read(dhcp_file)
  text.each do |line|
    if line.match(/^host #{install_mac}/)
      copy.push("host #{install_client} {")
      copy.push("  fixed-address #{install_ip};")
    else
      copy.push(line)
    end
  end
  File.open(dhcp_file,"w") {|file| file.puts copy}
  print_contents_of_file(dhcp_file)
  return
end

# Routine to actually add a client

def create_ai_client(install_client,client_arch,install_mac,install_service,install_ip)
  message = "Information:\tCreating client entry for #{install_client} with architecture #{client_arch} and MAC address #{install_mac}"
  command = "installadm create-client -n #{install_service} -e #{install_mac}"
   execute_command(message,command)
  if client_arch.match(/i386/) or client_arch.match(/i386/)
    update_ai_client_dhcpd_entry(install_client,install_mac,install_ip)
    update_ai_client_grub_cfg(install_mac)
  else
   add_dhcp_client(install_client,install_mac,install_ip,client_arch,install_service)
  end
  smf_service = "svc:/network/dhcp/server:ipv4"
  refresh_smf_service(smf_service)
  return
end

# Check AI client doesn't exist

def check_ai_client_doesnt_exist(install_client,install_mac,install_service)
  install_mac = install_mac.upcase
  message     = "Information:\tChecking client "+install_client+" doesn't exist"
  command     = "installadm list -p |grep '#{install_mac}'"
  output      = execute_command(message,command)
  if output.match(/#{install_client}/)
    handle_output("Warning:\tProfile already exists for #{install_client}")
    if $yes_to_all == 1
      handle_output("Deleting:\rtClient #{install_client}")
      unconfigure_ai_client(install_client,install_mac,install_service)
    else
      exit
    end
  end
  return
end

# Main code to actually add a client

def configure_ai_client(install_client,install_arch,install_mac,install_ip,install_model,publisher_host,install_service,
                        install_file,install_memory,install_cpu,install_network,install_license,install_mirror,install_type,install_vm)
  # Populate questions for AI profile
  if !install_service.match(/i386|sparc/)
    install_service = install_service+"_"+install_arch
  end
  check_ai_client_doesnt_exist(install_client,install_mac,install_service)
  populate_ai_client_profile_questions(install_ip,install_client)
  process_questions(install_service)
  if $os_name.match(/Darwin/)
    tftp_version_dir = $tftp_dir+"/"+install_service
    check_osx_iso_mount(tftp_version_dir,iso_file)
  end
  output_file = $work_dir+"/"+install_client+"_ai_profile.xml"
  create_ai_client_profile(output_file)
  handle_output("Configuring:\tClient #{install_client} with MAC address #{install_mac}")
  import_ai_client_profile(output_file,install_client,install_mac,install_service)
  create_ai_client(install_client,install_arch,install_mac,install_service,install_ip)
  if $os_name.match(/SunOS/) and $os_rel.match(/11/)
    clear_solaris_dhcpd()
  end
  return
end

# Unconfigure  AI client

def unconfigure_ai_client(install_client,install_mac,install_service)
  if !install_mac.match(/[a-z,A-Z,0-9]/) or !install_service.match(/[a-z,A-Z,0-9]/)
    repo_list            = %x[installadm list -p |grep -v '^-' |grep -v '^Service']
    temp_install_client  = ""
    temp_install_mac     = ""
    temp_install_service = ""
    repo_list.each do |line|
      line = line.chomp
      if line.match(/[a-z,A-Z,0-9]/)
        if line.match(/^[a-z,A-Z,0-9]/)
          line = line.gsub(/\s+/,"")
          temp_install_service = line
        else
          line = line.gsub(/\s+/,"")
          if line.match(/mac=/)
            (temp_install_client,temp_install_mac) = line.split(/mac=/)
            if temp_install_client.match(/^#{install_client}/)
              if !install_service.match(/[a-z,A-Z,0-9]/)
                install_service = temp_install_service
              end
              if !install_mac.match(/[a-z,A-Z,0-9]/)
                install_mac = temp_install_mac
              end
            end
          end
        end
      end
    end
  end
  if install_client.match(/[a-z,A-Z]/) and install_service.match(/[a-z,A-Z]/) and install_mac.match(/[a-z,A-Z]/)
    message = "Information:\tDeleting client profile "+install_client+" from "+install_service
    command = "installadm delete-profile -p #{install_client} -n #{install_service}"
    execute_command(message,command)
    message = "Information:\tDeleting client "+install_client+" with MAC address "+install_mac
    command = "installadm delete-client "+install_mac
    execute_command(message,command)
  else
    handle_output("Warning:\tClient #{install_client} does not exist")
    exit
  end
  return
end
