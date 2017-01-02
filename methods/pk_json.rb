
# Packer JSON code

# Configure Packer JSON file

def create_packer_json(install_method,install_client,install_vm,install_arch,install_file,install_guest,install_size,install_memory,install_cpu,install_network,install_mac,install_ip,install_label)
  nic_command1      = ""
  nic_command2      = ""
  nic_config1       = ""
  nic_config1       = ""
  communicator      = "winrm"
  hw_version        = "12"
  ks_ip             = $default_gateway
  winrm_use_ssl     = "false"
  winrm_insecure    = "true"
  virtual_dev       = "lsisas1068"
  ethernet_type     = "static"
  ethernet_dev      = "e1000"
  vnc_enabled       = "true"
  vhv_enabled       = "TRUE"
  ethernet_enabled  = "TRUE"
  boot_wait         = "2m"
  shutdown_timeout  = "1h"
  ssh_port          = "22"
  hwvirtex          = "off"
  audio             = "none"
  mouse             = "ps2"
  ssh_pty           = "true"
  winrm_port        = "5985"
  headless_mode     = $q_struct["headless_mode"].value
  if install_ip.match(/[0-9]/)
    port_no = install_ip.split(/\./)[-1]
    if port_no.to_i < 100
      port_no = "0"+port_no
    end
    vnc_port_min = "6"+port_no
    vnc_port_max = "6"+port_no
  else
    vnc_port_min = "5900"
    vnc_port_max = "5980"
  end
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
    ks_ip        = $default_gateway
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
    ssh_password   = $default_adminpassword
    admin_username = $default_admin_user
    admin_password = $default_adminpassword
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
    if $vmtools_mode == true
      if !install_label.match(/2016/)
        tools_upload_flavor = "windows"
        tools_upload_path   = "C:\\Windows\\Temp\\windows.iso"
      end
    end
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
                   "<wait>27<enter><wait>"+
                   "<wait>3<enter><wait>"+
                   "<wait10><wait10><wait10><wait10>"+
                   "<wait10><wait10><wait10><wait10>"+
                   "<wait10><wait10><wait10><wait10>"+
                   "<wait>1<enter><wait10><wait10>"+
                   "<wait><f2><wait10>"+
                   "<wait><f2><wait10>"+
                   "<wait><f2><wait10>"+
                   "<wait><f2><wait10>"+
                   "<wait><bs><bs><bs><bs><bs><bs><bs>"+install_client+"<wait>"+
                   "<wait><f2><wait10>"+
                   "<wait><tab><f2><wait>"+
                   install_ip+"<wait><tab><wait><tab>"+
                   $default_gateway+"<wait><f2><wait>"+
                   "<wait><f2><wait>"+
                   $default_nameserver+"<wait><f2><wait>"+
                   "<wait><f2><wait10>"+
                   "<wait><f2><wait10>"+
                   "<wait><f2><wait10>"+
                   "<wait><f2><wait10>"+
                   "<wait><f2><wait10>"+
                   "<wait><f2><wait10>"+
                   "<wait><f2><wait10>"+
                   $q_struct["root_password"].value+"<wait><tab><wait>"+
                   $q_struct["root_password"].value+"<wait><tab><wait>"+
                   $q_struct["admin_username"].value+"<wait><tab><wait>"+
                   $q_struct["admin_username"].value+"<wait><tab><wait>"+
                   $q_struct["admin_password"].value+"<wait><tab><wait>"+
                   $q_struct["admin_password"].value+"<wait><f2><wait>"+
                   "<wait><f2><wait10>"+
                   "<wait><f2><wait10>"+
                   "<wait><f2><wait10>"+
                   "<wait10><wait10><wait10><wait10>"+
                   "<wait10><wait10><wait10><wait10>"+
                   "<wait10><wait10><wait10><wait10>"+
                   "<wait10><wait10><wait10><wait10>"+
                   "<wait10><wait10><wait10><wait10>"+
                   "<wait10><wait10><wait10><wait10>"+
                   "<wait10><wait10><wait10><wait10>"+
                   "<wait10><wait10><wait10><wait10>"+
                   "<wait10><wait10><wait10><wait10>"+
                   "<wait><f8><wait10><wait10>"+
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
                   $default_gateway+"<wait><f2><wait>"+
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
    if install_service.match(/ubuntu_16/)
      tools_upload_flavor = ""
    else
      tools_upload_flavor = "linux"
    end
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
    shutdown_command = "echo 'shutdown -P now' > /tmp/shutdown.sh ; echo '#{$q_struct["admin_password"].value}'|sudo -S sh '/tmp/shutdown.sh'"
  when /vsphere|esx|vmware/
    hwvirtex         = "on"
    ks_file          = install_vm+"/"+install_client+"/"+install_client+".cfg"
    ks_url           = "http://#{ks_ip}:#{$default_httpd_port}/"+ks_file
    boot_command     = "<enter><wait>O<wait> ks="+ks_url+" ksdevice=vmnic0 netdevice=vmnic0 ip="+install_ip+" netmask="+$default_netmask+" gateway="+$default_gateway+"<wait><enter><wait>"
    ssh_username     = "root"
    shutdown_command = ""
    ssh_wait_timeout = "30m"
  when /fedora/
    tools_upload_flavor = "linux"
    tools_upload_path   = "/home/"+$q_struct["admin_username"].value
    ks_file          = install_vm+"/"+install_client+"/"+install_client+".cfg"
    ks_url           = "http://#{ks_ip}:#{$default_httpd_port}/"+ks_file
    boot_command     = "<tab><wait><bs><bs><bs><bs><bs><bs>=0 inst.text inst.method=cdrom inst.repo=cdrom:/dev/sr0 inst.sshd inst.ks="+ks_url+" ip="+install_ip+" netmask="+$default_netmask+" gateway="+$default_gateway+"<enter><wait>"
