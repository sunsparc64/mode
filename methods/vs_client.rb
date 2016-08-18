
# VSphere client routines

def get_vs_clients()
  client_list  = []
  service_list = Dir.entries($repo_base_dir)
  service_list.each do |install_service|
    if install_service.match(/vmware/)
      repo_version_dir = $repo_base_dir+"/"+install_service
      file_list        = Dir.entries(repo_version_dir)
      file_list.each do |file_name|
        if file_name.match(/\.cfg$/) and !file_name.match(/boot\.cfg|isolinux\.cfg/)
          install_client = file_name.split(/\./)[0]
          client_info = install_client+" service = "+install_service
          client_list.push(client_info)
        end
      end
    end
  end
  return client_list
end

# List ks clients

def list_vs_clients()
  client_list = get_vs_clients()
  if client_list.length > 0
    if $output_format.match(/html/)
      handle_output("<h1>Available vSphere clients:</h1>") 
      handle_output("<table>")
      handle_output("<tr>")
      handle_output("<th>Client</th>")
      handle_output("<th>Service</th>")
      handle_output("</tr>")
    else
      handle_output("")
      handle_output("Available vSphere clients:")
      handle_output("")
    end
    client_list.each do |client_info|
      if $output_format.match(/html/)
        (install_client,install_service) = client_info.split(/ service = /)
        handle_output("<tr>")
        handle_output("<td>#{install_client}</td>")
        handle_output("<td>#{install_service}</td>")
        handle_output("</tr>")
      else
        handle_output(client_info)
      end
    end
    if $output_format.match(/html/)
      handle_output("</table>")
    else
      handle_output("")
    end
  end
  return
end

# Configure client PXE boot

