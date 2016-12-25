
# AutoYast routines

# List available SLES ISOs

def list_ay_isos()
  search_string = "SLE"
  linux_type    = "OpenSuSE or SuSE Enterprise Linux"
  list_linux_isos(search_string,linux_type)
  return
end

# Configure AutoYast server

def configure_ay_server(install_arch,publisherhost,publisherport,install_service,install_file)
  if install_service.match(/[a-z,A-Z]/)
    if install_service.downcase.match(/suse/)
      search_string = "SLE"
    end
  else
    search_string = "SLE"
  end
  configure_linux_server(install_arch,publisherhost,publisherport,install_service,install_file,search_string)
  return
end

# List AutoYast services

def list_ay_services()
  service_type    = "AutoYast"
  service_command = "ls #{$repo_base_dir}/ |grep 'sles'"
  list_services(service_type,service_command)
  return
end

# Unconfigure AutoYast server

def unconfigure_ay_server(install_service)
  unconfigure_ks_repo(install_service)
end
