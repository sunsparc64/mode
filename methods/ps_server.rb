
# AutoYast routines

# Configure Preseed server

def configure_ps_server(install_arch,publisher_host,publisher_port,install_service,install_file)
  search_string = "ubuntu"
  configure_linux_server(install_arch,publisher_host,publisher_port,install_service,install_file,search_string)
  return
end

# List Preseed services

def list_ps_services()
  service_list = Dir.entries($repo_base_dir)
  service_list = service_list.grep(/ubuntu/)
  if service_list.length > 0
    handle_output("") 
    handle_output("Preseed services:")
    handle_output("")
  end
  service_list.each do |install_service|
    handle_output(install_service)
  end
  return
end

# Unconfigure Preseed server

def unconfigure_ps_server(install_service)
  unconfigure_ks_repo(install_service)
end
