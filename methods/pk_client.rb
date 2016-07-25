# Packer client related commands

# Get packer vm type

def get_client_vm_type_from_packer(install_client)
  packer_dir = $client_base_dir+"/packer"
  install_vm = ""
  [ "vbox", "fusion" ].each do |test_vm|
    test_dir = packer_dir+"/"+test_vm+"/"+install_client
    if File.directory?(test_dir)
      return test_vm
    end
  end
  return install_vm
end

# Get packer client directory

def get_packer_client_dir(install_client,install_vm)
  packer_dir = $client_base_dir+"/packer"
  client_dir = packer_dir+"/"+install_vm+"/"+install_client
  return client_dir
end

# check if packer VM image exists

def check_packer_vm_image_exists(install_client,install_vm)
  client_dir = get_packer_client_dir(install_client,install_vm)
  images_dir = client_dir+"/images"
  if File.directory?(images_dir)
    exists = "yes"
  else
    exists = "no"
  end
  return exists,images_dir
end

# List packer clients

def list_packer_clients(install_vm)
  packer_dir = $client_base_dir+"/packer"
  if !install_vm.match(/[a-z,A-Z]/)
    vm_types = [ 'fusion', 'vbox' ]
  else
    vm_types = []
    vm_types.push(install_vm)
  end
  vm_types.each do |vm_type|
    vm_dir = packer_dir+"/"+vm_type
    if File.directory?(vm_dir)
      puts ""
      if vm_type.match(/vbox/)
        vm_title = "VirtualBox"
      else
        vm_title = "VMware Fusion"
      end
      puts "Packer "+vm_title+" clients:"
      puts
      vm_list = Dir.entries(vm_dir)
      vm_list.each do |vm_name|
        if vm_name.match(/[a-z,A-Z]/)
          json_file = vm_dir+"/"+vm_name+"/"+vm_name+".json"
          if File.exist?(json_file)
            json  = File.readlines(json_file)
            vm_os = json.grep(/guest_os_type/)[0].split(/:/)[1].split(/"/)[1]
            puts vm_name+" os="+vm_os
          end
        end
      end
    end
  end
end

# Configure Packer JSON file

def create_packer_json(install_method,install_client,install_vm,install_arch,install_file,install_guest,install_size,install_memory,install_cpu,install_network,install_mac,install_ip,install_label)
  nic_command1     = ""
  nic_command2     = ""
  nic_config1      = ""
  nic_config1      = ""
  communicator     = "winrm"
  hw_version       = "12"
  ks_ip            = $default_gateway_ip
  winrm_use_ssl    = "false"
  winrm_insecure   = "true"
  virtual_dev      = "lsisas1068"
  ethernet_type    = "static"
  ethernet_dev     = "e1000"
  vnc_enabled      = "true"
  vhv_enabled      = "TRUE"
  ethernet_enabled = "TRUE"
  boot_wait        = "2m"
  shutdown_timeout = "1h"
  ssh_port         = "22"
  hwvirtex         = "off"
  audio            = "none"
  mouse            = "ps2"
  ssh_pty          = "true"
#  if install_vm.match(/fusion/)
    vnc_port_min = "5900"
    vnc_port_max = "5980"
    winrm_port   = "5985"
#  end
  if install_vm.match(/vbox/)
    output_format = "ova"
#    ssh_host_port_min = "55985"
#    ssh_host_port_max = "55985"
    winrm_port        = "55985"
  end
  if install_vm.match(/fusion/)
    hw_version  = get_fusion_version()
  end
  tools_upload_flavor = ""
  tools_upload_path   = ""
  if $default_vm_network.match(/hostonly/) and install_vm.match(/vbox/)
    if_name  = get_bridged_vbox_nic()
    nic_name = check_vbox_hostonly_network(if_name)
    nic_command1 = "--nic1"
    nic_config1  = "hostonly"
    nic_command2 = "--hostonlyadapter1"
    nic_config2  = "#{nic_name}"
    ks_ip        = $default_gateway_ip
  end
  if $default_vm_network.match(/bridged/) and install_vm.match(/vbox/)
    nic_name = get_bridged_vbox_nic()
    nic_command1 = "--nic1"
    nic_config1  = "bridged"
    nic_command2 = "--bridgeadapter1"
    nic_config2  = "#{nic_name}"
  end
  install_size     = install_size.gsub(/G/,"000")
  (install_service,install_os,install_release,install_arch) = get_packer_install_service(install_file)
  if install_service.match(/sol_10/)
    ssh_username   = $default_admin_user
    ssh_password   = $default_admin_password
    admin_username = $default_admin_user
    admin_password = $default_admin_password
  else
    if install_service.match(/vsphere/)
      ssh_username   = "root"
      ssh_password   = $q_struct["root_password"].value
    else
      ssh_username   = $q_struct["admin_username"].value
      ssh_password   = $q_struct["admin_password"].value
      admin_username = $q_struct["admin_username"].value
      admin_password = $q_struct["admin_password"].value
    end
  end
  if !install_service.match(/win/)
    root_password = $q_struct["root_password"].value
  end
  ssh_wait_timeout = $default_ssh_wait_timeout
  shutdown_command = ""
  if !install_mac.match(/[0-9]/)
    install_mac = generate_mac_address(install_vm)
  end
  if install_guest.class == Array
    install_guest = install_guest.join
  end
  case install_service
  when /win/
    tools_upload_flavor = "windows"
    shutdown_command    = "shutdown /s /t 1 /c \"Packer Shutdown\" /f /d p:4:1"
    unattended_xml      = $client_base_dir+"/packer/"+install_vm+"/"+install_client+"/Autounattend.xml"
    post_install_psh    = $client_base_dir+"/packer/"+install_vm+"/"+install_client+"/post_install.ps1"
    if install_label.match(/2012/)
      if install_vm.match(/fusion/)
        install_guest = "windows8srv-64"
        hw_version    = "12"
      end
      if install_memory.to_i < 2000
        install_memory = "2048"
      end
    else
      if install_vm.match(/fusion/)
        install_guest = "windows7srv-64"
      end
    end
  when /sol_11_[2,3]/
    tools_upload_flavor = "solaris"
    tools_upload_path   = "/export/home/"+$q_struct["admin_username"].value
    boot_command = "<wait10><wait10><wait10><wait10>"+
                   "<wait10><wait10><wait10><wait10>"+
                   "<wait10><wait10><wait10><wait10>"+
                   "27<enter><wait>"+
                   "3<enter><wait>"+
                   "<wait10><wait10><wait10><wait10>"+
                   "<wait10><wait10><wait10><wait10>"+
                   "<wait10><wait10><wait10><wait10>"+
                   "1<enter><wait10><wait10>"+
                   "<f2><wait10>"+
                   "<f2><wait10>"+
                   "<f2><wait10>"+
                   "<f2><wait10>"+
                   "<bs><bs><bs><bs><bs><bs><bs>"+install_client+"<wait>"+
                   "<f2><wait10>"+
                   "<tab><f2><wait>"+
                   install_ip+"<wait><tab><wait><tab>"+
                   $default_gateway_ip+"<wait><f2><wait>"+
                   "<f2><wait>"+
                   $default_nameserver+"<wait><f2><wait>"+
                   "<f2><wait10>"+
                   "<f2><wait10>"+
                   "<f2><wait10>"+
                   "<f2><wait10>"+
                   "<f2><wait10>"+
                   "<f2><wait10>"+
                   "<f2><wait10>"+
                   $q_struct["root_password"].value+"<wait><tab><wait>"+
                   $q_struct["root_password"].value+"<wait><tab><wait>"+
                   $q_struct["admin_username"].value+"<wait><tab><wait>"+
                   $q_struct["admin_username"].value+"<wait><tab><wait>"+
                   $q_struct["admin_password"].value+"<wait><tab><wait>"+
                   $q_struct["admin_password"].value+"<wait><f2><wait>"+
                   "<f2><wait10>"+
                   "<f2><wait10>"+
                   "<f2><wait10>"+
                   "<wait10><wait10><wait10><wait10>"+
                   "<wait10><wait10><wait10><wait10>"+
                   "<wait10><wait10><wait10><wait10>"+
                   "<wait10><wait10><wait10><wait10>"+
                   "<wait10><wait10><wait10><wait10>"+
                   "<wait10><wait10><wait10><wait10>"+
                   "<wait10><wait10><wait10><wait10>"+
                   "<wait10><wait10><wait10><wait10>"+
                   "<wait10><wait10><wait10><wait10>"+
                   "<f8><wait10><wait10>"+
                   "<enter><wait10>"+
                   "<wait10><wait10><wait10><wait10>"+
                   "<wait10><wait10><wait10><wait10>"+
                   "<wait10><wait10><wait10><wait10>"+
                   "<wait10><wait10><wait10><wait10>"+
                   $q_struct["admin_username"].value+"<enter><wait>"+
                   $q_struct["admin_password"].value+"<enter><wait>"+
                   "echo '"+$q_struct["admin_password"].value+"' |sudo -Sv<enter><wait>"+
                   "sudo sh -c \"echo '"+$q_struct["admin_username"].value+" ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers\"<enter><wait>"+
                   "sudo sh -c \"/usr/gnu/bin/sed -i 's/^.*requiretty/#Defaults requiretty/' /etc/sudoers\"<enter><wait>"+
                   "sudo sh -c \"/usr/sbin/svcadm disable sendmail\"<enter><wait>"+
                   "sudo sh -c \"/usr/sbin/svcadm disable asr-notify\"<enter><wait>"+
                   "exit<enter><wait>"
  when /sol_11_[0,1]/
    tools_upload_flavor = "solaris"
    tools_upload_path   = "/export/home/"+$q_struct["admin_username"].value
    boot_command = "<wait10><wait10><wait10><wait10>"+
                   "<wait10><wait10><wait10><wait10>"+
                   "<wait10><wait10><wait10><wait10>"+
                   "27<enter><wait>"+
                   "3<enter><wait>"+
                   "<wait10><wait10><wait10><wait10>"+
                   "<wait10><wait10><wait10><wait10>"+
                   "<wait10><wait10><wait10><wait10>"+
                   "1<enter><wait10><wait10>"+
                   "<f2><wait10>"+
                   "<f2><wait10>"+
                   "<f2><wait10>"+
                   "<f2><wait10>"+
                   "<bs><bs><bs><bs><bs><bs><bs>"+install_client+"<wait>"+
                   "<tab><tab><f2><wait10>"+
                   install_ip+"<wait><tab><wait><tab>"+
                   $default_gateway_ip+"<wait><f2><wait>"+
                   "<f2><wait>"+
                   $default_nameserver+"<wait><f2><wait>"+
                   "<f2><wait10>"+
                   "<f2><wait10>"+
                   "<f2><wait10>"+
                   "<f2><wait10>"+
                   $q_struct["root_password"].value+"<wait><tab><wait>"+
                   $q_struct["root_password"].value+"<wait><tab><wait>"+
                   $q_struct["admin_username"].value+"<wait><tab><wait>"+
                   $q_struct["admin_username"].value+"<wait><tab><wait>"+
                   $q_struct["admin_password"].value+"<wait><tab><wait>"+
                   $q_struct["admin_password"].value+"<wait><f2><wait>"+
                   "<f2><wait10>"+
                   "<f2><wait10>"+
                   "<f2><wait10>"+
                   "<wait10><wait10><wait10><wait10>"+
                   "<wait10><wait10><wait10><wait10>"+
                   "<wait10><wait10><wait10><wait10>"+
                   "<wait10><wait10><wait10><wait10>"+
                   "<wait10><wait10><wait10><wait10>"+
                   "<wait10><wait10><wait10><wait10>"+
                   "<wait10><wait10><wait10><wait10>"+
                   "<wait10><wait10><wait10><wait10>"+
                   "<wait10><wait10><wait10><wait10>"+
                   "<f8><wait10><wait10>"+
                   "<enter><wait10>"+
                   "<wait10><wait10><wait10><wait10>"+
                   "<wait10><wait10><wait10><wait10>"+
                   "<wait10><wait10><wait10><wait10>"+
                   "<wait10><wait10><wait10><wait10>"+
                   $q_struct["admin_username"].value+"<enter><wait>"+
                   $q_struct["admin_password"].value+"<enter><wait>"+
                   "echo '"+$q_struct["admin_password"].value+"' |sudo -Sv<enter><wait>"+
                   "sudo sh -c \"echo '"+$q_struct["admin_username"].value+" ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers\"<enter><wait>"+
                   "sudo sh -c \"/usr/gnu/bin/sed -i 's/^.*requiretty/#Defaults requiretty/' /etc/sudoers\"<enter><wait>"+
                   "sudo sh -c \"/usr/sbin/svcadm disable sendmail\"<enter><wait>"+
                   "sudo sh -c \"/usr/sbin/svcadm disable asr-notify\"<enter><wait>"+
                   "exit<enter><wait>"
  when /sol_10/
    tools_upload_flavor = "solaris"
    tools_upload_path   = "/export/home/"+$q_struct["admin_username"].value
    shutdown_command    = "echo '/usr/sbin/poweroff' > shutdown.sh; pfexec bash -l shutdown.sh"
    shutdown_timeout    = "20m"
    sysidcfg    = $client_base_dir+"/packer/"+install_vm+"/"+install_client+"/sysidcfg"
    rules       = $client_base_dir+"/packer/"+install_vm+"/"+install_client+"/rules"
    rules_ok    = $client_base_dir+"/packer/"+install_vm+"/"+install_client+"/rules.ok"
    profile     = $client_base_dir+"/packer/"+install_vm+"/"+install_client+"/profile"
    finish      = $client_base_dir+"/packer/"+install_vm+"/"+install_client+"/finish"
    boot_command = "e<wait>"+
                   "e<wait>"+
                   "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><wait>"+
                   "- nowin install -B install_media=cdrom<enter><wait>"+
                   "b<wait>"
  when /sles/
    tools_upload_flavor = "linux"
    tools_upload_path   = "/home/"+$q_struct["admin_username"].value
    ks_file      = install_vm+"/"+install_client+"/"+install_client+".xml"
    ks_url       = "http://#{ks_ip}:#{$default_httpd_port}/"+ks_file
    boot_command = "<esc><enter><wait> linux text install=cd:/ textmode=1 insecure=1"+
                   " netdevice="+$q_struct["nic"].value+
                   " autoyast="+ ks_url+
                   " language="+$default_language+
                   " netsetup=-dhcp,+hostip,+netmask,+gateway,+nameserver1,+domain"+
                   " hostip="+install_ip+"/24"+
                   " netmask="+$q_struct["netmask"].value+
                   " gateway="+$q_struct["gateway"].value+
                   " nameserver="+$q_struct["nameserver"].value+
                   " domain="+$default_domainname+
                   "<enter><wait>"
  when /debian|ubuntu/
    tools_upload_flavor = "linux"
    tools_upload_path   = "/home/"+$q_struct["admin_username"].value
    ks_file = install_vm+"/"+install_client+"/"+install_client+".cfg"
    ks_url  = "http://#{ks_ip}:#{$default_httpd_port}/"+ks_file
    if install_service.match(/ubuntu_[14,15]/)
      boot_header = "<enter><wait><f6><esc><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>"+
                    "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>"+
                    "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>"+
                    "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>"+
                    "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>"
    else
      boot_header = "<esc><esc><enter><wait>"
    end
    boot_command = boot_header+
                   "/install/vmlinuz debian-installer/language="+$q_struct["language"].value+
                   " debian-installer/country="+$q_struct["country"].value+
                   " keyboard-configuration/layoutcode="+$q_struct["layout"].value+
                   " interface="+$q_struct["nic"].value+
                   " netcfg/disable_autoconfig="+$q_struct["disable_autoconfig"].value+
                   " netcfg/disable_dhcp="+$q_struct["disable_dhcp"].value+
                   " hostname="+install_client+
                   " netcfg/get_ipaddress="+install_ip+
                   " netcfg/get_netmask="+$q_struct["netmask"].value+
                   " netcfg/get_gateway="+$q_struct["gateway"].value+
                   " netcfg/get_nameservers="+$q_struct["nameserver"].value+
                   " netcfg/get_domain="+$q_struct["domain"].value+
                   " preseed/url="+ks_url+
                   " initrd=/install/initrd.gz -- <wait><enter><wait>"
    #shutdown_command = "echo 'shutdown -P now' > /tmp/shutdown.sh ; echo '#{$q_struct["admin_password"].value}'|sudo -S sh '/tmp/shutdown.sh'"
  when /vsphere|esx|vmware/
    hwvirtex         = "on"
    ks_file          = install_vm+"/"+install_client+"/"+install_client+".cfg"
    ks_url           = "http://#{ks_ip}:#{$default_httpd_port}/"+ks_file
    boot_command     = "<enter><wait>O<wait> ks="+ks_url+" ksdevice=vmnic0 netdevice=vmnic0 ip="+install_ip+" netmask="+$default_netmask+" gateway="+$default_gateway_ip+"<wait><enter><wait>"
    ssh_username     = "root"
    shutdown_command = "/bin/halt"
    ssh_wait_timeout = "1200s"
  when /fedora/
    tools_upload_flavor = "linux"
    tools_upload_path   = "/home/"+$q_struct["admin_username"].value
    ks_file          = install_vm+"/"+install_client+"/"+install_client+".cfg"
    ks_url           = "http://#{ks_ip}:#{$default_httpd_port}/"+ks_file
    boot_command     = "<tab><wait><bs><bs><bs><bs><bs><bs>=0 inst.text inst.method=cdrom inst.repo=cdrom:/dev/sr0 inst.sshd inst.ks="+ks_url+" ip="+install_ip+" netmask="+$default_netmask+" gateway="+$default_gateway_ip+"<enter><wait>"
  else
    ks_file       = install_vm+"/"+install_client+"/"+install_client+".cfg"
    ks_url        = "http://#{ks_ip}:#{$default_httpd_port}/"+ks_file
    boot_command  = "<esc><wait> linux text install ks="+ks_url+" ip="+install_ip+" netmask="+$default_netmask+" gateway="+$default_gateway_ip+"<enter><wait>"
    if install_guest.class == Array
  	  install_guest = install_guest.join
    end
    #shutdown_command = "echo '#{$q_struct["admin_password"].value}' |sudo -S /sbin/halt -h -p"
    #if install_vm.match(/vbox/) and install_network.match(/hostonly|bridged/)
    #  shutdown_command = "sudo 'shutdown -P now'"
    #end
  end
	$vbox_disk_type = $vbox_disk_type.gsub(/sas/,"scsi")
	case install_vm
	when /vbox|virtualbox/
		install_type = "virtualbox-iso"
    install_mac  = install_mac.gsub(/:/,"")
	when /fusion|vmware/
		install_type = "vmware-iso"
	end
	if $do_checksums == 1
		md5_file = install_file+".md5"
		if File.exist?(md5_file)
			install_md5 = File.readlines(md5_file)[0]
		else
			install_md5 = %x[md5 "#{install_file}" |awk '{print $4}'].chomp
		end
		install_checksum      = install_md5
		install_checksum_type = "md5"
	else
		install_checksum      = ""
		install_checksum_type = "none"
	end
	if $default_vm_network.match(/bridged/) and install_vm.match(/vbox/)
    vbox_nic_name = get_bridged_vbox_nic()
  end
  if $default_vm_network.match(/hostonly/) and install_vm.match(/vbox/)
    if_name       = get_bridged_vbox_nic()
    vbox_nic_name = check_vbox_hostonly_network(if_name)
  end
	iso_url    = "file://"+install_file
	packer_dir = $client_base_dir+"/packer"
  client_dir = packer_dir+"/"+install_vm+"/"+install_client
  image_dir  = client_dir+"/images"
  json_file  = client_dir+"/"+install_client+".json"
  check_dir_exists(client_dir)
  if install_service.match(/sol_10/)
    if install_vm.match(/vbox/)
      if $default_vm_network.match(/hostonly|bridged/)
        json_data = {
          :variables => {
            :hostname => install_client
          },
          :builders => [
            :name                 => install_client,
            :vm_name              => install_client,
            :type                 => install_type,
            :guest_os_type        => install_guest,
            :output_directory     => image_dir,
            :disk_size            => install_size,
            :iso_url              => iso_url,
            :ssh_host             => install_ip,
            :ssh_port             => ssh_port,
            :ssh_username         => ssh_username,
            :ssh_password         => ssh_password,
            :ssh_wait_timeout     => ssh_wait_timeout,
            :shutdown_command     => shutdown_command,
            :shutdown_timeout     => shutdown_timeout,
            :ssh_pty              => ssh_pty,
            :iso_checksum         => install_checksum,
            :iso_checksum_type    => install_checksum_type,
            :http_directory       => packer_dir,
            :http_port_min        => $default_httpd_port,
            :http_port_max        => $default_httpd_port,
            :boot_command         => boot_command,
            :format               => output_format,
            :floppy_files         => [
              sysidcfg,
              rules,
              rules_ok,
              profile,
              finish
            ],
            :vboxmanage => [
              [ "modifyvm", "{{.Name}}", "--memory", install_memory ],
              [ "modifyvm", "{{.Name}}", "--audio", audio ],
              [ "modifyvm", "{{.Name}}", "--mouse", mouse ],
              [ "modifyvm", "{{.Name}}", "--hwvirtex", hwvirtex ],
              [ "modifyvm", "{{.Name}}", "--cpus", install_cpu ],
              [ "modifyvm", "{{.Name}}", nic_command1, nic_config1 ],
              [ "modifyvm", "{{.Name}}", nic_command2, nic_config2 ],
              [ "modifyvm", "{{.Name}}", "--macaddress1", install_mac ],
            ]
          ]
        }
      else
        json_data = {
          :variables => {
            :hostname => install_client
          },
          :builders => [
            :name                 => install_client,
            :vm_name              => install_client,
            :type                 => install_type,
            :guest_os_type        => install_guest,
            :hard_drive_interface => $vbox_disk_type,
            :output_directory     => image_dir,
            :disk_size            => install_size,
            :iso_url              => iso_url,
            :ssh_host             => install_ip,
            :ssh_username         => ssh_username,
            :ssh_password         => ssh_password,
            :ssh_pty              => ssh_pty,
            :ssh_wait_timeout     => ssh_wait_timeout,
            :shutdown_command     => shutdown_command,
            :shutdown_timeout     => shutdown_timeout,
            :iso_checksum         => install_checksum,
            :iso_checksum_type    => install_checksum_type,
            :http_directory       => packer_dir,
            :http_port_min        => $default_httpd_port,
            :http_port_max        => $default_httpd_port,
            :boot_command         => boot_command,
            :floppy_files         => [
              sysidcfg,
              rules,
              rules_ok,
              profile,
              finish
            ],
            :vboxmanage => [
              [ "modifyvm", "{{.Name}}", "--memory", install_memory ],
              [ "modifyvm", "{{.Name}}", "--audio", audio ],
              [ "modifyvm", "{{.Name}}", "--mouse", mouse ],
              [ "modifyvm", "{{.Name}}", "--hwvirtex", hwvirtex ],
              [ "modifyvm", "{{.Name}}", "--cpus", install_cpu ],
              [ "modifyvm", "{{.Name}}", "--macaddress1", install_mac ],
            ]
          ]
        }
      end
    else
      if $default_vm_network.match(/hostonly|bridged/)
        json_data = {
          :variables => {
            :hostname => install_client
          },
          :builders => [
            :name                 => install_client,
            :vm_name              => install_client,
            :type                 => install_type,
            :guest_os_type        => install_guest,
            :output_directory     => image_dir,
            :disk_size            => install_size,
            :iso_url              => iso_url,
            :ssh_host             => install_ip,
            :ssh_port             => ssh_port,
            :ssh_username         => ssh_username,
            :ssh_password         => ssh_password,
            :ssh_wait_timeout     => ssh_wait_timeout,
            :shutdown_command     => shutdown_command,
            :shutdown_timeout     => shutdown_timeout,
            :ssh_pty              => ssh_pty,
            :iso_checksum         => install_checksum,
            :iso_checksum_type    => install_checksum_type,
            :http_directory       => packer_dir,
            :http_port_min        => $default_httpd_port,
            :http_port_max        => $default_httpd_port,
            :boot_command         => boot_command,
            :tools_upload_flavor  => tools_upload_flavor,
            :tools_upload_path    => tools_upload_path,
            :vmx_data => {
              :"virtualHW.version"                => hw_version,
              :"RemoteDisplay.vnc.enabled"        => vnc_enabled,
              :memsize                            => install_memory,
              :numvcpus                           => install_cpu,
              :"vhv.enable"                       => vhv_enabled,
              :"ethernet0.present"                => ethernet_enabled,
              :"ethernet0.connectionType"         => install_network,
              :"ethernet0.virtualDev"             => ethernet_dev,
              :"ethernet0.addressType"            => ethernet_type,
              :"ethernet0.address"                => install_mac,
              :"scsi0.virtualDev"                 => virtual_dev
            }
          ]
        }
      else
        json_data = {
          :variables => {
            :hostname => install_client
          },
          :builders => [
            :name                 => install_client,
            :vm_name              => install_client,
            :type                 => install_type,
            :guest_os_type        => install_guest,
            :output_directory     => image_dir,
            :disk_size            => install_size,
            :iso_url              => iso_url,
            :ssh_username         => ssh_username,
            :ssh_password         => ssh_password,
            :ssh_wait_timeout     => ssh_wait_timeout,
            :shutdown_command     => shutdown_command,
            :shutdown_timeout     => shutdown_timeout,
            :ssh_pty              => ssh_pty,
            :iso_checksum         => install_checksum,
            :iso_checksum_type    => install_checksum_type,
            :http_directory       => packer_dir,
            :http_port_min        => $default_httpd_port,
            :http_port_max        => $default_httpd_port,
            :boot_command         => boot_command,
            :tools_upload_flavor  => tools_upload_flavor,
            :tools_upload_path    => tools_upload_path,
            :vmx_data => {
              :"virtualHW.version"                => hw_version,
              :"RemoteDisplay.vnc.enabled"        => vnc_enabled,
              :memsize                            => install_memory,
              :numvcpus                           => install_cpu,
              :"vhv.enable"                       => vhv_enabled,
              :"ethernet0.present"                => ethernet_enabled,
              :"ethernet0.connectionType"         => install_network,
              :"ethernet0.virtualDev"             => ethernet_dev,
              :"ethernet0.addressType"            => ethernet_type,
              :"ethernet0.address"                => install_mac,
              :"scsi0.virtualDev"                 => virtual_dev
            }
          ]
        }
      end
    end
  end
  if install_vm.match(/vbox/) and !install_service.match(/sol_10/)
    if $default_vm_network.match(/hostonly|bridged/)
      if install_service.match(/win/)
        json_data = {
          :variables => {
            :hostname => install_client
          },
          :builders => [
            :type                 => install_type,
            :vm_name              => install_client,
            :output_directory     => image_dir,
            :disk_size            => install_size,
            :iso_url              => iso_url,
            :iso_checksum         => install_checksum,
            :iso_checksum_type    => install_checksum_type,
            :guest_os_type        => install_guest,
            :communicator         => communicator,
            :winrm_port           => winrm_port,
            :winrm_username       => ssh_username,
            :winrm_password       => ssh_password,
            :winrm_timeout        => ssh_wait_timeout,
            :winrm_use_ssl        => winrm_use_ssl,
            :winrm_insecure       => winrm_insecure,
            :shutdown_timeout     => shutdown_timeout,
            :shutdown_command     => shutdown_command,
            :format               => output_format,
            :floppy_files         => [
              unattended_xml,
              post_install_psh
            ],
            :vboxmanage => [
              [ "modifyvm", "{{.Name}}", "--memory", install_memory ],
              [ "modifyvm", "{{.Name}}", "--audio", audio ],
              [ "modifyvm", "{{.Name}}", "--mouse", mouse ],
              [ "modifyvm", "{{.Name}}", "--hwvirtex", hwvirtex ],
              [ "modifyvm", "{{.Name}}", "--cpus", install_cpu ],
              [ "modifyvm", "{{.Name}}", nic_command1, nic_config1 ],
              [ "modifyvm", "{{.Name}}", nic_command2, nic_config2 ],
              [ "modifyvm", "{{.Name}}", "--macaddress1", install_mac ],
            ]
          ]
        }
      else
        json_data = {
        	:variables => {
        		:hostname => install_client
        	},
        	:builders => [
            :name                 => install_client,
            :vm_name              => install_client,
            :type                 => install_type,
            :guest_os_type        => install_guest,
            :output_directory     => image_dir,
            :disk_size            => install_size,
            :iso_url              => iso_url,
            :ssh_host             => install_ip,
            :ssh_port             => ssh_port,
            :ssh_username         => ssh_username,
            :ssh_password         => ssh_password,
            :ssh_wait_timeout     => ssh_wait_timeout,
            :ssh_pty              => ssh_pty,
            :shutdown_timeout     => shutdown_timeout,
            :shutdown_command     => shutdown_command,
            :iso_checksum         => install_checksum,
            :iso_checksum_type    => install_checksum_type,
            :http_directory       => packer_dir,
            :http_port_min        => $default_httpd_port,
            :http_port_max        => $default_httpd_port,
            :boot_command         => boot_command,
            :format               => output_format,
      			:vboxmanage => [
      				[ "modifyvm", "{{.Name}}", "--memory", install_memory ],
              [ "modifyvm", "{{.Name}}", "--audio", audio ],
              [ "modifyvm", "{{.Name}}", "--mouse", mouse ],
              [ "modifyvm", "{{.Name}}", "--hwvirtex", hwvirtex ],
      				[ "modifyvm", "{{.Name}}", "--cpus", install_cpu ],
              [ "modifyvm", "{{.Name}}", nic_command1, nic_config1 ],
              [ "modifyvm", "{{.Name}}", nic_command2, nic_config2 ],
              [ "modifyvm", "{{.Name}}", "--macaddress1", install_mac ],
      			]
      		]
        }
      end
    else
      if install_service.match(/win/)
        json_data = {
          :variables => {
            :hostname => install_client
          },
          :builders => [
              :type                 => install_type,
              :vm_name              => install_client,
              :output_directory     => image_dir,
              :disk_size            => install_size,
              :iso_url              => iso_url,
              :iso_checksum         => install_checksum,
              :iso_checksum_type    => install_checksum_type,
              :guest_os_type        => install_guest,
              :communicator         => communicator,
              :winrm_username       => ssh_username,
              :winrm_password       => ssh_password,
              :winrm_timeout        => ssh_wait_timeout,
              :shutdown_timeout     => shutdown_timeout,
              :shutdown_command     => shutdown_command,
              :format               => output_format,
              :floppy_files         => [
              unattended_xml,
              post_install_psh
            ],
            :vboxmanage => [
              [ "modifyvm", "{{.Name}}", "--memory", install_memory ],
              [ "modifyvm", "{{.Name}}", "--audio", audio ],
              [ "modifyvm", "{{.Name}}", "--mouse", mouse ],
              [ "modifyvm", "{{.Name}}", "--hwvirtex", hwvirtex ],
              [ "modifyvm", "{{.Name}}", "--cpus", install_cpu ],
              [ "modifyvm", "{{.Name}}", "--macaddress1", install_mac ],
              [ "modifyvm", "{{.Name}}", "--natpf1", "guestwinrm,tcp,,55985,,5985" ],
            ]
          ]
        }
      else
        json_data = {
          :variables => {
            :hostname => install_client
          },
          :builders => [
            :name                 => install_client,
            :vm_name              => install_client,
            :type                 => install_type,
            :guest_os_type        => install_guest,
            :hard_drive_interface => $vbox_disk_type,
            :output_directory     => image_dir,
            :disk_size            => install_size,
            :iso_url              => iso_url,
            :ssh_host             => install_ip,
            :ssh_username         => ssh_username,
            :ssh_password         => ssh_password,
            :ssh_wait_timeout     => ssh_wait_timeout,
            :shutdown_timeout     => shutdown_timeout,
            :shutdown_command     => shutdown_command,
            :ssh_pty              => ssh_pty,
            :iso_checksum         => install_checksum,
            :iso_checksum_type    => install_checksum_type,
            :http_directory       => packer_dir,
            :http_port_min        => $default_httpd_port,
            :http_port_max        => $default_httpd_port,
            :boot_command         => boot_command,
            :vboxmanage => [
              [ "modifyvm", "{{.Name}}", "--memory", install_memory ],
              [ "modifyvm", "{{.Name}}", "--audio", audio ],
              [ "modifyvm", "{{.Name}}", "--mouse", mouse ],
              [ "modifyvm", "{{.Name}}", "--hwvirtex", hwvirtex ],
              [ "modifyvm", "{{.Name}}", "--cpus", install_cpu ],
              [ "modifyvm", "{{.Name}}", "--macaddress1", install_mac ],
            ]
          ]
        }
      end
    end
  elsif !install_service.match(/sol_10/) 
    if $default_vm_network.match(/hostonly|bridged/)
      if install_service.match(/win/)
        json_data = {
          :variables => {
            :hostname => install_client
          },
          :builders => [
            :name                 => install_client,
            :vm_name              => install_client,
            :type                 => install_type,
            :guest_os_type        => install_guest,
            :output_directory     => image_dir,
            :disk_size            => install_size,
            :iso_url              => iso_url,
            :communicator         => communicator,
            :vnc_port_min         => vnc_port_min,
            :vnc_port_max         => vnc_port_max,
            :ssh_host             => install_ip,
            :ssh_port             => ssh_port,
            :ssh_username         => ssh_username,
            :ssh_password         => ssh_password,
            :ssh_wait_timeout     => ssh_wait_timeout,
            :ssh_pty              => ssh_pty,
            :winrm_host           => install_ip,
            :winrm_username       => ssh_username,
            :winrm_password       => ssh_password,
            :winrm_timeout        => ssh_wait_timeout,
            :winrm_use_ssl        => winrm_use_ssl,
            :winrm_insecure       => winrm_insecure,
            :winrm_port           => winrm_port,
            :shutdown_timeout     => shutdown_timeout,
            :shutdown_command     => shutdown_command,
            :iso_checksum         => install_checksum,
            :iso_checksum_type    => install_checksum_type,
            :http_directory       => packer_dir,
            :http_port_min        => $default_httpd_port,
            :http_port_max        => $default_httpd_port,
            :boot_command         => boot_command,
            :tools_upload_flavor  => tools_upload_flavor,
            :tools_upload_path    => tools_upload_path,
            :floppy_files         => [
              unattended_xml,
              post_install_psh
            ],
            :vmx_data => {
              :"virtualHW.version"                => hw_version,
              :"RemoteDisplay.vnc.enabled"        => vnc_enabled,
              :"RemoteDisplay.vnc.port"           => vnc_port_min,
              :memsize                            => install_memory,
              :numvcpus                           => install_cpu,
              :"vhv.enable"                       => vhv_enabled,
              :"ethernet0.present"                => ethernet_enabled,
              :"ethernet0.connectionType"         => install_network,
              :"ethernet0.virtualDev"             => ethernet_dev,
              :"ethernet0.addressType"            => ethernet_type,
              :"ethernet0.address"                => install_mac,
              :"scsi0.virtualDev"                 => virtual_dev
            }
          ]
        }
      else
        json_data = {
          :variables => {
            :hostname => install_client
          },
          :builders => [
            :name                 => install_client,
            :vm_name              => install_client,
            :type                 => install_type,
            :guest_os_type        => install_guest,
            :output_directory     => image_dir,
            :disk_size            => install_size,
            :iso_url              => iso_url,
            :ssh_host             => install_ip,
            :ssh_port             => ssh_port,
            :ssh_username         => ssh_username,
            :ssh_password         => ssh_password,
            :ssh_wait_timeout     => ssh_wait_timeout,
            :shutdown_timeout     => shutdown_timeout,
            :shutdown_command     => shutdown_command,
            :ssh_pty              => ssh_pty,
            :iso_checksum         => install_checksum,
            :iso_checksum_type    => install_checksum_type,
            :http_directory       => packer_dir,
            :http_port_min        => $default_httpd_port,
            :http_port_max        => $default_httpd_port,
            :boot_command         => boot_command,
            :tools_upload_flavor  => tools_upload_flavor,
            :tools_upload_path    => tools_upload_path,
            :vmx_data => {
              :"virtualHW.version"                => hw_version,
              :"RemoteDisplay.vnc.enabled"        => vnc_enabled,
              :memsize                            => install_memory,
              :numvcpus                           => install_cpu,
              :"vhv.enable"                       => vhv_enabled,
              :"ethernet0.present"                => ethernet_enabled,
              :"ethernet0.connectionType"         => install_network,
              :"ethernet0.virtualDev"             => ethernet_dev,
              :"ethernet0.addressType"            => ethernet_type,
              :"ethernet0.address"                => install_mac,
              :"scsi0.virtualDev"                 => virtual_dev
            }
          ]
        }
      end
    else
      if install_service.match(/win/)
        json_data = {
          :variables => {
            :hostname => install_client
          },
          :builders => [
            :type                 => install_type,
            :vm_name              => install_client,
            :output_directory     => image_dir,
            :disk_size            => install_size,
            :iso_url              => iso_url,
            :iso_checksum         => install_checksum,
            :iso_checksum_type    => install_checksum_type,
            :guest_os_type        => install_guest,
            :communicator         => communicator,
            :winrm_port           => winrm_port,
            :winrm_username       => ssh_username,
            :winrm_password       => ssh_password,
            :winrm_timeout        => ssh_wait_timeout,
            :winrm_use_ssl        => winrm_use_ssl,
            :winrm_insecure       => winrm_insecure,
            :shutdown_timeout     => shutdown_timeout,
            :shutdown_command     => shutdown_command,
            :ssh_pty              => ssh_pty,
            :tools_upload_flavor  => tools_upload_flavor,
            :tools_upload_path    => tools_upload_path,
            :floppy_files         => [
              unattended_xml,
              post_install_psh
            ],
            :vmx_data => {
              :"virtualHW.version"                => hw_version,
              :"RemoteDisplay.vnc.enabled"        => vnc_enabled,
              :"RemoteDisplay.vnc.port"           => vnc_port_min,
              :memsize                            => install_memory,
              :numvcpus                           => install_cpu,
              :"vhv.enable"                       => vhv_enabled,
              :"ethernet0.present"                => ethernet_enabled,
              :"ethernet0.connectionType"         => install_network,
              :"ethernet0.virtualDev"             => ethernet_dev,
              :"ethernet0.addressType"            => ethernet_type,
              :"ethernet0.address"                => install_mac,
              :"scsi0.virtualDev"                 => virtual_dev
            }
          ]
        }
      else
        json_data = {
          :variables => {
            :hostname => install_client
          },
          :builders => [
            :name                 => install_client,
            :vm_name              => install_client,
            :type                 => install_type,
            :guest_os_type        => install_guest,
            :output_directory     => image_dir,
            :disk_size            => install_size,
            :iso_url              => iso_url,
            :ssh_username         => ssh_username,
            :ssh_password         => ssh_password,
            :ssh_wait_timeout     => ssh_wait_timeout,
            :ssh_pty              => ssh_pty,
            :shutdown_timeout     => shutdown_timeout,
            :shutdown_command     => shutdown_command,
            :iso_checksum         => install_checksum,
            :iso_checksum_type    => install_checksum_type,
            :http_directory       => packer_dir,
            :http_port_min        => $default_httpd_port,
            :http_port_max        => $default_httpd_port,
            :boot_command         => boot_command,
            :tools_upload_flavor  => tools_upload_flavor,
            :tools_upload_path    => tools_upload_path,
            :vmx_data => {
              :"virtualHW.version"                => hw_version,
              :"RemoteDisplay.vnc.enabled"        => vnc_enabled,
              :memsize                            => install_memory,
              :numvcpus                           => install_cpu,
              :"vhv.enable"                       => vhv_enabled,
              :"ethernet0.present"                => ethernet_enabled,
              :"ethernet0.connectionType"         => install_network,
              :"ethernet0.virtualDev"             => ethernet_dev,
              :"ethernet0.addressType"            => ethernet_type,
              :"ethernet0.address"                => install_mac,
              :"scsi0.virtualDev"                 => virtual_dev
            }
          ]
        }
      end
    end
  end
  json_output = JSON.pretty_generate(json_data)
  delete_file(json_file)
  File.write(json_file,json_output)
  if $verbose_mode == 1
  	puts
  	system("cat #{json_file}")
  	puts
  end
  return communicator
end

# Check if a packer image exists

def check_packer_image_exists(install_client,install_vm)
	packer_dir = $client_base_dir+"/packer/"+install_vm
  client_dir = packer_dir+"/"+install_client
  image_dir  = client_dir+"/images"
  image_file = image_dir+"/"+install_client+".ovf"
  if File.exist?(image_file)
  	exists = "yes"
  else
  	exists = "no"
  end
	return exists
end

# Delete a packer image

def unconfigure_packer_client(install_client,install_vm)
	if $verbose_mode == 1
		puts "Information:\tDeleting Packer Image for "+install_client
	end
	packer_dir = $client_base_dir+"/packer/"+install_vm
  client_dir = packer_dir+"/"+install_client
  image_dir  = client_dir+"/images"
  ovf_file   = image_dir+"/"+install_client+".ovf"
  cfg_file   = client_dir+"/"+install_client+".cfg"
  json_file  = client_dir+"/"+install_client+".json"
  disk_file  = image_dir+"/"+install_client+"-disk1.vmdk"
  [ ovf_file, cfg_file, json_file, disk_file ].each do |file_name|
    if File.exist?(file_name)
    	if $verbose_mode == 1
    		puts "Information:\tDeleting file "+file_name
    	end
    	File.delete(file_name)
    end
  end
  if Dir.exist?(image_dir)
  	if $verbose_mode == 1
  		puts "Information:\tDeleting directory "+image_dir
  	end
    if image_dir.match(/[a-z]/)
    	FileUtils.rm_rf(image_dir)
    end
  end
	return
end

# Kill off any existing packer processes for a client
# some times dead packer processes are left running which stop the build process starting

def kill_packer_processes(install_client)
  puts "Information:\tMaking sure no existing Packer processes are running for "+install_client
  %x[ps -ef |grep packer |grep "#{install_client}.json" |awk '{print $2}' |xargs kill]
  return
end

# Create a packer config

def configure_packer_client(install_method,install_vm,install_os,install_client,install_arch,install_mac,install_ip,install_model,
                            publisher_host,install_service,install_file,install_memory,install_cpu,install_network,install_license,
                            install_mirror,install_size,install_type,install_locale,install_label,install_timezone,install_shell)

  if !$default_host.match(/[0-9,a-z,A-Z]/)
    $default_host = get_default_host()
  end
  uid = %x[id -u].chomp
  check_dir_exists($client_base_dir)
  check_dir_owner($client_base_dir,uid)
	exists = eval"[check_#{install_vm}_vm_exists(install_client)]"
	if exists == "yes"
		puts "Warning:\tVirtualBox VM "+install_client+" already exists"
		exit
	end
	exists = check_packer_image_exists(install_client,install_vm)
	if exists == "yes"
		puts "Warning:\tPacker image for VirtualBox VM "+install_client+" already exists "
		exit
	end
  (install_service,install_os,install_method,install_release,install_arch,install_label) = get_packer_install_service(install_file)
	install_guest = eval"[get_#{install_vm}_guest_os(install_method,install_arch)]"
	eval"[configure_packer_#{install_method}_client(install_client,install_arch,install_mac,install_ip,install_model,publisher_host,install_service,install_file,install_memory,
                           install_cpu,install_network,install_license,install_mirror,install_vm,install_type,install_locale,install_label,install_timezone,install_shell)]"
  create_packer_json(install_method,install_client,install_vm,install_arch,install_file,install_guest,install_size,install_memory,install_cpu,install_network,install_mac,install_ip,install_label)
	#build_packer_config(install_client,install_vm)
	return
