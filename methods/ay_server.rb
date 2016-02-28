
# AutoYast routines

# List available SLES ISOs

def list_ay_isos()
  search_string = "SLES"
  list_linux_isos(search_string)
  return
end

# Configure AutoYast server

def configure_ay_server(client_arch,publisher_host,publisher_port,service_name,iso_file)
  if service_name.match(/[a-z,A-Z]/)
    if service_name.downcase.match(/suse/)
      search_string = "SLES"
    end
  else
    search_string = "SLES"
  end
  configure_linux_server(client_arch,publisher_host,publisher_port,service_name,iso_file,search_string)
  return
end

# List AutoYast services

def list_ay_services()
  service_list = Dir.entries($repo_base_dir)
  service_list = service_list.grep(/sles/)
  if service_list.length > 0
    puts
    puts "AutoYast services:"
    puts
  end
  service_list.each do |service_name|
    puts service_name
  end
  return
end

# Unconfigure AutoYast server

def unconfigure_ay_server(service_name)
  unconfigure_ks_repo(service_name)
end
