# Configure Packer client

# Configure Packer JSON file

def create_packer_json(install_method,install_client,install_vm,install_arch,install_file,install_guest,install_size,install_memory,install_cpu)
  install_size    = install_size.gsub(/G/,"000")
  install_service = get_packer_install_service(install_file)
  case install_service
  when /sles/
    ks_file      = install_client+"/"+install_client+".xml"
    ks_url       = "http://{{ .HTTPIP }}:{{ .HTTPPort }}/"+ks_file
    boot_command = "<esc><wait> linux text install=cdrom autoyast="+ks_url+" language="+$default_language+"<enter><wait>"
  when /debian|ubuntu/
    ks_file      = install_client+"/"+install_client+".cfg"
    ks_url       = "http://{{ .HTTPIP }}:{{ .HTTPPort }}/"+ks_file
    boot_command = "linux text install auto=true priority=critical preseed/url="+ks_url+" console-keymaps-at/keymap=us locale=en_US hostname="+install_client+"<enter><wait>"
  when /vsphere|esx|vmware/
    ks_file      = install_client+"/"+install_client+".cfg"
    ks_url       = "http://{{ .HTTPIP }}:{{ .HTTPPort }}/"+ks_file
    boot_command = "<enter><wait>O<wait> ks="+ks_url+"<enter><wait>"
  else
    ks_file      = install_client+"/"+install_client+".cfg"
    ks_url       = "http://{{ .HTTPIP }}:{{ .HTTPPort }}/"+ks_file
    boot_command = "<esc><wait> linux text install ks="+ks_url+"<enter><wait>"
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
	if $default_vm_network.match(/bridged/)
    vbox_nic_name = get_bridged_vbox_nic()
  end
	iso_url    = "file://"+install_file
	packer_dir = $client_base_dir+"/packer/"+install_vm
  client_dir = packer_dir+"/"+install_client
  image_dir  = client_dir+"/images"
  json_file  = client_dir+"/"+install_client+".json"
  check_dir_exists(client_dir)
	install_guest = install_guest.join
  if install_vm.match(/vbox/)
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
    		:ssh_username					=> $default_admin_user,
    		:ssh_password       	=> $default_admin_password,
        :ssh_wait_timeout     => "600s",
    		:iso_checksum 				=> install_checksum,
    		:iso_checksum_type		=> install_checksum_type,
    		:http_directory 			=> packer_dir,
    		:boot_command      		=> boot_command,
  			:vboxmanage => [
  				[ "modifyvm", "{{.Name}}", "--memory", install_memory ],
  				[ "modifyvm", "{{.Name}}", "--cpus", install_cpu ],
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
        :ssh_username         => $default_admin_user,
        :ssh_password         => $default_admin_password,
        :ssh_wait_timeout     => "600s",
        :iso_checksum         => install_checksum,
        :iso_checksum_type    => install_checksum_type,
        :http_directory       => packer_dir,
        :boot_command         => boot_command,
        :vmx_data => {
          :memsize  => install_memory,
          :numvcpus => install_cpu
        }
      ]
    }
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
	packer_dir = $client_base_dir+"/packer"+install_vm
  client_dir = packer_dir+"/"+install_client
  image_dir  = client_dir+"/images"
  ovf_file   = image_dir+"/"+install_client+".ovf"
  disk_file  = image_dir+"/"+install_client+"-disk1.vmdk"
  if File.exist?(ovf_file)
  	if $verbose_mode == 1
  		puts "Information:\tDeleting file "+ovf_file
  	end
  	File.delete(ovf_file)
  end
  if File.exist?(disk_file)
  	if $verbose_mode == 1
  		puts "Information:\tDeleting file "+disk_file
  	end
  	File.delete(disk_file)
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

