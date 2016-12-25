
# Server code for Kickstart

# Unconfigure alternate packages

def unconfigure_ks_alt_repo(install_service)
  return
end

# Configure alternate packages

def configure_ks_alt_repo(install_service,install_arch)
  rpm_list = build_ks_alt_rpm_list(install_service)
  alt_dir  = $repo_base_dir+"/"+install_service+"/alt"
  check_dir_exists(alt_dir)
  rpm_list.each do |rpm_url|
    rpm_file = File.basename(rpm_url)
    rpm_file = alt_dir+"/"+rpm_file
    if !File.exist?(rpm_file)
      wget_file(rpm_url,rpm_file)
    end
  end
  return
end

# Unconfigure Linux repo

def unconfigure_ks_repo(install_service)
  remove_apache_alias(install_service)
  repo_version_dir = $repo_base_dir+"/"+install_service
  if File.symlink?(repo_version_dir)
    netboot_repo_dir = $tftp_dir+"/"+install_service
    destroy_zfs_fs(netboot_repo_dir)
    File.delete(repo_version_dir)
  else
    destroy_zfs_fs(repo_version_dir)
  end
  return
end

# Set ZFS mount point for filesystem

def set_zfs_mount(repo_version_dir,netboot_repo_dir)
  zfs_name = $default_zpool+repo_version_dir
  message  = "Information:\tSetting "+zfs_name+" mount point to "+repo_version_dir
  command  = "zfs set mountpoint=#{netboot_repo_dir} #{zfs_name}"
  execute_command(message,command)
  return
end

# Copy Linux ISO contents to repo

def configure_ks_repo(install_service,iso_file,repo_version_dir)
  netboot_repo_dir = $tftp_dir+"/"+install_service
  if $os_name.match(/SunOS/)
    if $os_ver.to_i < 11
      check_fs_exists(repo_version_dir)
      if !File.symlink?(netboot_repo_dir)
        File.symlink(repo_version_dir,netboot_repo_dir)
      end
    else
      check_fs_exists(repo_version_dir)
      set_zfs_mount(repo_version_dir,netboot_repo_dir)
      if !File.symlink?(repo_version_dir)
        Dir.delete(repo_version_dir)
        File.symlink(netboot_repo_dir,repo_version_dir)
      end
    end
  end
  if $os_name.match(/Linux/)
    check_fs_exists(netboot_repo_dir)
    if !File.symlink?(repo_version_dir)
      File.symlink(netboot_repo_dir,repo_version_dir)
    end
  end
  if repo_version_dir.match(/sles/)
    check_dir = repo_version_dir+"/boot"
  else
    check_dir = repo_version_dir+"/isolinux"
  end
  if $verbose_mode == true
    handle_output("Information:\tChecking directory #{check_dir} exits")
  end
  if !File.directory?(check_dir)
    mount_iso(iso_file)
    copy_iso(iso_file,repo_version_dir)
    umount_iso()
    if iso_file.match(/DVD1\.iso|1of2\.iso/)
      if iso_file.match(/DVD1/)
        iso_file = iso_file.gsub(/1\.iso/,"2.iso")
      end
      if iso_file.match(/1of2/)
        iso_file = iso_file.gsub(/1of2\.iso/,"2of2.iso")
      end
      mount_iso(iso_file)
      copy_iso(iso_file,repo_version_dir)
      umount_iso()
    end
  end
  return
end

# Unconfigure Kickstart server

def unconfigure_ks_server(install_service)
  unconfigure_ks_repo(install_service)
end

# Configure PXE boot