#  when /rhel_7/
#    ks_file       = install_vm+"/"+install_client+"/"+install_client+".cfg"
#    ks_url        = "http://#{ks_ip}:#{$default_httpd_port}/"+ks_file
#    boot_command  = "<esc><wait> linux text install ks="+ks_url+" ksdevice=eno16777736 "+"ip="+install_ip+" netmask="+$default_netmask+" gateway="+$default_gateway+"<enter><wait>"
  else
    ks_file       = install_vm+"/"+install_client+"/"+install_client+".cfg"
    ks_url        = "http://#{ks_ip}:#{$default_httpd_port}/"+ks_file
    boot_command  = "<esc><wait> linux text install ks="+ks_url+" ip="+install_ip+" netmask="+$default_netmask+" gateway="+$default_gateway+"<enter><wait>"
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
	if $checksum_mode == true
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
            :headless             => headless_mode,
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
            :headless             => headless_mode,
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
            :headless             => headless_mode,
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
            :headless             => headless_mode,
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
            :headless             => headless_mode,
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
            :headless             => headless_mode,
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
              :headless             => headless_mode,
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
            :headless             => headless_mode,
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
            :headless             => headless_mode,
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
            :headless             => headless_mode,
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
            :headless             => headless_mode,
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
            :headless             => headless_mode,
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
  print_contents_of_file("",json_file)
  return communicator
end

# Create Packer JSON file for AWS

def create_packer_aws_json()
  install_service = $q_struct["type"].value
  install_access  = $q_struct["access_key"].value
  install_secret  = $q_struct["secret_key"].value
  install_ami     = $q_struct["source_ami"].value
  install_region  = $q_struct["region"].value
  install_size    = $q_struct["instance_type"].value
  install_admin   = $q_struct["ssh_username"].value
  install_keyfile = File.basename($q_struct["keyfile"].value,".pem")+".key.pub"
  install_client  = $q_struct["ami_name"].value
  tmp_keyfile     = "/tmp/"+install_keyfile
  user_data_file  = $q_struct["user_data_file"].value
  packer_dir      = $client_base_dir+"/packer"
  client_dir      = packer_dir+"/aws/"+install_client
  json_file       = client_dir+"/"+install_client+".json"
  check_dir_exists(client_dir)
  json_data = {
    :builders => [
      {
        :name             => "aws",
        :type             => install_service,
        :access_key       => install_access,
        :secret_key       => install_secret,
        :source_ami       => install_ami,
        :region           => install_region,
        :instance_type    => install_size,
        :ssh_username     => install_admin,
        :ami_name         => install_client,
        :user_data_file   => user_data_file
      }
    ],
    :provisioners => [
      {
        :type             => "file",
        :source           => install_keyfile,
        :destination      => tmp_keyfile
      },
      {
        :type             => "shell",
        :execute_command  => "{{ .Vars }} sudo -E -S sh '{{ .Path }}'",
        :scripts          => [
          "scripts/vagrant.sh"
        ]
      }
    ],
    :"post-processors"    => [
      {
        :output           => "builds/packer_{{.BuildName}}_{{.Provider}}.box",
        :type             => "vagrant"
      }
    ]
  }
  json_output = JSON.pretty_generate(json_data)
  delete_file(json_file)
  File.write(json_file,json_output)
  set_file_perms(json_file,"600")
  print_contents_of_file("",json_file)
  return
end

