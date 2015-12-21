# Packer client related commands

def get_packer_client_dir(install_client,install_vm)
  packer_dir = $client_base_dir+"/packer"
  client_dir = packer_dir+"/"+install_vm+"/"+install_client
  return client_dir
end

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
  if !install_vm.match(/[A-z]/)
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
        if vm_name.match(/[A-z]/)
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

def create_packer_json(install_method,install_client,install_vm,install_arch,install_file,install_guest,install_size,install_memory,install_cpu,install_network,install_mac,install_ip)
  nic_command1 = ""
  nic_command2 = ""
  nic_config1  = ""
  nic_config1  = ""
  ks_ip        = $default_host
  if $default_vm_network.match(/hostonly/)
    if_name  = get_bridged_vbox_nic()
    nic_name = check_vbox_hostonly_network(if_name)
    nic_command1 = "--nic1"
    nic_config1  = "hostonly"
    nic_command2 = "--hostonlyadapter1"
    nic_config2  = "#{nic_name}"
    ks_ip        = $default_gateway_ip
  end
  if $default_vm_network.match(/bridged/)
    nic_name = get_bridged_vbox_nic()
    nic_command1 = "--nic1"
    nic_config1  = "bridged"
    nic_command2 = "--bridgeadapter1"
    nic_config2  = "#{nic_name}"
  end
  install_size     = install_size.gsub(/G/,"000")
  install_service  = get_packer_install_service(install_file)
  ssh_username     = $default_admin_user
  ssh_password     = $default_admin_password
  ssh_wait_timeout = "600s"
  shutdown_command = ""
  case install_service
  when /sles/
    ks_file      = install_client+"/"+install_client+".xml"
    ks_url       = "http://#{ks_ip}:#{$default_httpd_port}/"+ks_file
    boot_command = "<esc><wait> linux text install=cdrom autoyast="+ks_url+" language="+$default_language+" ip="+install_ip+" netmask="+$default_netmask+" gateway="+$default_gateway_ip+"<enter><wait>"
  when /debian|ubuntu/
    ks_file      = install_client+"/"+install_client+".cfg"
    ks_url       = "http://#{ks_ip}:#{$default_httpd_port}/"+ks_file
    boot_command = "linux text install auto=true priority=critical preseed/url="+ks_url+" console-keymaps-at/keymap=us locale=en_US hostname="+install_client+" ip="+install_ip+" netmask="+$default_netmask+" gateway="+$default_gateway_ip+"<enter><wait>"
  when /vsphere|esx|vmware/
    ks_file          = install_client+"/"+install_client+".cfg"
    ks_url           = "http://#{ks_ip}:#{$default_httpd_port}/"+ks_file
    boot_command     = "<enter><wait>O<wait> ks="+ks_url+" ksdevice=vmnic0 netdevice=vmnic0 ip="+install_ip+" netmask="+$default_netmask+" gateway="+$default_gateway_ip+"<wait><enter><wait>"
    ssh_username     = "root"
    ssh_password     = $default_root_password
    shutdown_command = "esxcli system maintenanceMode set -e true -t 0 ; esxcli system shutdown poweroff -d 10 -r 'Packer Shutdown' ; esxcli system maintenanceMode set -e false -t 0"
    ssh_wait_timeout = "60m"
  when /fedora/
    ks_file          = install_client+"/"+install_client+".cfg"
    ks_url           = "http://#{ks_ip}:#{$default_httpd_port}/"+ks_file
    boot_command     = "<tab><wait><bs><bs><bs><bs><bs><bs>=0 inst.text inst.method=cdrom inst.repo=cdrom:/dev/sr0 inst.sshd inst.ks="+ks_url+" ip="+install_ip+" netmask="+$default_netmask+" gateway="+$default_gateway_ip+"<enter><wait>"
    ssh_wait_timeout = "1200s"
  else
    ks_file      = install_client+"/"+install_client+".cfg"
    ks_url       = "http://#{ks_ip}:#{$default_httpd_port}/"+ks_file
    boot_command = "<esc><wait> linux text install ks="+ks_url+" ip="+install_ip+" netmask="+$default_netmask+" gateway="+$default_gateway_ip+"<enter><wait>"
  end
	$vbox_disk_type = $vbox_disk_type.gsub(/sas/,"scsi")
	case install_vm
	when /vbox|virtualbox/
		install_type = "virtualbox-iso"
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
	packer_dir = $client_base_dir+"/packer/"+install_vm
  client_dir = packer_dir+"/"+install_client
  image_dir  = client_dir+"/images"
  json_file  = client_dir+"/"+install_client+".json"
  check_dir_exists(client_dir)
	install_guest = install_guest.join
  if install_vm.match(/vbox/)
    if install_mac.match(/[0-9]|[A-z]/)
      if $default_vm_network.match(/hostonly|bridged/)
        json_data = {
        	:variables => {
        		:hostname => install_client
        	},
        	:builders => [
        		:name 								=> install_client,
        		:vm_name							=> install_client,
        		:type 								=> install_type,
        		:guest_os_type 				=> install_guest,
        		:hard_drive_interface => $vbox_disk_type,
        		:output_directory     => image_dir,
        		:disk_size						=> install_size,
        		:iso_url 							=> iso_url,
        		:ssh_username					=> ssh_username,
        		:ssh_password       	=> ssh_password,
            :ssh_wait_timeout     => ssh_wait_timeout,
            :shutdown_command     => shutdown_command,
        		:iso_checksum 				=> install_checksum,
        		:iso_checksum_type		=> install_checksum_type,
        		:http_directory 			=> packer_dir,
            :http_port_min        => $default_httpd_port,
            :http_port_max        => $default_httpd_port,
        		:boot_command      		=> boot_command,
      			:vboxmanage => [
      				[ "modifyvm", "{{.Name}}", "--memory", install_memory ],
      				[ "modifyvm", "{{.Name}}", "--cpus", install_cpu ],
              [ "modifyvm", "{{.Name}}", nic_command1, nic_config1 ],
              [ "modifyvm", "{{.Name}}", nic_command2, nic_config2 ],
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
            :ssh_username         => ssh_username,
            :ssh_password         => ssh_password,
            :ssh_wait_timeout     => ssh_wait_timeout,
            :shutdown_command     => shutdown_command,
            :iso_checksum         => install_checksum,
            :iso_checksum_type    => install_checksum_type,
            :http_directory       => packer_dir,
            :http_port_min        => $default_httpd_port,
            :http_port_max        => $default_httpd_port,
            :boot_command         => boot_command,
            :vboxmanage => [
              [ "modifyvm", "{{.Name}}", "--memory", install_memory ],
              [ "modifyvm", "{{.Name}}", "--cpus", install_cpu ],
            ]
          ]
        }
      end  
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
          :ssh_username         => ssh_username,
          :ssh_password         => ssh_password,
          :ssh_wait_timeout     => ssh_wait_timeout,
          :shutdown_command     => shutdown_command,
          :iso_checksum         => install_checksum,
          :iso_checksum_type    => install_checksum_type,
          :http_directory       => packer_dir,
          :http_port_min        => $default_httpd_port,
          :http_port_max        => $default_httpd_port,
          :boot_command         => boot_command,
          :vboxmanage => [
            [ "modifyvm", "{{.Name}}", "--memory", install_memory ],
            [ "modifyvm", "{{.Name}}", "--cpus", install_cpu ],
            [ "modifyvm", "{{.Name}}", "--macaddress", install_mac ],
          ]
        ]
      }
    end
  else
    if install_mac.match(/[0-9]|[A-z]/)
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
          :iso_checksum         => install_checksum,
          :iso_checksum_type    => install_checksum_type,
          :http_directory       => packer_dir,
          :http_port_min        => $default_httpd_port,
          :http_port_max        => $default_httpd_port,
          :boot_command         => boot_command,
          :vmx_data => {
            :memsize                            => "#{install_memory}",
            :numvcpus                           => "#{install_cpu}",
            :"vhv.enable"                       => "TRUE",
            :"ethernet0.present"                => "TRUE",
            :"ethernet0.startConnected"         => "TRUE",
            :"ethernet0.virtualDev"             => "e1000",
            :"ethernet0.networkName"            => "VM Network",
            :"ethernet0.addressType"            => "static",
            :"ethernet0.address"                => "#{install_mac}",
            :"ethernet0.wakeOnPcktRcv"          => "FALSE",
            :"ethernet0.connectionType"         => "#{install_network}"
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
          :iso_checksum         => install_checksum,
          :iso_checksum_type    => install_checksum_type,
          :http_directory       => packer_dir,
          :boot_command         => boot_command,
          :vmx_data => {
            :memsize                            => install_memory,
            :numvcpus                           => install_cpu,
            :"vhv.enable"                       => "TRUE",
            :"ethernet0.present"                => "TRUE",
            :"ethernet0.startConnected"         => "TRUE",
            :"ethernet0.virtualDev"             => "e1000",
            :"ethernet0.networkName"            => "VM Network",
            :"ethernet0.addressType"            => "generated",
            :"ethernet0.generatedAddressOffset" => "0",
            :"ethernet0.wakeOnPcktRcv"          => "FALSE",
            :"ethernet0.connectionType"         => install_network
          }
        ]
      }
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
  return
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
  	Dir.delete(image_dir)
  end
	return
