# Code for AutoYast clients

# List AutoYest clients

def list_ay_clients()
  service_type = "AutoYast"
  list_clients(service_type)
  return
end

# Configure AutoYast client

def configure_ay_client(install_client,install_arch,install_mac,install_ip,install_model,publisher_host,install_service,
                        install_file,install_memory,install_cpu,install_network,install_license,install_mirror,install_type,install_vm)
  configure_ks_client(install_client,install_arch,install_mac,install_ip,install_model,publisher_host,install_service,
                      install_file,install_memory,install_cpu,install_network,install_license,install_mirror,install_type,install_vm)
  return
end

# Unconfigure AutoYast client

def unconfigure_ay_client(client_name,client_mac,service_name)
  unconfigure_ks_client(client_name,client_mac,service_name)
  return
end
