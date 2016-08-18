# Server related code for Linux related code

# List availabel images

def list_lxc_services()
  if $os_name.match(/Linux/)
    image_list = Dir.entries($lxc_image_dir)
    if image_list.length > 0
      if $output_format.match(/html/)
        handle_output("<h1>Available LXC service(s)</h1>")
        handle_output("<table border=\"1\">")
        handle_output("<tr>")
        handle_output("<th>Distribution</th>")
        handle_output("<th>Version</th>")
        handle_output("<th>Architecture</th>")
        handle_output("<th>Image File</th>")
        handle_output("<th>Service</th>")
        handle_output("</tr>")
      else
        handle_output("") 
        handle_output("Available LXC Images:")
        handle_output("") 
      end
      image_list.each do |image_name|
        if image_name.match(/tar/)
          image_file   = $lxc_image_dir+"/"+image_name
          image_info   = File.basename(image_name,".tar.gz")
          image_info   = image_info.split(/-/)
          image_os     = image_info[0]
          image_ver    = image_info[1]
          image_arch   = image_info[2]
          if $output_format.match(/html/)
            handle_output("<tr>")
            handle_output("<td>#{image_os.capitalize}</td>")
            handle_output("<td>#{image_ver}</td>")
            handle_output("<td><#{image_arch}/td>")
            handle_output("<td>#{image_file}</td>")
          else
            handle_output("Distribution:\t#{image_os.capitalize}")
            handle_output("Version:\t#{image_ver}")
            handle_output("Architecture:\t#{image_arch}")
            handle_output("Image File:\t#{image_file}")
          end
          if image_info[3]
            service_name = image_os.gsub(/ /,"")+"_"+image_ver.gsub(/\./,"_")+"_"+image_arch+"_"+image_info[3]
          else
            service_name = image_os.gsub(/ /,"")+"_"+image_ver.gsub(/\./,"_")+"_"+image_arch
          end
          if $output_format.match(/html/)
            handle_output("<td><#{service_name}</td>")
            handle_output("</tr>")
          else
            handle_output("Service Name:\t#{service_name}")
            handle_output("")
          end
        end
      end
    end
    if $output_format.match(/html/)
      handle_output("</table>")
    end
  end
  return
end

# Configure Ubunut LXC server

def configure_ubuntu_lxc_server(server_type)
  config_file  = "/etc/network/interfaces"
  if server_type.match(/public/)
    message = "Checking:\tLXC network configuration"
    command = "cat #{config_file} |grep 'bridge_ports eth0'"
    output  = execute_command(message,command)
    if !output.match(/bridge_ports/)
      tmp_file   = "/tmp/interfaces"
      server_ip  = $default_host
      gateway    = $q_struct["gateway"].value
      broadcast  = $q_struct["broadcast"].value
      network    = $q_struct["network_address"].value
      nameserver = $q_struct["nameserver"].value
      file = File.open(tmp_file,"w")
      file.write("# The loopback network interface\n")
      file.write("auto lo\n")
      file.write("iface lo inet loopback\n")
      file.write("\n")
      file.write("# The primary network interface\n")
      file.write("auto eth0\n")
      file.write("iface eth0 inet manual\n")
      file.write("\n")
      file.write("# LXC network\n")
      file.write("auto lxcbr0\n")
      file.write("iface lxcbr0 inet static\n")
      file.write("bridge_ports eth0\n")
      file.write("bridge_fd 0\n")
      file.write("bridge_stp off\n")
      file.write("bridge_waitport 0\n")
      file.write("bridge_maxwait 0\n")
      file.write("address #{server_ip}\n")
      file.write("gateway #{gateway}\n")
      file.write("netmask #{netmask}\n")
      file.write("network #{network}\n")
      file.write("broadcast #{broadcast}\n")
      file.write("dns-nameservers #{nameserver}\n")
      file.write("\n")
      file.close
      backup_file = config_file+".nolxc"
      message = "Information:\tArchiving network configuration file "+config_file+" to "+backup_file
      command = "cp #{config_file} #{backup_file}"
      execute_command(message,command)
      message = "Information:\tCreating network configuration file "+config_file
      command = "cp #{tmp_file} #{config_file} ; rm #{tmp_file}"
      execute_command(message,command)
      service = "networking"
      restart_service(service)
    end
  end
  return
end

# Configure LXC Server

def configure_lxc_server(server_type)
  service_name = ""
  populate_lxc_server_questions()
  process_questions(service_name)
  if $os_info.match(/Ubuntu/)
    configure_ubuntu_lxc_server(server_type)
  end
  check_lxc_install()
  return
end