end

# Create a packer config

def configure_packer_client(install_method,install_vm,install_os,install_client,install_arch,install_mac,install_ip,install_model,publisher_host,install_service,
                            install_file,install_memory,install_cpu,install_network,install_license,install_mirror,install_size,install_type)
  if !$default_host.match(/[0-9]|[A-z]/)
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
	install_guest = eval"[get_#{install_vm}_guest_os(install_method,install_arch)]"
	eval"[configure_packer_#{install_method}_client(install_client,install_arch,install_mac,install_ip,install_model,publisher_host,install_service,
        install_file,install_memory,install_cpu,install_network,install_license,install_mirror,install_vm,install_type)]"
	create_packer_json(install_method,install_client,install_vm,install_arch,install_file,install_guest,install_size,install_memory,install_cpu,install_network,install_mac,install_ip)
	#build_packer_config(install_client,install_vm)
	return
end

# Build a packer config

def build_packer_config(install_client,install_vm)
  exists = eval"[check_#{install_vm}_vm_exists(install_client)]"
  if exists.to_s.match(/yes/)
    puts "Warning:\tVirtualBox VM "+install_client+" already exists "
    exit
  end
  exists = check_packer_image_exists(install_client,install_vm)
  client_dir = $client_base_dir+"/packer/"+install_vm+"/"+install_client
  json_file  = client_dir+"/"+install_client+".json"
	message    = "Information:\tBuilding Packer Image "+json_file
	command    = "packer build "+json_file
	execute_command(message,command)
	return
