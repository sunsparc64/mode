
# AutoYast routines

# Configure Preseed server

def configure_ps_server(client_arch,publisher_host,publisher_port,service_name,iso_file)
  search_string = "ubuntu"
  configure_linux_server(client_arch,publisher_host,publisher_port,service_name,iso_file,search_string)
  return
end

# List Preseed services

def list_ps_services()
  service_list = Dir.entries($repo_base_dir)
  service_list = service_list.grep(/ubuntu/)
  if service_list.length > 0
    puts
    puts "Preseed services:"
    puts
  end
  service_list.each do |service_name|
    puts service_name
  end
  return
end

# Unconfigure Preseed server

def unconfigure_ps_server(service_name)
  unconfigure_ks_repo(service_name)
end
