
# Jumpstart server code

# Configure NFS service

def configure_js_nfs_service(install_service,publisher_host)
  repo_version_dir = $repo_base_dir+"/"+install_service
  if $os_name.match(/SunOS/)
    if $os_rel.match(/11/)
      check_fs_exists($client_base_dir)
      add_nfs_export(install_service,repo_version_dir,publisher_host)
      export_name = "client_configs"
      add_nfs_export(export_name,$client_base_dir,publisher_host)
    else
      check_dir_exists($client_base_dir)
      add_nfs_export(install_service,repo_version_dir,publisher_host)
      export_name = "client_configs"
      add_nfs_export(export_name,$client_base_dir,publisher_host)
    end
  else
    check_dir_exists($client_base_dir)
    add_nfs_export(install_service,repo_version_dir,publisher_host)
    export_name = "client_configs"
    add_nfs_export(export_name,$client_base_dir,publisher_host)
  end
  return
end

# Unconfigure NFS services

def unconfigure_js_nfs_service(install_service)
  repo_version_dir = $repo_base_dir+"/"+install_service
  remove_nfs_export(repo_version_dir)
end

# Configure tftpboot services

def configure_js_tftp_service(install_arch,install_service,repo_version_dir,os_version)
  boot_dir=$tftp_dir+"/"+install_service+"/boot"
  source_dir = repo_version_dir+"/boot"
  if $os_name.match(/SunOS/)
    if $os_rel.match(/11/)
      pkg_name = "system/boot/network"
      message  = "Information:\tChecking boot server package is installed"
      command  = "pkg info #{pkg_name} |grep Name |awk '{print $2}'"
      output   = execute_command(message,command)
      if !output.match(/#{pkg_name}/)
        message = "Information:\tInstalling boot server package"
        command = "pkg install #{pkg_name}"
        output  = execute_command(message,command)
      end
      old_tftp_dir="/tftpboot"
      if !File.symlink?($tftp_dir)
        message = "Information:\tSymlinking directory "+old_tftp_dir+" to "+$tftp_dir
        command = "ln -s #{old_tftp_dir} #{$tftp_dir}"
        output  = execute_command(message,command)
      end
      smf_install_service="svc:/network/tftp/udp6:default"
      message = "Information:\tChecking TFTP service is installed"
      command = "svcs -a |grep '#{smf_install_service}'"
      output  = execute_command(message,command)
      if !output.match(/#{smf_install_service}/)
        message = "Information:\tCreating TFTP service information"
        command = "echo 'tftp  dgram  udp6  wait  root  /usr/sbin/in.tftpd  in.tftpd -s /tftpboot' >> /tmp/tftp"
        output  = execute_command(message,command)
        message = "Information:\tCreating TFTP service manifest"
        command = "inetconv -i /tmp/tftp"
        output  = execute_command(message,command)
      end
      enable_smf_service(smf_install_service)
    end
  end
  if $os_name.match(/Darwin/)
    check_osx_tftpd()
  end
  if $os_name.match(/Linux/)
  end
  if !File.directory?(boot_dir)
    check_dir_exists(boot_dir)
    message = "Information:\tCopying boot files from "+source_dir+" to "+boot_dir
    command = "cp -r #{source_dir}/* #{boot_dir}"
    output  = execute_command(message,command)
  end
  return
end

# Unconfigure jumpstart tftpboot services

def unconfigure_js_tftp_service()
  return
end

# Copy SPARC boot images to /tftpboot

def copy_js_sparc_boot_images(repo_version_dir,os_version,os_update)
  boot_list=[]
  $tftp_dir="/tftpboot"
  boot_list.push("sun4u")
  if os_version == "10"
    boot_list.push("sun4v")
  end
  boot_list.each do |boot_arch|
    boot_file = repo_version_dir+"/Solaris_"+os_version+"/Tools/Boot/platform/"+boot_arch+"/inetboot"
    tftp_file = $tftp_dir+"/"+boot_arch+".inetboot.sol_"+os_version+"_"+os_update
    if !File.exist?(boot_file)
      message = "Information:\tCopying boot image "+boot_file+" to "+tftp_file
      command = "cp #{boot_file} #{tftp_file}"
      execute_command(message,command)
    end
  end
  return
end

# Unconfigure jumpstart repo

def unconfigure_js_repo(install_service)
  repo_version_dir = $repo_base_dir+"/"+install_service
  destroy_zfs_fs(repo_version_dir)
  return
end

# Configure Jumpstart repo

def configure_js_repo(iso_file,repo_version_dir,os_version,os_update)

  if $os_name.match(/SunOS|Linux/)
    check_fs_exists(repo_version_dir)
  else
    check_dir_exists(repo_version_dir)
  end
  check_dir = repo_version_dir+"/boot"
  if $verbose_mode == true
    handle_output("Checking:\tDirectory #{check_dir} exists")
  end
  if !File.directory?(check_dir)
    if $os_name.match(/SunOS/)
      mount_iso(iso_file)
      if iso_file.match(/sol\-10/)
        check_dir = $iso_mount_dir+"/boot"
      else
        check_dir = $iso_mount_dir+"/installer"
      end
      if $verbose_mode == true
        handle_output("Checking:\tDirectory #{check_dir} exists")
      end
      if File.directory?(check_dir) or File.exist?(check_dir)
        iso_update = get_js_iso_update($iso_mount_dir,os_version)
        if !iso_update.match(/#{os_update}/)
          handle_output("Warning:\tISO update version does not match ISO name")
          exit
        end
        message = "Information:\tCopying ISO file "+iso_file+" contents to "+repo_version_dir
        if $os_name.match(/SunOS/)
          if iso_file.match(/sol\-10/)
            command = "cd /cdrom/Solaris_#{os_version}/Tools ; ./setup_install_server #{repo_version_dir}"
          else
            ufs_file = iso_file.gsub(/\-ga\-/,"-s0-")
            if !File.exist?(ufs_file)
              dd_message = "Extracting VTOC from #{iso_file}" 
              dd_command = "dd if=#{iso_file} of=/tmp/vtoc bs=512 count=1"
              execute_command(dd_message,dd_command)
              dd_message = "Processing VTOC information for #{iso_file}"
              dd_command = "od -D -j 452 -N 8 < /tmp/vtoc |head -1"
              output     = execute_command(dd_message,dd_command)
              (header,start_block,no_blocks) = output.split(/\s+/)
              start_block = start_block.gsub(/^0/,"")
              start_block = start_block.to_i*640
              start_block = start_block.to_s
              no_blocks   = no_blocks(/^0/,"")
              dd_message = "Extracting UFS partition from #{iso_file} to #{ufs_file}"
              dd_command = "dd if=#{iso_info} of=#{ufs_file} bs=512 skip=#{start_block} count=#{no_blocks}"
              execute_command(dd_message,dd_command)
            end
            command = "(cd /cdrom ; tar -cpf - . ) | (cd #{repo_version_dir} ; tar -xpf - )"
          end
        else
          command = "(cd /cdrom ; tar -cpf - . ) | (cd #{repo_version_dir} ; tar -xpf - )"
        end
        execute_command(message,command)
      else
        handle_output("Warning:\tISO #{iso_file} is not mounted")
        return
      end
      umount_iso()
      if !iso_file.match(/sol\-10/)
        check_dir = repo_version_dir+"/boot"
        if !File.directory?(check_dir)
          message = "Mounting UFS partition from #{ufs_file}"
          command = "mount -F ufs -o ro #{ufs_file} /cdrom"
          execute_command(message,command)
          message = "Copying ISO file #{ufs_file} contents to #{repo_version_dir}"
          command = "(cd /cdrom ; tar -cpf - . ) | (cd #{repo_version_dir} ; tar -xpf - )"
          execute_command(message,command)
          message = "Unmounting #{ufs_file} from /cdrom"
          command = "umount /cdrom"
          execute_command(message,command)
        end
      end
    else
      if !File.directory?(check_dir)
        check_osx_iso_mount(repo_version_dir,iso_file)
      end
    end
  end
  return
end

# Fix rm_install_client script

def fix_js_rm_client(repo_version_dir,os_version)
  file_name   = "rm_install_client"
  rm_script   = repo_version_dir+"/Solaris_"+os_version+"/Tools/"+file_name
  backup_file = rm_script+".modest"
  if !File.exist?(backup_file)
    message = "Information:\tArchiving remove install script "+rm_script+" to "+backup_file
    command = "cp #{rm_script} #{backup_file}"
    execute_command(message,command)
    text = IO.readlines(rm_script)
    copy = []
    if text
      text.each do |line|
        if line.match(/ANS/) and line.match(/sed/) and !line.match(/\{/)
          line=line.gsub(/#/,' #')
        end
        if line.match(/nslookup/) and !line.match(/sed/)
          line="ANS=`nslookup ${K} | /bin/sed '/^;;/d' 2>&1`"
        end
        copy.push(line)
      end
    end
    File.open(rm_script,"w") {|file| file.puts copy}
  end
  return
end

# List Jumpstart services

def list_js_services()
  service_type    = "Jumpstart"
  service_command = "ls $repo_base_dir/ |egrep 'sol_6|sol_7|sol_8|sol_9|sol_10'"
  list_services(service_type,service_command) 
  return
end

# Fix check script

def fix_js_check(repo_version_dir,os_version)
  file_name    = "check"
  check_script = repo_version_dir+"/Solaris_"+os_version+"/Misc/jumpstart_sample/"+file_name
  backup_file  = check_script+".modest"
  if !File.exist?(backup_file)
    message = "Information:\tArchiving check script "+check_script+" to "+backup_file
    command = "cp #{check_script} #{backup_file}"
    execute_command(message,command)
    text     = File.read(check_script)
    copy     = text
    copy[0]  = "#!/usr/sbin/sh\n"
    tmp_file = "/tmp/check_script"
    File.open(tmp_file,"w") {|file| file.puts copy}
    message  = "Information:\tUpdating check script"
    command  = "cp #{tmp_file} #{check_script} ; chmod +x #{check_script} ; rm #{tmp_file}"
    execute_command(message,command)
  end
  return
end

# Unconfigure jumpstart server

def unconfigure_js_server(install_service)
  unconfigure_js_nfs_service(install_service)
  unconfigure_js_repo(install_service)
  unconfigure_js_tftp_service()
  return
end

# Configure jumpstart server

def configure_js_server(install_arch,publisher_host,publisher_port,install_service,iso_file)
  check_dhcpd_config(publisher_host)
  iso_list      = []
  search_string = "\\-ga\\-"
  if iso_file.match(/[a-z,A-Z]/)
    if File.exist?(iso_file)
      if !iso_file.match(/sol/)
        handle_output("Warning:\tISO #{iso_file} does not appear to be a valid Solaris distribution")
        exit
      else
        iso_list[0] = iso_file
      end
    else
      handle_output("Warning:\tISO file #{iso_file} does not exist")
    end
  else
    iso_list=check_iso_base_dir(search_string)
  end
  if iso_file.class == String
    iso_list[0] = iso_file
  end
  iso_list.each do |iso_file_name|
    iso_file_name = iso_file_name.chomp
    iso_info      = File.basename(iso_file_name)
    iso_info      = iso_info.split(/\-/)
    os_version    = iso_info[1]
    os_update     = iso_info[2]
    os_update     = os_update.gsub(/u/,"")
    os_arch       = iso_info[4]
    if !os_arch.match(/sparc/)
      if os_arch.match(/x86/)
        os_arch = "i386"
      else
        handle_output("Warning:\tCould not determine architecture from ISO name")
        exit
      end
    end
    install_service     = "sol_"+os_version+"_"+os_update+"_"+os_arch
    repo_version_dir = $repo_base_dir+"/"+install_service
    add_apache_alias(install_service)
    configure_js_repo(iso_file_name,repo_version_dir,os_version,os_update)
    configure_js_tftp_service(install_arch,install_service,repo_version_dir,os_version)
    configure_js_nfs_service(install_service,publisher_host)
    if os_arch.match(/sparc/)
      copy_js_sparc_boot_images(repo_version_dir,os_version,os_update)
    end
    if !$os_name.match(/Darwin/)
      fix_js_rm_client(repo_version_dir,os_version)
      fix_js_check(repo_version_dir,os_version)
    else
      tune_osx_nfs()
    end
  end
  return
end
