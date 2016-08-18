
# Common routines for server and client configuration

# Question/config structure

Ai=Struct.new(:question, :ask, :value, :valid, :eval)

# Get the running repository version
# If running in test mode use a default version so client creation
# code can be tested

def get_ai_repo_version(publisher_url,publisher_host,publisher_port)
  publisher_url = get_ai_publisher_url(publisher_host,publisher_port)
  if $test_mode == 1 or $os_name.match(/Darwin/)
  repo_version  = "0.175.1"
  else
    message      = "Information:\tDetermining if available repository version from "+publisher_url
    command      = "pkg info -g #{publisher_url} entire |grep Branch |awk '{print $2}'"
    repo_version = execute_command(message,command)
    repo_version = repo_version.chomp
    repo_version = repo_version.split(/\./)[0..2].join(".")
  end
  return repo_version
end

# Check the publisher port isn't being used

def check_publisher_port(publisher_port)
  message      = "Information:\tDetermining if publisher port "+publisher_port+" is in use"
  command      = "svcprop -a pkg/server |grep 'port count'"
  ports_in_use = execute_command(message,command)
  if ports_in_use.match(/#{publisher_port}/)
    if $verbose_mode == 1
      handle_output("Warning:\tPublisher port #{publisher_port} is in use")
      handle_output("Information:\tFinding free publisher port")
    end
  end
  while ports_in_use.match(/#{publisher_port}/)
    publisher_port = publisher_port.to_i+1
    publisher_port = publisher_port.to_s
  end
  if $verbose_mode == 1
    handle_output("Setting:\tPublisher port to #{publisher_port}")
  end
  return publisher_port
end

# Get publisher port for service

def get_publisher_port(install_service)
  message     = "Information:\tDetermining publisher port for service "+install_service
  command     = "svcprop -a pkg/server |grep 'port count'"
  port_in_use = execute_command(message,command)
  return port_in_use
end

# Get the repository URL

def get_ai_repo_url(publisher_url,publisher_host,publisher_port)
  repo_version = get_ai_repo_version(publisher_url,publisher_host,publisher_port)
  repo_url     = "pkg:/entire@0.5.11-"+repo_version
  return repo_url
end

# Get the publisher URL
# If running in test mode use the default Oracle one

def get_ai_publisher_url(publisher_host,publisher_port)
  publisher_url = "http://"+publisher_host+":"+publisher_port
  return publisher_url
end

# Get alternate publisher url

def get_ai_alt_publisher_url(publisher_host,publisher_port)
  publisher_port = publisher_port.to_i+1
  publisher_port = publisher_port.to_s
  publisher_url  = "http://"+publisher_host+":"+publisher_port
  return publisher_url
end

# Get service base name

def get_ai_service_base_name(install_service)
  service_base_name = install_service
  if service_base_name.match(/i386|sparc/)
    service_base_name = service_base_name.gsub(/i386/,"")
    service_base_name = service_base_name.gsub(/sparc/,"")
    service_base_name = service_base_name.gsub(/_$/,"")
  end
  return service_base_name
end

# Configure a package repository

def configure_ai_pkg_repo(publisher_host,publisher_port,install_service,repo_version_dir,read_only)
  if $os_name.match(/SunOS/)
    smf_name = "pkg/server:#{install_service}"
    message  = "Information:\tChecking if service "+smf_name+" exists"
    if install_service.match(/alt/)
      command = "svcs -a |grep '#{smf_name}"
    else
      command = "svcs -a |grep '#{smf_name} |grep -v alt"
    end
    output = execute_command(message,command)
    if !output.match(/#{smf_name}/)
      message  = ""
      commands = []
      commands.push("svccfg -s pkg/server add #{install_service}")
      commands.push("svccfg -s #{smf_name} addpg pkg application")
      commands.push("svccfg -s #{smf_name} setprop pkg/port=#{publisher_port}")
      commands.push("svccfg -s #{smf_name} setprop pkg/inst_root=#{repo_version_dir}")
      commands.push("svccfg -s #{smf_name} addpg general framework")
      commands.push("svccfg -s #{smf_name} addpropvalue general/complete astring: #{install_service}")
      commands.push("svccfg -s #{smf_name} setprop pkg/readonly=#{read_only}")
      commands.push("svccfg -s #{smf_name} setprop pkg/proxy_base = astring: http://#{publisher_host}/#{install_service}")
      commands.push("svccfg -s #{smf_name} addpropvalue general/enabled boolean: true")
      commands.each do |temp_command|
        execute_command(message,temp_command)
      end
      refresh_smf_service(smf_name)
      add_apache_proxy(publisher_host,publisher_port,install_service)
    end
  end
  return
end

# Delete a package repository

def unconfigure_ai_pkg_repo(smf_install_service)
  install_service = smf_install_service.split(":")[1]
  if $os_name.match(/SunOS/)
    message  = "Information:\tChecking if repository service "+smf_install_service+" exists"
    if smf_install_service.match(/alt/)
      command  = "svcs -a |grep '#{smf_install_service}'"
    else
      command  = "svcs -a |grep '#{smf_install_service}' |grep -v alt"
    end
    output   = execute_command(message,command)
    if output.match(/#{smf_install_service}/)
      disable_smf_service(smf_install_service)
      message = "Removing\tPackage repository service "+smf_install_service
      command = "svccfg -s pkg/server delete #{smf_install_service}"
      execute_command(message,command)
      remove_apache_proxy(install_service)
    end
  end
  return
end

# List available ISOs

def list_ai_isos()
  search_string = "sol-11"
  iso_list      = check_iso_base_dir(search_string)
  if iso_list.length > 0
    if $output_format.match(/html/)
      handle_output("<h1>Available AI ISOs:</h1>")
      handle_output("<table border=\"1\">")
      handle_output("<tr>")
      handle_output("<th>ISO file</th>")
      handle_output("<th>Distribution</th>")
      handle_output("<th>Version</th>")
      handle_output("<th>Architecture</th>")
      handle_output("<th>Service Name</th>")
      handle_output("</tr>")
    else
      handle_output("Available AI ISOs:")
    end
    handle_output("")
    iso_list.each do |iso_file|
      iso_file = iso_file.chomp
      iso_info = File.basename(iso_file,".iso")
      iso_info = iso_info.split(/-/)
      iso_arch = iso_info[3]
      if iso_file.match(/beta/)
        iso_version = iso_info[1]+"_beta"
      else
        iso_version = iso_info[1]
      end
      install_service  = "sol_"+iso_version
      repo_version_dir = $repo_base_dir+"/"+install_service
      if $output_format.match(/html/)
        handle_output("<tr>")
        handle_output("<td>#{iso_file}</td>")
        handle_output("<td>Solaris 11</td>")
        handle_output("<td>#{iso_version.gsub(/_/,'.')}</td>")
        if iso_file.match(/repo/)
          handle_output("<td>sparc and x86</td>")
        else
          handle_output("<td>#{iso_arch}</td>")
        end
        if File.directory?(repo_version_dir)
          handle_output("<td>#{install_service} (exists)</td>")
        else
          handle_output("<td>#{install_service}</td>")
        end
        handle_output("</tr>")
      else
        handle_output("ISO file:\t#{iso_file}")
        handle_output("Distribution:\tSolaris 11")
        handle_output("Version:\t#{iso_version.gsub(/_/,'.')}")
        if iso_file.match(/repo/)
          handle_output("Architecture:\tsparc and x86")
        else
          handle_output("Architecture:\t#{iso_arch}")
        end
        if File.directory?(repo_version_dir)
          handle_output("Service Name:\t#{install_service} (exists)")
        else
          handle_output("Service Name:\t#{install_service}")
        end
        handle_output("")
      end
    end
    if $output_format.match(/html/)
      handle_output("</table>")
    end
  end
  return
end
