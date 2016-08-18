# MAAS serer related functions

# Configure MAAS server components

def configure_maas_server()
  maas_url = "http://"+$default_host+"/MAAS/"
  if $os_info.match(/Ubuntu/)
    message = "Information:\tChecking installation status of MAAS"
    command = "dpkg -l maas"
    output  = execute_command(message,command)
    if output.match(/no packages found/)
      message = "Information:\tGetting Ubuntu release information"
      command = "lsb_release -c"
      output  = execute_command(message,command)
      if output.match(/precise/)
        message = "Information:\tEnabling APT Repository - Cloud Archive"
        command = "echo '' |add-apt-repository cloud-archive:tool"
        execute_command(message,command)
      end
      message = "Information:\tInstalling MAAS"
      command = "echo '' |apt-get install -y apt-get install maas dnsmasq debmirror"
      execute_command(message,command)
      service = "apache"
      restart_service(service)
      service = "avahi-daemon"
      restart_service(service)
      message = "Information:\tCreating MAAS Admin"
      command = "maas createadmin --username=#{$default_maas_admin} --email=#{$default_maas_email} --password=#{$default_mass_password}"
      execute_command(message,command)
      handle_output("") 
      handle_output("Information:\tLog into #{maas_url} and continue configuration")
      handle_output("") 
    end
  else
    handle_output("Warning:\tMAAS is only supported on Ubuntu LTS")
    exit
  end
  return
end