def configure_ks_pxe_boot(install_service,iso_arch)
  pxe_boot_dir = $tftp_dir+"/"+install_service
  if install_service.match(/centos|rhel|fedora|sles|sl_|oel/)
    test_dir     = pxe_boot_dir+"/usr"
    if !File.directory?(test_dir)
      if install_service.match(/centos/)
        rpm_dir = $repo_base_dir+"/"+install_service+"/CentOS"
        if !File.directory?(rpm_dir)
          rpm_dir = $repo_base_dir+"/"+install_service+"/Packages"
        end
      end
      if install_service.match(/sles/)
        rpm_dir = $repo_base_dir+"/"+install_service+"/suse"
      end
      if install_service.match(/sl_/)
        rpm_dir = $repo_base_dir+"/"+install_service+"/Scientific"
        if !File.directory?(rpm_dir)
          rpm_dir = $repo_base_dir+"/"+install_service+"/Packages"
        end
      end
      if install_service.match(/oel|rhel|fedora/)
        if install_service.match(/rhel_5/)
          rpm_dir = $repo_base_dir+"/"+install_service+"/Server"
        else
          rpm_dir = $repo_base_dir+"/"+install_service+"/Packages"
        end
      end
      if File.directory?(rpm_dir)
        if !install_service.match(/sl_|fedora_19|rhel_6/)
          message  = "Information:\tLocating syslinux package"
          command  = "cd #{rpm_dir} ; find . -name 'syslinux-[0-9]*' |grep '#{iso_arch}'"
          output   = execute_command(message,command)
          rpm_file = output.chomp
          rpm_file = rpm_file.gsub(/\.\//,"")
          rpm_file = rpm_dir+"/"+rpm_file
          check_dir_exists(pxe_boot_dir)
        else
          rpm_dir  = $work_dir+"/rpm"
          if !File.directory?(rpm_dir)
            check_dir_exists(rpm_dir)
          end
          rpm_url  = "http://"+$local_ubuntu_mirror+"/pub/centos/5/os/i386/CentOS/syslinux-4.02-7.2.el5.i386.rpm"
          rpm_file = rpm_dir+"/syslinux-4.02-7.2.el5.i386.rpm"
          if !File.exist?(rpm_file)
            wget_file(rpm_url,rpm_file)
          end
        end
        check_dir_exists(pxe_boot_dir)
        message = "Information:\tCopying PXE boot files from "+rpm_file+" to "+pxe_boot_dir
        command = "cd #{pxe_boot_dir} ; #{$rpm2cpio_bin} #{rpm_file} | cpio -iud"
        output  = execute_command(message,command)
        if $os_info.match(/RedHat/) and $os_rel.match(/^7/) and pxe_boot_dir.match(/[a-z]/)
          httpd_p = "httpd_sys_rw_content_t"
          tftpd_p = "unconfined_u:object_r:system_conf_t:s0"
          message = "Information:\tFixing permissions on "+pxe_boot_dir
          command = "chcon -R -t #{httpd_p} #{pxe_boot_dir} ; chcon #{tftpd_p} #{pxe_boot_dir}"
          execute_command(message,command)
          message = "Information:\tFixing permissions on "+pxe_boot_dir+"/usr and "+pxe_boot_dir+"/images"
          command = "chcon -R #{pxe_boot_dir}/usr ; chcon -R #{pxe_boot_dir}/images"
          execute_command(message,command)
        end
      else
        handle_output("Warning:\tSource directory #{rpm_dir} does not exist")
        exit
      end
    end
    if install_service.match(/sles/)
      pxe_image_dir=pxe_boot_dir+"/boot"
    else
      pxe_image_dir=pxe_boot_dir+"/images"
    end
    if !File.directory?(pxe_image_dir)
      if install_service.match(/sles/)
        iso_image_dir = $repo_base_dir+"/"+install_service+"/boot"
      else
        iso_image_dir = $repo_base_dir+"/"+install_service+"/images"
      end
      message       = "Information:\tCopying PXE boot images from "+iso_image_dir+" to "+pxe_image_dir
      command       = "cp -r #{iso_image_dir} #{pxe_boot_dir}"
      output        = execute_command(message,command)
    end
  else
    check_dir_exists(pxe_boot_dir)
    pxe_image_dir = pxe_boot_dir+"/images"
    check_dir_exists(pxe_image_dir)
    pxe_image_dir = pxe_boot_dir+"/images/pxeboot"
    check_dir_exists(pxe_image_dir)
    test_file = pxe_image_dir+"/vmlinuz"
    if install_service.match(/ubuntu/)
      iso_image_dir = $repo_base_dir+"/"+install_service+"/install"
    else
      iso_image_dir = $repo_base_dir+"/"+install_service+"/isolinux"
    end
    if !File.exist?(test_file)
      message = "Information:\tCopying PXE boot files from "+iso_image_dir+" to "+pxe_image_dir
      command = "cd #{pxe_image_dir} ; cp -r #{iso_image_dir}/* . "
      output  = execute_command(message,command)
    end
  end
  pxe_cfg_dir = $tftp_dir+"/pxelinux.cfg"
  check_dir_exists(pxe_cfg_dir)
  return
end

# Unconfigure PXE boot

def unconfigure_ks_pxe_boot(install_service)
  return
end

# Configure Kickstart server

def configure_ks_server(install_arch,publisherhost,publisherport,install_service,iso_file)
  if install_service.match(/[a-z,A-Z]/)
    if install_service.downcase.match(/centos/)
      search_string = "CentOS"
    end
    if install_service.downcase.match(/redhat/)
      search_string = "rhel"
    end
    if install_service.downcase.match(/scientific|sl_/)
      search_string = "sl"
    end
    if install_service.downcase.match(/oel/)
      search_string = "OracleLinux"
    end
  else
    search_string = "CentOS|rhel|SL|OracleLinux|Fedora"
  end
  configure_linux_server(install_arch,publisherhost,publisherport,install_service,iso_file,search_string)
  return
end

# Configure local VMware repo

def configure_ks_vmware_repo(install_service,install_arch)
  vmware_dir   = $pkg_base_dir+"/vmware"
  add_apache_alias(vmware_dir)
  repodata_dir = vmware_dir+"/repodata"
  vmware_url   = "http://packages.vmware.com/tools/esx/latest"
  if install_service.match(/centos_5|rhel_5|sl_5|oel_5|fedora_18/)
    vmware_url   = vmware_url+"/rhel5/"+install_arch+"/"
    repodata_url = vmware_url+"repodata/"
  end
  if install_service.match(/centos_6|rhel_[6,7]|sl_6|oel_6|fedora_[19,20]/)
    vmware_url   = vmware_url+"/rhel6/"+install_arch+"/"
    repodata_url = vmware_url+"repodata/"
  end
  if $download_mode == true
    if !File.directory?(vmware_dir)
      check_dir_exists(vmware_dir)
      message = "Information:\tFetching VMware RPMs"
      command = "cd #{vmware_dir} ; lftp -e 'mget * ; quit' #{vmware_url}"
      execute_command(message,command)
      check_dir_exists(repodata_dir)
      message = "Information:\tFetching VMware RPM repodata"
      command = "cd #{repodata_dir} ; lftp -e 'mget * ; quit' #{repodata_url}"
      execute_command(message,command)
    end
  end
  return
end

# Configure local Puppet repo

def configure_ks_puppet_repo(install_service,iso_arch)
  puppet_rpm_list = {}
  puppet_base_dir = $pkg_base_dir+"/puppet"
  puppet_rpm_list["products"]     = []
  puppet_rpm_list["dependencies"] = []
  puppet_rpm_list["products"].push("facter")
  puppet_rpm_list["products"].push("hiera")
  puppet_rpm_list["products"].push("puppet")
  puppet_rpm_list["dependencies"].push("ruby-augeas")
  puppet_rpm_list["dependencies"].push("ruby-json")
  puppet_rpm_list["dependencies"].push("ruby-shadow")
  puppet_rpm_list["dependencies"].push("ruby-rgen")
  puppet_rpm_list["dependencies"].push("libselinux-ruby")
  check_fs_exists(puppet_base_dir)
  add_apache_alias(puppet_base_dir)
  rpm_list   = populate_puppet_rpm_list(install_service,iso_arch)
  if !File.directory?(puppet_base_dir)
    check_dir_exists(puppet_base_dir)
  end
  release    = install_service.split(/_/)[1]
  [ "products", "dependencies" ].each do |remote_dir|
    puppet_rpm_list[remote_dir].each do |pkg_name|
      if pkg_name.match(/libselinux-ruby/)
        remote_url = $puppet_rpm_base_url+"/el/"+release+"/"+remote_dir+"/"+iso_arch+"/"
      else
        remote_url = $centos_rpm_base_url+"/"+release+"/os/"+iso_arch+"/Packages/"
      end
      rpm_urls = Nokogiri::HTML.parse(remote_url).css('td a')
      pkg_file = rpm_urls.grep(/^#{pkg_name}-[0-9]/)[-1]
      if pkg_file.to_s.match(/href/)
        pkg_file   = URI.parse(pkg_file).to_s
        pkg_url    = puppet_rpm_url+pkg_file
        local_file = puppet_local_dir+"/"+pkg_file
        if !File.exist?(local_file) or File.size(local_file) == 0
          if $verbose_mode == true
            handle_output("Fetching #{pkg_url} to #{local_file}")
          end
          agent = Mechanize.new
          agent.redirect_ok = true
          agent.pluggable_parser.default = Mechanize::Download
          agent.get(pkg_url).save(local_file)
        end
      end
    end
  end
  return
end

# Configue Linux server

def configure_linux_server(install_arch,publisherhost,publisherport,install_service,iso_file,search_string)
  iso_list = []
  check_fs_exists($client_base_dir)
  check_dhcpd_config(publisherhost)
  if iso_file.match(/[a-z,A-Z]/)
    if File.exist?(iso_file)
      if !iso_file.match(/CentOS|rhel|Fedora|SL|OracleLinux|ubuntu/)
        handle_output("Warning:\tISO #{iso_file} does not appear to be a valid Linux distribution")
        exit
      else
        iso_list[0] = iso_file
      end
    else
      handle_output("Warning:\tISO file #{iso_file} does not exist")
    end
  else
    iso_list = check_iso_base_dir(search_string)
  end
  if iso_list[0]
    iso_list.each do |iso_file_name|
      iso_file_name = iso_file_name.chomp
      (linux_distro,iso_version,iso_arch) = get_linux_version_info(iso_file_name)
      iso_version  = iso_version.gsub(/\./,"_")
      install_service = linux_distro+"_"+iso_version+"_"+iso_arch
      repo_version_dir  = $repo_base_dir+"/"+install_service
      if !iso_file_name.match(/DVD2\.iso|2of2\.iso/)
        add_apache_alias(install_service)
        configure_ks_repo(install_service,iso_file_name,repo_version_dir)
        configure_ks_pxe_boot(install_service,iso_arch)
        if install_service.match(/centos|fedora|rhel|sl_|oel/)
          configure_ks_vmware_repo(install_service,iso_arch)
        end
        if !install_service.match(/ubuntu|sles/)
          if $default_options.match(/puppet/)
            configure_ks_puppet_repo(install_service,iso_arch)
          end
        end
      else
        mount_iso(iso_file)
        copy_iso(iso_file,repo_version_dir)
        umount_iso()
      end
    end
  else
    if install_service.match(/[a-z,A-Z]/)
      if !install_arch.match(/[a-z,A-Z]/)
        iso_info    = install_service.split(/_/)
        install_arch = iso_info[-1]
      end
      add_apache_alias(install_service)
      configure_ks_pxe_boot(install_service,install_arch)
      if install_service.match(/centos|fedora|rhel|sl_|oel/)
        configure_ks_vmware_repo(install_service,install_arch)
      end
      if !install_service.match(/ubuntu|sles/)
        if $default_options.match(/puppet/)
          configure_ks_puppet_repo(install_service,install_arch)
        end
      end
    else
      handle_output("Warning:\tISO file and/or Service name not found")
      exit
    end
  end
  return
end

# List kickstart services

def list_ks_services()
  service_type    = "Kickstart"
  service_command = "ls $repo_base_dir/ |egrep 'centos|fedora|rhel|sl_|oel'"
  list_services(service_type,service_command)
  return
end
