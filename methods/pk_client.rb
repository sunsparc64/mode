# Configure Packer client

# Configure Packer JSON file

def create_packer_ks_json(install_client,install_vm,install_arch,install_file,install_guest,install_size,install_memory,install_cpu)
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
	packer_dir = $client_base_dir+"/packer"
  client_dir = packer_dir+"/"+install_client
  image_dir  = client_dir+"/images"
  ks_file    = install_client+"/"+install_client+".cfg"
  json_file  = client_dir+"/"+install_client+".json"
  check_dir_exists(client_dir)
	install_guest = install_guest.join
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
  		:iso_checksum 				=> install_checksum,
  		:iso_checksum_type		=> install_checksum_type,
  		:http_directory 			=> packer_dir,
  		:boot_command      		=> "<esc><wait>linux ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/#{ks_file}<enter><wait>",
			:vboxmanage => [
				[ "modifyvm", "{{.Name}}", "--memory", install_memory ],
				[ "modifyvm", "{{.Name}}", "--cpus", install_cpu ],
			]
		]
  }
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

def check_packer_image_exists(install_client)
	packer_dir = $client_base_dir+"/packer"
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

def unconfigure_packer_client(install_client)
	if $verbose_mode == 1
		puts "Information:\tDeleting Packer Image for "+install_client
	end
	packer_dir = $client_base_dir+"/packer"
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
	exists = check_vbox_vm_exists(install_client)
	if exists == "yes"
		puts "Warning:\tVirtualBox VM "+install_client+" already exists "
		exit
	end
	exists = check_packer_image_exists(install_client)
	if exists == "yes"
		puts "Warning:\tPacker image for VirtualBox VM "+install_client+" already exists "
		exit
	end
	install_guest = eval"[get_#{install_vm}_guest_os(install_method,install_arch)]"
	eval"[configure_packer_#{install_method}_client(install_client,install_arch,install_mac,install_ip,install_model,publisher_host,install_service,install_file,install_memory,install_cpu,install_network,install_license,install_mirror)]"
	eval"[create_packer_#{install_method}_json(install_client,install_vm,install_arch,install_file,install_guest,install_size,install_memory,install_cpu)]"
	#build_packer_config(install_client)
	return
end

# Build a packer config

def build_packer_config(install_client)
  client_dir = $client_base_dir+"/packer/"+install_client
  json_file  = client_dir+"/"+install_client+".json"
	message    = "Information:\tBuilding Packer Image "+json_file
	command    = "packer build "+json_file
	execute_command(message,command)
	return
end

# Configure Packer Kickstart client

def configure_packer_ks_client(install_client,install_arch,install_mac,install_ip,install_model,publisher_host,install_service,install_file,install_memory,install_cpu,install_network,install_license,install_mirror)
  client_dir  = $client_base_dir+"/packer/"+install_client
  output_file = client_dir+"/"+install_client+".cfg"
  check_dir_exists(client_dir)
  delete_file(output_file)
  (linux_distro,iso_version,iso_arch) = get_linux_version_info(install_file)
  iso_version     = iso_version.gsub(/\./,"_")
  install_service = install_service+"_"+linux_distro+"_"+iso_version+"_"+iso_arch
  populate_ks_questions(install_service,install_client,install_ip)
  process_questions(install_service)
  output_ks_header(install_client,output_file)
  pkg_list = populate_ks_pkg_list(install_service)
  output_ks_pkg_list(install_client,pkg_list,output_file,install_service)
  post_list = populate_ks_post_list(install_client,install_service,publisher_host)
  output_ks_post_list(install_client,post_list,output_file,install_service)
  return
end