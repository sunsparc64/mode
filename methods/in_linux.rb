# Linux specific functions

# Process ISO file to get details

def get_linux_version_info(iso_file_name)
  iso_info = File.basename(iso_file_name)
  if iso_file_name.match(/purity/)
    iso_info     = iso_info.split(/_/)
  else
    iso_info     = iso_info.split(/-/)
  end
  linux_distro = iso_info[0]
  linux_distro = linux_distro.downcase
  if linux_distro.match(/^sle$/)
    linux_distro = "sles"
  end
  if linux_distro.match(/oraclelinux/)
    linux_distro = "oel"
  end
  if linux_distro.match(/centos|ubuntu|sles|sl|oel|rhel/)
    if linux_distro.match(/sles/)
      if iso_info[2].match(/Server/)
        iso_version = iso_info[1]+".0"
      else
        iso_version = iso_info[1]+"."+iso_info[2]
        iso_version = iso_version.gsub(/SP/,"")
      end
    else
      if linux_distro.match(/sl$/)
        iso_version = iso_info[1].split(//).join(".")
        if iso_version.length == 1
          iso_version = iso_version+".0"
        end
      else
        if linux_distro.match(/oel|rhel/)
          if iso_file_name =~ /-rc-/
            iso_version = iso_info[1..3].join(".")
            iso_version = iso_version.gsub(/server/,"")
          else
            iso_version = iso_info[1..2].join(".")
            iso_version = iso_version.gsub(/[a-z,A-Z]/,"")
          end
          iso_version = iso_version.gsub(/^\./,"")
        else
          iso_version = iso_info[1]
        end
      end
    end
    case iso_file_name
    when /i[3-6]86/
      iso_arch = "i386"
    when /x86_64/
      iso_arch = "x86_64"
    else
      if linux_distro.match(/centos|sl$/)
        iso_arch = iso_info[2]
      else
        if linux_distro.match(/sles|oel/)
          iso_arch = iso_info[4]
        else
          iso_arch = iso_info[3]
          iso_arch = iso_arch.split(/\./)[0]
          if iso_arch.match(/amd64/)
            iso_arch = "x86_64"
          else
            iso_arch = "i386"
          end
        end
      end
    end
  else
    if linux_distro.match(/fedora/)
      iso_version = iso_info[1]
      iso_arch    = iso_info[2]
    else
      if linux_distro.match(/purity/)
        iso_version = iso_info[1]
        iso_arch    = "x86_64"
      else
        if linux_distro.match(/vmware/)
          iso_version = iso_info[3].split(/\./)[0..-2].join(".")
          iso_update  = iso_info[3].split(/\./)[-1]
          iso_release = iso_info[4].split(/\./)[-3]
          iso_version = iso_version+"."+iso_update+"."+iso_release
          iso_arch    = "x86_64"
        else
          iso_version = iso_info[2]
          iso_arch    = iso_info[3]
        end
      end
    end
  end
  return linux_distro,iso_version,iso_arch
end

# List ISOs

def list_linux_isos(search_string,linux_type)
  iso_list      = check_iso_base_dir(search_string)
    iso_list      = check_iso_base_dir(search_string)
  if iso_list.length > 0
    if $output_format.match(/html/)
      handle_output("<h1>Available #{linux_type} ISOs:</h1>")
      handle_output("<table>")
      handle_output("<tr>")
      handle_output("<th>ISO File</th>")
      handle_output("<th>Distribution</th>")
      handle_output("<th>Version</th>")
      handle_output("<th>Architecture</th>")
      handle_output("<th>Service Name</th>")
      handle_output("</tr>")
    else
      handle_output("Available #{linux_type} ISOs:")
      handle_output("") 
    end
    iso_list.each do |iso_file_name|
      iso_file_name = iso_file_name.chomp
      (linux_distro,iso_version,iso_arch) = get_linux_version_info(iso_file_name)
      if $output_format.match(/html/)
        handle_output("<tr>")
        handle_output("<td>#{iso_file_name}</td>")
        handle_output("<td>#{linux_distro}</td>")
        handle_output("<td>#{iso_version}</td>")
        handle_output("<td>#{iso_arch}</td>")
      else
        handle_output("ISO file:\t#{iso_file_name}")
        handle_output("Distribution:\t#{linux_distro}")
        handle_output("Version:\t#{iso_version}")
        handle_output("Architecture:\t#{iso_arch}")
      end
      iso_version      = iso_version.gsub(/\./,"_")
      service_name     = linux_distro+"_"+iso_version+"_"+iso_arch
      repo_version_dir = $repo_base_dir+"/"+service_name
      if File.directory?(repo_version_dir)
        if $output_format.match(/html/)
          handle_output("<td>#{service_name} (exists)</td>")
        else
          handle_output("Service Name:\t#{service_name} (exists)")
        end
      else
        if $output_format.match(/html/)
          handle_output("<td>#{service_name}</td>")
        else
          handle_output("Service Name:\t#{service_name}")
        end
      end
      if $output_format.match(/html/)
        handle_output("</tr>")
      else
        handle_output("") 
      end
    end
    if $output_format.match(/html/)
      handle_output("</table>")
    end
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