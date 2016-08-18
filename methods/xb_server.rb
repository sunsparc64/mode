# Server code for *BSD and other (e.g. CoreOS) PXE boot

# Configure BSD server

def configure_xb_server(install_client,publisher_host,publisher_port,install_service,iso_file)
  if install_service.match(/[a-z,A-Z]/)
    case install_service
    when /openbsd/
      search_string = "install"
    when /freebsd/
      search_string = "FreeBSD"
    when /coreos/
      search_string = "coreos"
    end
  else
    search_string = "install|FreeBSD|coreos"
  end
  configure_other_server(install_client,publisher_host,publisher_port,install_service,iso_file,search_string)
  return
end

# Copy Linux ISO contents to repo

def configure_xb_repo(iso_file,repo_version_dir,install_service)
  check_fs_exists(repo_version_dir)
  case install_service
  when /openbsd|freebsd/
    check_dir = repo_version_dir+"/etc"
  when /coreos/
    check_dir = repo_version_dir+"/coreos"
  end
  if $verbose_mode == 1
    handle_output("Checking:\tDirectory #{check_dir} exits")
  end
  if !File.directory?(check_dir)
    mount_iso(iso_file)
    copy_iso(iso_file,repo_version_dir)
    umount_iso()
  end
  return
end

# Configure PXE boot

def configure_xb_pxe_boot(iso_arch,iso_version,install_service,pxe_boot_dir,repo_version_dir)
  if install_service.match(/openbsd/)
    iso_arch = iso_arch.gsub(/x86_64/,"amd64")
    pxe_boot_file = pxe_boot_dir+"/"+iso_version+"/"+iso_arch+"/pxeboot"
    if !File.exist?(pxe_boot_file)
      pxe_boot_url = $openbsd_base_url+"/"+iso_version+"/"+iso_arch+"/pxeboot"
      wget_file(pxe_boot_url,pxe_boot_file)
    end
  end
  return
end

# Unconfigure BSD server

def unconfigure_xb_server(install_service)
  remove_apache_alias(install_service)
  pxe_boot_dir     = $tftp_dir+"/"+install_service
  repo_version_dir = $repo_base_dir+"/"+install_service
  destroy_zfs_fs(repo_version_dir)
  if File.symlink?(repo_version_dir)
    File.delete(repo_version_dir)
  end
  if File.directory?(pxe_boot_dir)
    Dir.rmdir(pxe_boot_dir)
  end
  return
end

# Configue BSD server

def configure_other_server(install_client,publisher_host,publisher_port,install_service,iso_file,search_string)
  iso_list = []
  check_dhcpd_config(publisher_host)
  if iso_file.match(/[a-z,A-Z]/)
    if File.exist?(iso_file)
      if !iso_file.match(/install|FreeBSD|coreos/)
        handle_output("Warning:\tISO #{iso_file} does not appear to be a valid distribution")
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
      (other_distro,iso_version,iso_arch) = get_other_version_info(iso_file_name)
      install_service = other_distro.downcase+"_"+iso_version.gsub(/\./,"_")+"_"+iso_arch
      pxe_boot_dir = $tftp_dir+"/"+install_service
      repo_version_dir  = $repo_base_dir+"/"+install_service
      add_apache_alias(install_service)
      configure_xb_repo(iso_file_name,repo_version_dir,install_service)
      configure_xb_pxe_boot(iso_arch,iso_version,install_service,pxe_boot_dir,repo_version_dir)
    end
  else
    if install_service.match(/[a-z,A-Z]/)
      if !install_client.match(/[a-z,A-Z]/)
        iso_info    = install_service.split(/_/)
        install_client = iso_info[-1]
      end
      add_apache_alias(install_service)
      configure_xb_pxe_boot(install_service,install_client)
    else
      handle_output("Warning:\tISO file and/or Service name not found")
      exit
    end
  end
  return
end

# List kickstart services

def list_xb_services()
  service_type    = "BSD"
  service_command = "ls #{$repo_base_dir}/ |egrep 'bsd|coreos'"
  list_service(service_type,service_command)
  return
end
