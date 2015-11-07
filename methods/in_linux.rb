# Linux specific functions

# List ISOs

def list_linux_isos(search_string)
  iso_list      = check_iso_base_dir(search_string)
  iso_list.each do |iso_file_name|
    iso_file_name = iso_file_name.chomp
    (linux_distro,iso_version,iso_arch) = get_linux_version_info(iso_file_name)
    puts "ISO file:\t"+iso_file_name
    puts "Distribution:\t"+linux_distro
    puts "Version:\t"+iso_version
    puts "Architecture:\t"+iso_arch
    iso_version      = iso_version.gsub(/\./,"_")
    service_name     = linux_distro+"_"+iso_version+"_"+iso_arch
    repo_version_dir = $repo_base_dir+"/"+service_name
    if File.directory?(repo_version_dir)
      puts "Service Name:\t"+service_name+" (exists)"
    else
      puts "Service Name:\t"+service_name
    end
    puts
  end
  return
end

# Stop Linux service

def stop_linux_service(service)
  message = "Information\tStopping Service "+service
  command = "service #{service} stop"
  output  = execute_command(message,command)
  return output
end

# Start Linux service

def start_linux_service(service)
  message = "Information\tStarting Service "+service
  command = "service #{service} start"
  output  = execute_command(message,command)
  return output
end

# Enable Linux service

def enable_linux_service(service)
  message = "Information\tEnabling Service "+service
  command = "chkconfig #{service} on"
  output  = execute_command(message,command)
  start_linux_service(service)
  return output
end

# Disable Linux service

def disable_linux_service(service)
  message = "Information\tDisabling Service "+service
  command = "chkconfig #{service} off"
  output  = execute_command(message,command)
  stop_linux_service(Service)
  return output
end

# Refresh OS X service

def refresh_linux_service(service_name)
  restart_service(service_name)
  return
end

# Restart Linux related services

def restart_linux_service(service)
  message = "Information:\tRestarting Service "+service
  command = "service #{service} restart"
  output  = execute_command(message,command)
  return output
end