end

# Build a packer config

def build_packer_config(install_client,install_vm)
  kill_packer_processes(install_client)
  exists = eval"[check_#{install_vm}_vm_exists(install_client)]"
  if exists.to_s.match(/yes/)
    puts "Warning:\t"+install_vm.capitalize+" VM "+install_client+" already exists "
    exit
  end
  exists = check_packer_image_exists(install_client,install_vm)
  client_dir = $client_base_dir+"/packer/"+install_vm+"/"+install_client
  json_file  = client_dir+"/"+install_client+".json"
  if !File.exist?(json_file)
    puts "Warning:\tJSON configuration file \""+json_file+"\" for "+install_client+" does not exist"
    exit
  end
	message    = "Information:\tBuilding Packer Image "+json_file
	command    = "packer build "+json_file
	execute_command(message,command)
	return
end

# Get Packer install service from ISO file name

def get_packer_install_service(install_file)
  (install_service,install_os,install_method,install_release,install_arch,install_label) = get_install_service_from_file(install_file)
#  (linux_distro,iso_version,iso_arch) = get_linux_version_info(install_file)
#  iso_version     = iso_version.gsub(/\./,"_")
#  install_service = "packer_"+linux_distro+"_"+iso_version+"_"+iso_arch
  return install_service,install_os,install_method,install_release,install_arch,install_label
