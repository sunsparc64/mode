
# AutoYast routines

# Configure Preseed server

def configure_ps_server(install_arch,publisher_host,publisher_port,install_service,install_file)
  search_string = "ubuntu"
  configure_linux_server(install_arch,publisher_host,publisher_port,install_service,install_file,search_string)
  return
end

# List Preseed services

def list_ps_services()
  service_type    = "Preseed"
  service_command = "ls $repo_base_dir/ |egrep 'ubuntu|debian'"
  list_services(service_type,service_command)
  return
end

# Unconfigure Preseed server

def unconfigure_ps_server(install_service)
  unconfigure_ks_repo(install_service)
end