def configure_vs_pxe_client(install_client,install_mac,install_service)
  tftp_pxe_file  = install_mac.gsub(/:/,"")
  tftp_pxe_file  = tftp_pxe_file.upcase
  tftp_boot_file = "boot.cfg.01"+tftp_pxe_file
  tftp_pxe_file  = "01"+tftp_pxe_file+".pxelinux"
  test_file      = $tftp_dir+"/"+tftp_pxe_file
  if !File.exists?(test_file)
    pxelinux_file = install_service+"/usr/share/syslinux/pxelinux.0"
    message       = "Information:\tCreating PXE boot file for "+install_client+" with MAC address "+install_mac
    command       = "cd #{$tftp_dir} ; ln -s #{pxelinux_file} #{tftp_pxe_file}"
    execute_command(message,command)
  end
  pxe_cfg_dir  = $tftp_dir+"/pxelinux.cfg"
  pxe_cfg_file = install_mac.gsub(/:/,"-")
  pxe_cfg_file = "01-"+pxe_cfg_file
  pxe_cfg_file = pxe_cfg_file.downcase
  pxe_cfg_file = pxe_cfg_dir+"/"+pxe_cfg_file
  #ks_url       = "http://"+$default_host+"/"+install_service+"/"+install_client+".cfg"
  ks_url       = "http://"+$default_host+"/clients/"+install_service+"/"+install_client+"/"+install_client+".cfg"
  mboot_file   = "/"+install_service+"/mboot.c32"
  if $verbose_mode == 1
    handle_output("Information:\tCreating Menu config file #{pxe_cfg_file}")
  end
  file = File.open(pxe_cfg_file,"w")
  if $serial_mode == 1
    file.write("serial 0 115200\n")
  end
  file.write("DEFAULT ESX\n")
  file.write("LABEL ESX\n")
  file.write("KERNEL #{mboot_file}\n")
  if $text_mode == 1
    if $serial_mode == 1
      file.write("APPEND -c #{tftp_boot_file} text gdbPort=none logPort=none tty2Port=com1 ks=#{ks_url} +++\n")
    else
      file.write("APPEND -c #{tftp_boot_file} text ks=#{ks_url} +++\n")
    end
  else
    file.write("APPEND -c #{tftp_boot_file} ks=#{ks_url} +++\n")
  end
  file.write("IPAPPEND 1\n")
  file.close
  if $verbose_mode == 1
    handle_output("Created:\tPXE menu file #{pxe_cfg_file}:")
    system("cat #{pxe_cfg_file}")
  end
  tftp_boot_file=$tftp_dir+"/"+tftp_boot_file
  esx_boot_file=$tftp_dir+"/"+install_service+"/boot.cfg"
  if $verbose_mode == 1
    handle_output("Creating:\tBoot config file #{tftp_boot_file}")
  end
  copy=[]
  file=IO.readlines(esx_boot_file)
  file.each do |line|
    line=line.gsub(/\//,"")
    if $text_mode == 1
      if line.match(/^kernelopt/)
        if !line.match(/text/)
          line = line.chomp+" text\n"
        end
      end
    end
    if $serial_mode == 1
      if line.match(/^kernelopt/)
        if !line.match(/nofb/)
          line = line.chomp+" nofb com1_baud=115200 com1_Port=0x3f8 tty2Port=com1 gdbPort=none logPort=none\n"
        end
      end
    end
    if line.match(/^title/)
      copy.push(line)
      copy.push("prefix=#{install_service}\n")
    else
      copy.push(line)
    end
  end
  File.open(tftp_boot_file,"w") {|file_data| file_data.puts copy}
  if $verbose_mode == 1
    handle_output("Created:\tBoot config file #{tftp_boot_file}:")
    system("cat #{tftp_boot_file}")
  end
  return
end

# Unconfigure client PXE boot

def unconfigure_vs_pxe_client(install_client)
  install_mac = get_install_mac(install_client)
  if !install_mac
    handle_output("Warning:\tNo MAC Address entry found for #{install_client}")
    exit
  end
  tftp_pxe_file = install_mac.gsub(/:/,"")
  tftp_pxe_file = tftp_pxe_file.upcase
  tftp_pxe_file = "01"+tftp_pxe_file+".pxelinux"
  tftp_pxe_file = $tftp_dir+"/"+tftp_pxe_file
  if File.exists?(tftp_pxe_file)
    message = "Information:\tRemoving PXE boot file "+tftp_pxe_file+" for "+install_client
    command = "rm #{tftp_pxe_file}"
    execute_command(message,command)
  end
  pxe_cfg_dir  = $tftp_dir+"/pxelinux.cfg"
  pxe_cfg_file = install_mac.gsub(/:/,"-")
  pxe_cfg_file = "01-"+pxe_cfg_file
  pxe_cfg_file = pxe_cfg_file.downcase
  pxe_cfg_file = pxe_cfg_dir+"/"+pxe_cfg_file
  if File.exists?(pxe_cfg_file)
    message = "Information:\tRemoving PXE boot config file "+pxe_cfg_file+" for "+install_client
    command = "rm #{pxe_cfg_file}"
    execute_command(message,command)
  end
  client_info     = get_vs_clients()
  install_service = client_info.grep(/#{install_client}/)[0].split(/ = /)[1].chomp
  ks_dir          = $tftp_dir+"/"+install_service
  ks_cfg_file     = ks_dir+"/"+install_client+".cfg"
  if File.exist?(ks_cfg_file)
    message = "Information:\tRemoving Kickstart boot config file "+ks_cfg_file+" for "+install_client
    command = "rm #{ks_cfg_file}"
    execute_command(message,command)
  end
  unconfigure_vs_dhcp_client(install_client)
  return
end

# Configure DHCP entry

def configure_vs_dhcp_client(install_client,install_mac,client_ip,client_arch,install_service)
  add_dhcp_client(install_client,install_mac,client_ip,client_arch,install_service)
  return
end

# Unconfigure DHCP client

def unconfigure_vs_dhcp_client(install_client)
  remove_dhcp_client(install_client)
  return
end

# Configure VSphere client

def configure_vs_client(install_client,install_arch,install_mac,install_ip,install_model,publisher_host,install_service,
                        install_file,install_memory,install_cpu,install_network,install_license,install_mirror,install_type,install_vm)
  repo_version_dir=$repo_base_dir+"/"+install_service
  if !File.directory?(repo_version_dir) and !File.symlink?(repo_version_dir)
    handle_output("Information:\tWarning service #{install_service} does not exist")
    handle_output("")
    list_vs_services()
    exit
  end
  populate_vs_questions(install_service,install_client,install_ip)
  process_questions(install_service)
  client_dir = $client_base_dir+"/"+install_service+"/"+install_client
  check_fs_exists(client_dir)
  output_file = client_dir+"/"+install_client+".cfg"
  #output_file=repo_version_dir+"/"+install_client+".cfg"
  if File.exists?(output_file)
    File.delete(output_file)
  end
  #output_file=repo_version_dir+"/"+install_client+".cfg"
  output_vs_header(output_file)
  # Output firstboot list
  post_list = populate_vs_firstboot_list(install_service,install_license,install_client)
  output_vs_post_list(post_list,output_file)
  # Output post list
  post_list = populate_vs_post_list(install_service)
  output_vs_post_list(post_list,output_file)
  if output_file
    %x[chmod 755 #{output_file}]
  end
  configure_vs_pxe_client(install_client,install_mac,install_service)
  configure_vs_dhcp_client(install_client,install_mac,install_ip,install_arch,install_service)
  add_apache_alias($client_base_dir)
  return
end

# Unconfigure VSphere client

def unconfigure_vs_client(install_client,install_mac,install_service)
  unconfigure_vs_pxe_client(install_client)
  unconfigure_vs_dhcp_client(install_client)
  return
end

# Populate firstboot commands

def populate_vs_firstboot_list(install_service,install_license,install_client)
  post_list   = []
  #post_list.push("%pre --interpreter=busybox")
  #post_list.push("echo '127.0.0.1 localhost' >> /etc/resolv.conf")
  #post_list.push("")
  post_list.push("%firstboot --interpreter=busybox")
  post_list.push("")
  post_list.push("# enable HV (Hardware Virtualization to run nested 64bit Guests + Hyper-V VM)")
  post_list.push("grep -i 'vhv.allow' /etc/vmware/config || echo 'vhv.allow = \"TRUE\"' >> /etc/vmware/config")
  post_list.push("")
  post_list.push("# set hostname and DNS")
  post_list.push("esxcli system hostname set --fqdn=#{install_client}.#{$default_domainname}")
  post_list.push("esxcli network ip dns search add --domain=#{$default_domainname}")
  post_list.push("esxcli network ip dns server add --server=#{$default_nameserver}")
  post_list.push("")
  post_list.push("# enable & start remote ESXi Shell  (SSH)")
  post_list.push("vim-cmd hostsvc/enable_ssh")
  post_list.push("vim-cmd hostsvc/start_ssh")
  post_list.push("")
  post_list.push("# Allow root access to DCUI")
  post_list.push("vim-cmd hostsvc/advopt/update DCUI.Access string root")
  post_list.push("")
  post_list.push("# enable & start ESXi Shell (TSM)")
  post_list.push("vim-cmd hostsvc/enable_esx_shell")
  post_list.push("vim-cmd hostsvc/start_esx_shell")
  post_list.push("")
  post_list.push("vim-cmd hostsvc/enable_remote_tsm ")
  post_list.push("vim-cmd hostsvc/start_remote_tsm")
  post_list.push("")
  post_list.push("# Fix for network dropouts")
  post_list.push("esxcli system settings advanced set -o /Net/FollowHardwareMac -i 1")
#  post_list.push("")
#  post_list.push("vim-cmd hostsvc/net/refresh")
  post_list.push("")
  post_list.push("# supress ESXi Shell shell warning ")
  post_list.push("esxcli system settings advanced set -o /UserVars/SuppressShellWarning -i 1")
#  post_list.push("esxcli system settings advanced set -o /UserVars/ESXiShellTimeOut -i 1")
  post_list.push("")
  post_list.push("# rename local datastore to something more meaningful")
  post_list.push("vim-cmd hostsvc/datastore/rename datastore1 \"$(hostname -s)-local-storage-1\"")
  post_list.push("")
  if install_license.match(/[a-z,A-Z]/)
    post_list.push("# assign license")
    post_list.push("vim-cmd vimsvc/license --set #{install_license}")
    post_list.push("")
  end
  post_list.push("# enable management interface")
  post_list.push("cat > /tmp/enableVmkInterface.py << __ENABLE_MGMT_INT__")
  post_list.push("import sys,re,os,urllib,urllib2")
  post_list.push("")
  post_list.push("# connection info to MOB")
  post_list.push("")
  post_list.push("url = \"https://localhost/mob/?moid=ha-vnic-mgr&method=selectVnic\"")
  post_list.push("username = \"root\"")
  post_list.push("password = \"#{$default_root_password}\"")
  post_list.push("")
  post_list.push("# Create global variables")
  post_list.push("global passman,authhandler,opener,req,page,page_content,nonce,headers,cookie,params,e_params")
  post_list.push("")
  post_list.push("#auth")
  post_list.push("passman = urllib2.HTTPPasswordMgrWithDefaultRealm()")
  post_list.push("passman.add_password(None,url,username,password)")
  post_list.push("authhandler = urllib2.HTTPBasicAuthHandler(passman)")
  post_list.push("opener = urllib2.build_opener(authhandler)")
  post_list.push("urllib2.install_opener(opener)")
  post_list.push("")
  post_list.push("# Code to capture required page data and cookie required for post back to meet CSRF requirements  ###")
  post_list.push("req = urllib2.Request(url)")
  post_list.push("page = urllib2.urlopen(req)")
  post_list.push("page_content= page.read()")
  post_list.push("")
  post_list.push("# regex to get the vmware-session-nonce value from the hidden form entry")
  post_list.push("reg = re.compile('name=\"vmware-session-nonce\" type=\"hidden\" value=\"?([^\s^\"]+)\"')")
  post_list.push("nonce = reg.search(page_content).group(1)")
  post_list.push("")
  post_list.push("# get the page headers to capture the cookie")
  post_list.push("headers = page.info()")
  post_list.push("cookie = headers.get(\"Set-Cookie\")")
  post_list.push("")
  post_list.push("#execute method")
  post_list.push("params = {'vmware-session-nonce':nonce,'nicType':'management','device':'vmk0'}")
  post_list.push("e_params = urllib.urlencode(params)")
  post_list.push("req = urllib2.Request(url, e_params, headers={\"Cookie\":cookie})")
  post_list.push("page = urllib2.urlopen(req).read()")
  post_list.push("__ENABLE_MGMT_INT__")
  post_list.push("")
  post_list.push("python /tmp/enableVmkInterface.py")
  post_list.push("")
  post_list.push("# backup ESXi configuration to persist changes")
  post_list.push("/sbin/auto-backup.sh")
  post_list.push("")
#  post_list.push("# enter maintenance mode")
#  post_list.push("vim-cmd hostsvc/maintenance_mode_enter")
#  post_list.push("")
  post_list.push("# copy %first boot script logs to persisted datastore")
  post_list.push("cp /var/log/hostd.log \"/vmfs/volumes/$(hostname -s)-local-storage-1/firstboot-hostd.log\"")
  post_list.push("cp /var/log/esxi_install.log \"/vmfs/volumes/$(hostname -s)-local-storage-1/firstboot-esxi_install.log\"")
  post_list.push("")
  if $serial_mode == 1
    post_list.push("# Fix bootloader to run in serial mode")
    post_list.push("sed -i '/no-auto-partition/ s/$/ text nofb com1_baud=115200 com1_Port=0x3f8 tty2Port=com1 gdbPort=none logPort=none/' /bootbank/boot.cfg")
    post_list.push("")
  end
  post_list.push("reboot")
  return post_list
end

# Populate post commands

def populate_vs_post_list(install_service)
  post_list = []
  post_list.push("")
  return post_list
end

# Output the VSphere file header

def output_vs_header(output_file)
  if $verbose_mode == 1
    handle_output("Information:\tCreating vSphere file #{output_file}")
  end
  file=File.open(output_file, 'w')
  $q_order.each do |key|
    if $q_struct[key].type.match(/output/)
      if !$q_struct[key].parameter.match(/[a-z,A-Z]/)
        output=$q_struct[key].value+"\n"
      else
        output=$q_struct[key].parameter+" "+$q_struct[key].value+"\n"
        if $verbose_mode == 1
          handle_output(output)
        end
      end
      file.write(output)
    end
  end
  file.close
  return
end

# Output the ks packages list

def output_vs_post_list(post_list,output_file)
  file=File.open(output_file, 'a')
  post_list.each do |line|
    output=line+"\n"
    file.write(output)
  end
  file.close
  return
end

# Check service install_service

def check_vs_install_service(install_service)
  if !install_service.match(/[a-z,A-Z]/)
    handle_output("Warning:\tService name not given")
    exit
  end
  client_list=Dir.entries($repo_base_dir)
  if !client_list.grep(install_service)
    handle_output("Warning:\tService name #{install_service} does not exist")
    exit
  end
  return
end