end

# Create vSphere Packer client

def create_packer_vs_install_files(install_client,install_service,install_ip,publisher_host,install_vm,install_license,install_mac,install_type)
  client_dir  = $client_base_dir+"/packer/"+install_vm+"/"+install_client
  output_file = client_dir+"/"+install_client+".cfg"
  check_dir_exists(client_dir)
  delete_file(output_file)
  populate_vs_questions(install_service,install_client,install_ip)
  process_questions(install_service)
  output_vs_header(output_file)
  # Output firstboot list
  post_list = populate_vs_firstboot_list(install_service,install_license,install_client)
  output_vs_post_list(post_list,output_file)
  # Output post list
  post_list = populate_vs_post_list(install_service)
  output_vs_post_list(post_list,output_file)
  return
end

# Create Kickstart Packer client (RHEL, CentOS, SL, and OEL)

def create_packer_ks_install_files(install_arch,install_client,install_service,install_ip,publisher_host,install_vm,install_type)
  client_dir  = $client_base_dir+"/packer/"+install_vm+"/"+install_client
  output_file = client_dir+"/"+install_client+".cfg"
  check_dir_exists(client_dir)
  delete_file(output_file)
  populate_ks_questions(install_service,install_client,install_ip,install_type)
  process_questions(install_service)
  output_ks_header(install_client,output_file)
  pkg_list = populate_ks_pkg_list(install_service)
  output_ks_pkg_list(install_client,pkg_list,output_file,install_service)
  post_list = populate_ks_post_list(install_arch,install_service,publisher_host,install_client,install_ip)
  output_ks_post_list(install_client,post_list,output_file,install_service)
  return
