
# Server code for VSphere

# Unconfigure alternate packages

def unconfigure_vs_alt_repo(install_service)
  return
end

# Configure alternate packages

def configure_vs_alt_repo(install_service,install_arch)
  rpm_list = build_vs_alt_rpm_list(install_service)
  alt_dir  = $repo_base_dir+"/"+install_service+"/alt"
  check_dir_exists(alt_dir)
  rpm_list.each do |rpm_url|
    rpm_file = File.basename(rpm_url)
    rpm_file = alt_dir+"/"+rpm_file
    if !File.exists?(rpm_file)
      wget_file(rpm_url,rpm_file)
    end
  end
  return
end

# Unconfigure Linux repo

def unconfigure_vs_repo(install_service)
  remove_apache_alias(install_service)
  repo_version_dir = $repo_base_dir+"/"+install_service
  if $os_name.match(/SunOS/)
    if File.symlink?(repo_version_dir)
      message = "Information:\tRemoving symlink "+repo_version_dir
      command = "rm #{repo_version_dir}"
      execute_command(message,command)
    else
      destroy_zfs_fs(repo_version_dir)
    end
    netboot_repo_dir = $tftp_dir+"/"+install_service
    if File.directory?(netboot_repo_dir)
      message = "Information:\tRemoving directory "+netboot_repo_dir
      command = "rmdir #{netboot_repo_dir}"
      execute_command(message,command)
    end
  else
    if File.directory?(repo_version_dir)
      message = "Information:\tRemoving directory "+repo_version_dir
      command = "rm #{repo_version_dir}"
      execute_command(message,command)
    end
  end
  return
end

# Copy Linux ISO contents to

def configure_vs_repo(iso_file,repo_version_dir,install_service)
  if $os_name.match(/SunOS/)
    check_fs_exists(repo_version_dir)
    if !File.symlink?(netboot_repo_dir)
      File.symlink(repo_version_dir,netboot_repo_dir)
    end
  end
  if $os_name.match(/Linux/)
    netboot_repo_dir = $tftp_dir+"/"+install_service
    check_fs_exists(netboot_repo_dir)
    if !File.symlink?(repo_version_dir)
      File.symlink(netboot_repo_dir,repo_version_dir)
    end
  end
  check_dir = repo_version_dir+"/upgrade"
  if $verbose_mode == 1
    puts "Information:\tChecking directory "+check_dir+" exists"
  end
  if !File.directory?(check_dir)
    mount_iso(iso_file)
    repo_version_dir = $tftp_dir+"/"+install_service
    copy_iso(iso_file,repo_version_dir)
    umount_iso()
  end
  client_dir = $client_base_dir+"/"+install_service
  ovf_file   = client_dir+"/vmware-ovftools.tar.gz"
  if !File.exist(ovf_file)
    message = "Information:\tFetching "+$ovftool_tar_url+" to "+ovf_file
    command = "wget \"#{$ovftool_tar_url}\" -O #{ovf_file}"
    execute_command(message,command)
    if $os_info.match(/RedHat/) and $os_ver.match(/^7|^6\.7/)
      message = "Information:\tFixing permission on "+ovf_file
      command = "chcon -R -t httpd_sys_rw_content_t #{ovf_file}"
      execute_command(message,command)
    end
  end
  return
end

# Unconfigure VSphere server

def unconfigure_vs_server(install_service)
  unconfigure_vs_repo(install_service)
end

# Configure PXE boot

def configure_vs_pxe_boot(install_service)
  pxe_boot_dir = $tftp_dir+"/"+install_service
  test_dir     = pxe_boot_dir+"/usr"
  if !File.directory?(test_dir)
    rpm_dir = $work_dir+"/rpms"
    check_dir_exists(rpm_dir)
    if File.directory?(rpm_dir)
      message  = "Information:\tLocating syslinux package"
      command  = "ls #{rpm_dir} |grep 'syslinux-[0-9]'"
      output   = execute_command(message,command)
      rpm_file = output.chomp
      if !rpm_file.match(/syslinux/)
        rpm_file = "syslinux-4.02-7.2.el5.i386.rpm"
        rpm_file = rpm_dir+"/"+rpm_file
        rpm_url  = "http://mirror.centos.org/centos/5/os/i386/CentOS/syslinux-4.02-7.2.el5.i386.rpm"
        wget_file(rpm_url,rpm_file)
      else
        rpm_file = rpm_dir+"/"+rpm_file
      end
      check_dir_exists(pxe_boot_dir)
      message = "Information:\tCopying PXE boot files from "+rpm_file+" to "+pxe_boot_dir
      command = "cd #{pxe_boot_dir} ; #{$rpm2cpio_bin} #{rpm_file} | cpio -iud"
      output  = execute_command(message,command)
    else
      puts "Warning:\tSource directory "+rpm_dir+" does not exist"
      exit
    end
  end
  if !install_service.match(/vmware/)
    pxe_image_dir=pxe_boot_dir+"/images"
    if !File.directory?(pxe_image_dir)
      iso_image_dir = $repo_base_dir+"/"+install_service+"/images"
      message       = "Information:\tCopying PXE boot images from "+iso_image_dir+" to "+pxe_image_dir
      command       = "cp -r #{iso_image_dir} #{pxe_boot_dir}"
      output        = execute_command(message,command)
    end
  end
  pxe_cfg_dir = $tftp_dir+"/pxelinux.cfg"
  check_dir_exists(pxe_cfg_dir)
  return
end

# Unconfigure PXE boot

def unconfigure_vs_pxe_boot(install_service)
  return
end

# Configure VSphere server

def configure_vs_server(install_arch,publisher_host,publisher_port,install_service,iso_file)
  search_string = "VMvisor"
  iso_list      = []
  if iso_file.match(/[a-z,A-Z]/)
    if File.exists?(iso_file)
      if !iso_file.match(/VM/)
        puts "Warning:\tISO "+iso_file+" does not appear to be VMware distribution"
        exit
      else
        iso_list[0] = iso_file
      end
    else
      puts "Warning:\tISO file "+is_file+" does not exist"
    end
  else
    iso_list = check_iso_base_dir(search_string)
  end
  if iso_list[0]
    iso_list.each do |iso_file_name|
      iso_file_name    = iso_file_name.chomp
      iso_info         = File.basename(iso_file_name)
      iso_info         = iso_info.split(/-/)
      vs_distro        = iso_info[0]
      vs_distro        = vs_distro.downcase
      iso_version      = iso_info[3]
      iso_arch         = iso_info[4].split(/\./)[1]
      iso_version      = iso_version.gsub(/\./,"_")
      install_service     = vs_distro+"_"+iso_version+"_"+iso_arch
      repo_version_dir = $repo_base_dir+"/"+install_service
      add_apache_alias(install_service)
      configure_vs_repo(iso_file_name,repo_version_dir,install_service)
      configure_vs_pxe_boot(install_service)
    end
  else
    add_apache_alias(install_service)
    configure_vs_repo(iso_file,repo_version_dir)
    configure_vs_pxe_boot(install_service)
  end
  return
end

# List kickstart services

def list_vs_services()
  service_list = Dir.entries($repo_base_dir)
  service_list = service_list
  if service_list.length > 0
    puts
    puts "vSphere services:"
    puts
  end
  service_list.each do |install_service|
    if install_service.match(/vmware/)
      puts install_service
    end
  end
  return
end