def configure_packer_client(install_method,install_vm,install_os,install_client,install_arch,install_mac,install_ip,install_model,publisher_host,install_service,install_file,install_memory,install_cpu,install_network,install_license,install_mirror,install_size)
	exists = eval"[check_#{install_vm}_vm_exists(install_client)]"
	if exists == "yes"
		puts "Warning:\tVirtualBox VM "+install_client+" already exists "
		exit
	end
	exists = check_packer_image_exists(install_client,install_vm)
	if exists == "yes"
		puts "Warning:\tPacker image for VirtualBox VM "+install_client+" already exists "
		exit
	end
	install_guest = eval"[get_#{install_vm}_guest_os(install_method,install_arch)]"
	eval"[configure_packer_#{install_method}_client(install_client,install_arch,install_mac,install_ip,install_model,publisher_host,install_service,install_file,install_memory,install_cpu,install_network,install_license,install_mirror,install_vm)]"
	create_packer_json(install_method,install_client,install_vm,install_arch,install_file,install_guest,install_size,install_memory,install_cpu)
	#build_packer_config(install_client,install_vm)
	return
end

# Build a packer config

def build_packer_config(install_client,install_vm)
  client_dir = $client_base_dir+"/packer/"+install_vm+"/"+install_client
  json_file  = client_dir+"/"+install_client+".json"
	message    = "Information:\tBuilding Packer Image "+json_file
	command    = "packer build "+json_file
	execute_command(message,command)
	return
end

# Get Packer install service

def get_packer_install_service(install_file)
  (linux_distro,iso_version,iso_arch) = get_linux_version_info(install_file)
  iso_version     = iso_version.gsub(/\./,"_")
  install_service = "packer_"+linux_distro+"_"+iso_version+"_"+iso_arch
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
  post_list = populate_vs_firstboot_list(install_service,install_license)
  output_vs_post_list(post_list,output_file)
  # Output post list
  post_list = populate_vs_post_list(install_service)
  output_vs_post_list(post_list,output_file)
  return
end

def create_packer_ks_install_files(install_client,install_service,install_ip,publisher_host,install_vm)
  client_dir  = $client_base_dir+"/packer/"+install_vm+"/"+install_client
  output_file = client_dir+"/"+install_client+".cfg"
  check_dir_exists(client_dir)
  delete_file(output_file)
  populate_ks_questions(install_service,install_client,install_ip)
  process_questions(install_service)
  output_ks_header(install_client,output_file)
  pkg_list = populate_ks_pkg_list(install_service)
  output_ks_pkg_list(install_client,pkg_list,output_file,install_service)
  post_list = populate_ks_post_list(install_client,install_service,publisher_host)
  output_ks_post_list(install_client,post_list,output_file,install_service)
  return
end

def create_packer_ay_install_files(install_client,install_service,install_ip,install_vm)
  client_dir  = $client_base_dir+"/packer/"+install_vm+"/"+install_client
  output_file = client_dir+"/"+install_client+".xml"
  check_dir_exists(client_dir)
  delete_file(output_file)
  populate_ks_questions(install_service,install_client,install_ip)
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

def configure_packer_vs_client(install_client,install_arch,install_mac,install_ip,install_model,publisher_host,install_service,install_file,install_memory,install_cpu,install_network,install_license,install_mirror,install_vm)
  install_service = get_packer_install_service(install_file)
  create_packer_vs_install_files(install_client,install_service,install_ip,publisher_host,install_vm,install_license)
  return
end

# Configure Packer Kickstart client

def configure_packer_ks_client(install_client,install_arch,install_mac,install_ip,install_model,publisher_host,install_service,install_file,install_memory,install_cpu,install_network,install_license,install_mirror,install_vm)
  install_service = get_packer_install_service(install_file)
  create_packer_ks_install_files(install_client,install_service,install_ip,publisher_host,install_vm)
  return
end

# Configure Packer AutoYast client

def configure_packer_ay_client(install_client,install_arch,install_mac,install_ip,install_model,publisher_host,install_service,install_file,install_memory,install_cpu,install_network,install_license,install_mirror,install_vm)
  install_service = get_packer_install_service(install_file)
  create_packer_ay_install_files(install_client,install_service,install_ip,install_vm)
  return
end

# Configure Packer Preseed client

def configure_packer_ps_client(install_client,install_arch,install_mac,install_ip,install_model,publisher_host,install_service,install_file,install_memory,install_cpu,install_network,install_license,install_mirror,install_vm)
  install_service = get_packer_install_service(install_file)
  create_packer_ps_install_files(install_client,install_service,install_ip,install_mirror,install_vm)
  return
end