end

# Create Windows client

def create_packer_pe_install_files(install_client,install_service,install_ip,publisher_host,install_vm,install_license,install_locale,
                                   install_label,install_timezone,install_mirror,install_mac,install_type,install_arch,install_shell,install_network)
  client_dir  = $client_base_dir+"/packer/"+install_vm+"/"+install_client
  output_file = client_dir+"/Autounattend.xml"
  check_dir_exists(client_dir)
  delete_file(output_file)
  populate_pe_questions(install_service,install_client,install_ip,install_mirror,install_type,install_locale,install_license,install_timezone,install_arch,install_label,install_shell,install_vm,install_network)
  process_questions(install_service)
  output_pe_client_profile(install_client,install_ip,install_mac,output_file,install_service,install_type,install_label,install_license,install_shell)
  output_file = client_dir+"/post_install.ps1"
  if File.exist?(output_file)
    %x[rm #{output_file}]
    %x[touch #{output_file}]
  end
  if install_shell.match(/ssh/)
    download_pkg($openssh_win_url)
    openssh_pkg = File.basename($openssh_win_url)
    copy_pkg_to_packer_client(openssh_package,install_client,install_vm)
    openssh_psh = populate_openssh_psh()
    output_psh(install_client,openssh_psh,output_file)
  else
    winrm_psh = populate_winrm_psh()
    output_psh(install_client,winrm_psh,output_file)
  end
  return
end

# Create AutoYast (SLES and OpenSUSE) client

def create_packer_ay_install_files(install_client,install_service,install_ip,install_vm,install_mac,install_type)
  client_dir  = $client_base_dir+"/packer/"+install_vm+"/"+install_client
  output_file = client_dir+"/"+install_client+".xml"
  check_dir_exists(client_dir)
  delete_file(output_file)
  populate_ks_questions(install_service,install_client,install_ip,install_type)
  process_questions(install_service)
  output_ay_client_profile(install_client,install_ip,install_mac,output_file,install_service)
  return
end

# Create Preseed (Ubuntu and Debian) client

def create_packer_ps_install_files(install_client,install_service,install_ip,install_mirror,install_vm,install_mac,install_type)
  client_dir  = $client_base_dir+"/packer/"+install_vm+"/"+install_client
  output_file = client_dir+"/"+install_client+".cfg"
  check_dir_exists(client_dir)
  delete_file(output_file)
  populate_ps_questions(install_service,install_client,install_ip,install_mirror,install_type,install_vm)
  process_questions(install_service)
  output_ps_header(install_client,output_file)
  output_file = client_dir+"/"+install_client+"_post.sh"
  post_list   = populate_ps_post_list(install_client,install_service,install_type,install_vm)
  output_ks_post_list(install_client,post_list,output_file,install_service)
  output_file = client_dir+"/"+install_client+"_first_boot.sh"
  post_list   = populate_ps_first_boot_list()
  output_ks_post_list(install_client,post_list,output_file,install_service)
  return
end

# Create JS client

def create_packer_js_install_files(install_client,install_service,install_ip,install_mirror,install_vm,install_mac,install_type,install_arch,install_file)
  client_dir  = $client_base_dir+"/packer/"+install_vm+"/"+install_client
  output_file = client_dir+"/"+install_client+".cfg"
  check_dir_exists(client_dir)
  delete_file(output_file)
  install_version = install_service.split(/_/)[1]
  install_update  = install_service.split(/_/)[2]
  install_model   = "vm"
  populate_js_sysid_questions(install_client,install_ip,install_arch,install_model,install_version,install_update)
  process_questions(install_service)
  output_file = client_dir+"/sysidcfg"
  create_js_sysid_file(install_client,output_file)
  publisher_host = ""
  install_karch  = "packer"
  populate_js_machine_questions(install_model,install_karch,publisher_host,install_service,install_version,install_update,install_file)
  process_questions(install_service)
  output_file = client_dir+"/profile"
  create_js_machine_file(install_client,output_file)
  output_file   = client_dir+"/rules"
  create_js_rules_file(install_client,install_karch,output_file)
  create_rules_ok_file(install_client,client_dir)
  output_file = client_dir+"/begin"
  output_file = client_dir+"/profile"
  output_file = client_dir+"/finish"
  create_js_finish_file(install_client,output_file)
  process_questions(install_service)
  return
end

# Create AI client

def create_packer_ai_install_files(install_client,install_service,install_ip,install_mirror,install_vm,install_mac,install_type)
  client_dir  = $client_base_dir+"/packer/"+install_vm+"/"+install_client
  output_file = client_dir+"/"+install_client+".cfg"
  check_dir_exists(client_dir)
  delete_file(output_file)
  publisher_host = ""
  publisher_port = ""
  populate_ai_client_profile_questions(publisher_host,publisher_port)
  process_questions(install_service)
  return
end

# Copy package from package directory to packer client directory

def copy_pkg_to_packer_client(pkg_name,install_client,install_vm)
  client_dir = $client_base_dir+"/packer/"+install_vm+"/"+install_client
  if !pkg_name.match(/$pkg_base_dir/)
    source_pkg = $pkg_base_dir+"/"+pkg_name
  else
    source_pkg = pkg_name
  end
  if !File.exist?(source_pkg)
    puts "Warning:\tPackage "+source_pkg+" does not exist"
    exit
  end
  if !File.exist?(dest_pkg)
    dest_pkg = client_dir+"/"+pkg_name
    message  = "Information:\tCopying '"+source_pkg+"' to '"+dest_pkg+"'"
    command  = "cp #{source_pkg} #{dest_pkg}"
    execute_command(message,command)
  end
  return
end

# Configure Packer Windows client

def configure_packer_pe_client(install_client,install_arch,install_mac,install_ip,install_model,publisher_host,install_service,install_file,install_memory,install_cpu,
                               install_network,install_license,install_mirror,install_vm,install_type,install_locale,install_label,install_timezone,install_shell)
  create_packer_pe_install_files(install_client,install_service,install_ip,publisher_host,install_vm,install_license,install_locale,install_label,install_timezone,
                                 install_mirror,install_mac,install_type,install_arch,install_shell,install_network)
  return
end

# Configure Packer vSphere client

def configure_packer_vs_client(install_client,install_arch,install_mac,install_ip,install_model,publisher_host,install_service,install_file,install_memory,install_cpu,
                               install_network,install_license,install_mirror,install_vm,install_type,install_locale,install_label,install_timezone,install_shell)
  create_packer_vs_install_files(install_client,install_service,install_ip,publisher_host,install_vm,install_license,install_mac,install_type)
  return
end

# Configure Packer Kickstart client

def configure_packer_ks_client(install_client,install_arch,install_mac,install_ip,install_model,publisher_host,install_service,install_file,install_memory,install_cpu,
                               install_network,install_license,install_mirror,install_vm,install_type,install_locale,install_label,install_timezone,install_shell)
  create_packer_ks_install_files(install_arch,install_client,install_service,install_ip,publisher_host,install_vm,install_type)
  return
end

# Configure Packer AutoYast client

def configure_packer_ay_client(install_client,install_arch,install_mac,install_ip,install_model,publisher_host,install_service,install_file,install_memory,install_cpu,
                               install_network,install_license,install_mirror,install_vm,install_type,install_locale,install_label,install_timezone,install_shell)
  create_packer_ay_install_files(install_client,install_service,install_ip,install_vm,install_mac,install_type)
  return
end

# Configure Packer Preseed client

def configure_packer_ps_client(install_client,install_arch,install_mac,install_ip,install_model,publisher_host,install_service,install_file,install_memory,install_cpu,
                               install_network,install_license,install_mirror,install_vm,install_type,install_locale,install_label,install_timezone,install_shell)
  create_packer_ps_install_files(install_client,install_service,install_ip,install_mirror,install_vm,install_mac,install_type)
  return
end

# Configure Packer AI client

def configure_packer_ai_client(install_client,install_arch,install_mac,install_ip,install_model,publisher_host,install_service,install_file,install_memory,install_cpu,
                               install_network,install_license,install_mirror,install_vm,install_type,install_locale,install_label,install_timezone,install_shell)
  create_packer_ai_install_files(install_client,install_service,install_ip,install_mirror,install_vm,install_mac,install_type)
  return
end

# Configure Packer JS client

def configure_packer_js_client(install_client,install_arch,install_mac,install_ip,install_model,publisher_host,install_service,install_file,install_memory,install_cpu,
                               install_network,install_license,install_mirror,install_vm,install_type,install_locale,install_label,install_timezone,install_shell)
  create_packer_js_install_files(install_client,install_service,install_ip,install_mirror,install_vm,install_mac,install_type,install_arch,install_file)
  return
end