end

# Get Packer install service

def get_packer_install_service(install_file)
  install_service = get_install_service_from_file(install_file)
#  (linux_distro,iso_version,iso_arch) = get_linux_version_info(install_file)
#  iso_version     = iso_version.gsub(/\./,"_")
#  install_service = "packer_"+linux_distro+"_"+iso_version+"_"+iso_arch
  return install_service
end

# Get Packer install config file


def create_packer_vs_install_files(install_client,install_service,install_ip,publisher_host,install_vm,install_license)
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

def create_packer_ay_install_files(install_client,install_service,install_ip,install_vm)
  client_dir  = $client_base_dir+"/packer/"+install_vm+"/"+install_client
  output_file = client_dir+"/"+install_client+".xml"
  check_dir_exists(client_dir)
  delete_file(output_file)
  populate_ks_questions(install_service,install_client,install_ip,install_type)
  process_questions(install_service)
  output_ay_client_profile(install_client,install_ip,install_mac,output_file,install_service)
  return
end

def create_packer_ps_install_files(install_client,install_service,install_ip,install_mirror,install_vm)
  client_dir  = $client_base_dir+"/packer/"+install_vm+"/"+install_client
  populate_ps_questions(install_service,install_client,install_ip,install_mirror)
  process_questions(install_service)
  output_ps_header(install_client,output_file)
  output_file = client_dir+"/"+install_client+"_post.sh"
  post_list   = populate_ps_post_list(install_client,install_service)
  output_ks_post_list(install_client,post_list,output_file,install_service)
  output_file = client_dir+"/"+install_client+"_first_boot.sh"
  post_list   = populate_ps_first_boot_list()
  output_ks_post_list(install_client,post_list,output_file,install_service)
  return
end

# Configure Packer vSphere client

def configure_packer_vs_client(install_client,install_arch,install_mac,install_ip,install_model,publisher_host,install_service,
                               install_file,install_memory,install_cpu,install_network,install_license,install_mirror,install_vm,install_type)
  install_service = get_packer_install_service(install_file)
  create_packer_vs_install_files(install_client,install_service,install_ip,publisher_host,install_vm,install_license)
  return
end

# Configure Packer Kickstart client

def configure_packer_ks_client(install_client,install_arch,install_mac,install_ip,install_model,publisher_host,install_service,
                               install_file,install_memory,install_cpu,install_network,install_license,install_mirror,install_vm,install_type)
  install_service = get_packer_install_service(install_file)
  create_packer_ks_install_files(install_arch,install_client,install_service,install_ip,publisher_host,install_vm,install_type)
  return
end

# Configure Packer AutoYast client

def configure_packer_ay_client(install_client,install_arch,install_mac,install_ip,install_model,publisher_host,install_service,
                               install_file,install_memory,install_cpu,install_network,install_license,install_mirror,install_vm,install_type)
  install_service = get_packer_install_service(install_file)
  create_packer_ay_install_files(install_client,install_service,install_ip,install_vm)
  return
end

# Configure Packer Preseed client

def configure_packer_ps_client(install_client,install_arch,install_mac,install_ip,install_model,publisher_host,install_service,
                               install_file,install_memory,install_cpu,install_network,install_license,install_mirror,install_vm,install_type)
  install_service = get_packer_install_service(install_file)
  create_packer_ps_install_files(install_client,install_service,install_ip,install_mirror,install_vm)
  return
end
