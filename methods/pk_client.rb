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
  if !install_vm.match(/[a-z]/)
    install_vm = get_client_vm_type_from_packer(install_client)
  end
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

def list_packer_aws_clients()
  list_packer_clients("aws")
  return
end

def list_packer_clients(install_vm)
  packer_dir = $client_base_dir+"/packer"
  if !install_vm.match(/[a-z,A-Z]/) or install_vm.match(/none/)
    vm_types = [ 'fusion', 'vbox', 'aws' ]
  else
    vm_types = []
    vm_types.push(install_vm)
  end
  vm_types.each do |vm_type|
    vm_dir = packer_dir+"/"+vm_type
    if File.directory?(vm_dir)
      handle_output("")
      case vm_type
      when /vbox/
        vm_title = "VirtualBox"
      when /aws/
        vm_title = "AWS"
      else
        vm_title = "VMware Fusion"
      end
      vm_list = Dir.entries(vm_dir)
      if vm_list.length > 0
        if $output_format.match(/html/)
          handle_output("<h1>Available Packer #{vm_title} clients</h1>")
          handle_output("<table border=\"1\">")
          handle_output("<tr>")
          handle_output("<th>VM</th>")
          handle_output("<th>OS</th>")
          handle_output("</tr>")
        else
          handle_output("Packer #{vm_title} clients:")
          handle_output("")
        end
        vm_list.each do |vm_name|
          if vm_name.match(/[a-z,A-Z]/)
            json_file = vm_dir+"/"+vm_name+"/"+vm_name+".json"
            if File.exist?(json_file)
              json  = File.readlines(json_file)
              if vm_type.match(/aws/)
                vm_os = "AMI"
              else
                vm_os = json.grep(/guest_os_type/)[0].split(/:/)[1].split(/"/)[1]
              end
              if $output_format.match(/html/)
                handle_output("<tr>")
                handle_output("<td>#{vm_name}</td>")
                handle_output("<td>#{vm_os}</td>")
                handle_output("</tr>")
              else
                handle_output("#{vm_name} os=#{vm_os}")
              end
            end
          end
        end
        if $output_format.match(/html/)
          handle_output("</table>")
        else
          handle_output("")
        end
      end
    end
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
	if $verbose_mode == true
		handle_output("Information:\tDeleting Packer Image for #{install_client}")
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
    	if $verbose_mode == true
    		handle_output("Information:\tDeleting file #{file_name}")
    	end
    	File.delete(file_name)
    end
  end
  if Dir.exist?(image_dir)
  	if $verbose_mode == true
  		handle_output("Information:\tDeleting directory #{image_dir}")
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
  handle_output("Information:\tMaking sure no existing Packer processes are running for #{install_client}")
  %x[ps -ef |grep packer |grep "#{install_client}.json" |awk '{print $2}' |xargs kill]
  return
end

# Create a packer config

def configure_packer_client(install_method,install_vm,install_os,install_client,install_arch,install_mac,install_ip,install_model,
                            publisherhost,install_service,install_file,install_memory,install_cpu,install_network,install_license,
                            install_mirror,install_size,install_type,install_locale,install_label,install_timezone,install_shell)

  if !$default_host
    $default_host = get_default_host()
  end
  if !$default_host.match(/[0-9,a-z,A-Z]/)
  end
  uid = %x[id -u].chomp
  check_dir_exists($client_base_dir)
  check_dir_owner($client_base_dir,uid)
	exists = eval"[check_#{install_vm}_vm_exists(install_client)]"
	if exists == "yes"
    if install_vm.match(/vbox/)
  		handle_output("Warning:\tVirtualBox VM #{install_client} already exists")
    else
      handle_output("Warning:\tVMware Fusion VM #{install_client} already exists")
    end
		exit
	end
	exists = check_packer_image_exists(install_client,install_vm)
	if exists == "yes"
    if install_vm.match(/vbox/)
  		handle_output("Warning:\tPacker image for VirtualBox VM #{install_client} already exists")
    else
      handle_output("Warning:\tPacker image for VMware Fusion VM #{install_client} already exists")
    end
		exit
	end
  (install_service,install_os,install_method,install_release,install_arch,install_label) = get_packer_install_service(install_file)
	install_guest = eval"[get_#{install_vm}_guest_os(install_method,install_arch)]"
	eval"[configure_packer_#{install_method}_client(install_client,install_arch,install_mac,install_ip,install_model,publisherhost,install_service,install_file,install_memory,
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
    if install_vm.match(/vbox/)
      handle_output("Warning:\tVirtualBox VM #{install_client} already exists")
    else
      handle_output("Warning:\tVMware Fusion VM #{install_client} already exists")
    end
    exit
  end
  exists = check_packer_image_exists(install_client,install_vm)
  client_dir = $client_base_dir+"/packer/"+install_vm+"/"+install_client
  json_file  = client_dir+"/"+install_client+".json"
  if !File.exist?(json_file)
    handle_output("Warning:\tJSON configuration file \"#{json_file}\" for #{install_client} does not exist")
    exit
  end
	message = "Information:\tBuilding Packer Image "+json_file
	command = "packer build "+json_file
  if $verbose_mode == true
    handle_output(message)
    handle_output("Executing:\t"+command)
  end
  exec(command)
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

def create_packer_vs_install_files(install_client,install_service,install_ip,publisherhost,install_vm,install_license,install_mac,install_type)
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
  print_contents_of_file("",output_file)
  return
end

# Create Kickstart Packer client (RHEL, CentOS, SL, and OEL)

def create_packer_ks_install_files(install_arch,install_client,install_service,install_ip,publisherhost,install_vm,install_type)
  client_dir  = $client_base_dir+"/packer/"+install_vm+"/"+install_client
  output_file = client_dir+"/"+install_client+".cfg"
  check_dir_exists(client_dir)
  delete_file(output_file)
  populate_ks_questions(install_service,install_client,install_ip,install_type)
  process_questions(install_service)
  output_ks_header(install_client,output_file)
  pkg_list = populate_ks_pkg_list(install_service)
  output_ks_pkg_list(install_client,pkg_list,output_file,install_service)
  post_list = populate_ks_post_list(install_arch,install_service,publisherhost,install_client,install_ip,install_vm)
  output_ks_post_list(install_client,post_list,output_file,install_service)
  return
end

# Create Windows client

def create_packer_pe_install_files(install_client,install_service,install_ip,publisherhost,install_vm,install_license,install_locale,
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
    vmtools_psh = populate_vmtools_psh()
    output_psh(install_client,vmtools_psh,output_file)
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
  post_list   = populate_ps_first_boot_list(install_service)
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
  publisherhost = ""
  install_karch  = "packer"
  populate_js_machine_questions(install_model,install_karch,publisherhost,install_service,install_version,install_update,install_file)
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
  publisherhost = ""
  publisherport = ""
  populate_ai_client_profile_questions(publisherhost,publisherport)
  process_questions(install_service)
  return
end

# Populate vagrant.sh array

def populate_packer_vagrant_sh(install_name)
  tmp_keyfile = "/tmp/"+install_name+".key.pub"
  file_array  = []
  file_array.push("#!/usr/bin/env bash\n")
  file_array.push("\n")
  file_array.push("groupadd vagrant\n")
  file_array.push("useradd vagrant -g vagrant -G wheel\n")
  file_array.push("echo \"vagrant\" | passwd --stdin vagrant\n")
  file_array.push("echo \"vagrant        ALL=(ALL)       NOPASSWD: ALL\" >> /etc/sudoers.d/99-vagrant\n")
  file_array.push("\n")
  file_array.push("mkdir /home/vagrant/.ssh\n")
  file_array.push("\n")
  file_array.push("# Use my own private key\n")
  file_array.push("cat  #{tmp_keyfile} >> /home/vagrant/.ssh/authorized_key\n")
  file_array.push("chown -R vagrant /home/vagrant/.ssh\n")
  file_array.push("chmod -R go-rwsx /home/vagrant/.ssh\n")
  return file_array
end

# Create vagrant.sh array

def create_packer_vagrant_sh(install_name,file_name)
  file_array = populate_packer_vagrant_sh(install_name)
  write_array_to_file(file_array,file_name,"w")
  return
end

# Create AWS client

def create_packer_aws_install_files(install_name,install_type,install_ami,install_region,install_size,install_access,install_secret,install_number,install_key,install_keyfile,install_group,install_desc,install_ports)
  if !install_number.match(/[0,9]/)
    handle_output("Warning:\tIncorrect number of instances specified: '#{install_number}'")
    quit()
  end
  install_name,install_key,install_keyfile,install_group,install_ports = handle_aws_values(install_name,install_key,install_keyfile,install_access,install_secret,install_region,install_group,install_desc,install_type,install_ports)
  exists = check_if_aws_image_exists(install_name,install_access,install_secret,install_region)
  if exists == "yes"
    handle_output("Warning:\tAWS AMI already exists with name #{install_name}")
    exit
  end
  if !install_ami.match(/^ami/)
    old_install_ami = install_ami
    ec2,install_ami = get_aws_image(old_install_ami,install_access,install_secret,install_region)
    if install_ami.match(/^none$/)
      handle_output("Warning:\tNo AWS AMI ID found for #{old_install_ami}")
      install_ami = $default_aws_ami
      handle_output("Information:\tSetting AWS AMI ID to #{install_ami}")
    else
      handle_output("Information:\tFound AWS AMI ID #{install_ami} for #{old_install_ami}")
    end
  end
  client_dir     = $client_base_dir+"/packer/aws/"+install_name
  script_dir     = client_dir+"/scripts"
  build_dir      = client_dir+"/builds"
  user_data_file = "userdata.yml"
  check_dir_exists(client_dir)
  check_dir_exists(script_dir)
  check_dir_exists(build_dir)
  populate_aws_questions(install_name,install_ami,install_region,install_size,install_access,install_secret,user_data_file,install_type,install_number,install_key,install_keyfile,install_group,install_ports)
  install_service = "aws"
  process_questions(install_service)
  user_data_file = client_dir+"/userdata.yml"
  create_aws_user_data_file(user_data_file)
  create_packer_aws_json()
  file_name = script_dir+"/vagrant.sh"
  create_packer_vagrant_sh(install_name,file_name)
  key_file = client_dir+"/"+install_name+".key.pub"
  if !File.exist?(key_file)
    message  = "Copying Key file '#{install_keyfile}' to '#{key_file}' ; chmod 600 #{key_file}"
    command  = "cp #{install_keyfile} #{key_file}"
    execute_command(message,command)
  end
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
    handle_output("Warning:\tPackage #{source_pkg} does not exist")
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

# Build AWS client

def build_packer_aws_config(install_name,install_access,install_secret,install_region)
  exists = check_if_aws_image_exists(install_name,install_access,install_secret,install_region)
  if exists == "yes"
    handle_output("Warning:\tAWS image already exists for '#{install_name}'")
    exit
  end
  client_dir = $client_base_dir+"/packer/aws/"+install_name
  json_file  = client_dir+"/"+install_name+".json"
  key_file   = client_dir+"/"+install_name+".key.pub"
  if !File.exist?(json_file)
    handle_output("Warning:\tPacker AWS config file '#{json_file}' does not exist")
    exit
  end
  if !File.exist?(key_file) and !File.symlink?(key_file)
    handle_output("Warning:\tPacker AWS key file '#{key_file}' does not exist")
    exit
  end
  message    = "Information:\tCodesigning /usr/local/bin/packer"
  command    = "/usr/bin/codesign --verify /usr/local/bin/packer"
  execute_command(message,command)
  message    = "Information:\tBuilding Packer AWS instance using AMI name '#{install_name}' using '#{json_file}'"
  command    = "cd #{client_dir} ; /usr/local/bin/packer build #{json_file}"
  execute_command(message,command)
  return
end

# Configure Packer AWS client

def configure_packer_aws_client(install_name,install_type,install_ami,install_region,install_size,install_access,install_secret,install_number,install_key,install_keyfile,install_group,install_desc,install_ports)
  create_packer_aws_install_files(install_name,install_type,install_ami,install_region,install_size,install_access,install_secret,install_number,install_key,install_keyfile,install_group,install_desc,install_ports)
  return
end

# Configure Packer Windows client

def configure_packer_pe_client(install_client,install_arch,install_mac,install_ip,install_model,publisherhost,install_service,install_file,install_memory,install_cpu,
                               install_network,install_license,install_mirror,install_vm,install_type,install_locale,install_label,install_timezone,install_shell)
  create_packer_pe_install_files(install_client,install_service,install_ip,publisherhost,install_vm,install_license,install_locale,install_label,install_timezone,
                                 install_mirror,install_mac,install_type,install_arch,install_shell,install_network)
  return
end

# Configure Packer vSphere client

def configure_packer_vs_client(install_client,install_arch,install_mac,install_ip,install_model,publisherhost,install_service,install_file,install_memory,install_cpu,
                               install_network,install_license,install_mirror,install_vm,install_type,install_locale,install_label,install_timezone,install_shell)
  create_packer_vs_install_files(install_client,install_service,install_ip,publisherhost,install_vm,install_license,install_mac,install_type)
  return
end

# Configure Packer Kickstart client

def configure_packer_ks_client(install_client,install_arch,install_mac,install_ip,install_model,publisherhost,install_service,install_file,install_memory,install_cpu,
                               install_network,install_license,install_mirror,install_vm,install_type,install_locale,install_label,install_timezone,install_shell)
  create_packer_ks_install_files(install_arch,install_client,install_service,install_ip,publisherhost,install_vm,install_type)
  return
end

# Configure Packer AutoYast client

def configure_packer_ay_client(install_client,install_arch,install_mac,install_ip,install_model,publisherhost,install_service,install_file,install_memory,install_cpu,
                               install_network,install_license,install_mirror,install_vm,install_type,install_locale,install_label,install_timezone,install_shell)
  create_packer_ay_install_files(install_client,install_service,install_ip,install_vm,install_mac,install_type)
  return
end

# Configure Packer Preseed client

def configure_packer_ps_client(install_client,install_arch,install_mac,install_ip,install_model,publisherhost,install_service,install_file,install_memory,install_cpu,
                               install_network,install_license,install_mirror,install_vm,install_type,install_locale,install_label,install_timezone,install_shell)
  create_packer_ps_install_files(install_client,install_service,install_ip,install_mirror,install_vm,install_mac,install_type)
  return
end

# Configure Packer AI client

def configure_packer_ai_client(install_client,install_arch,install_mac,install_ip,install_model,publisherhost,install_service,install_file,install_memory,install_cpu,
                               install_network,install_license,install_mirror,install_vm,install_type,install_locale,install_label,install_timezone,install_shell)
  create_packer_ai_install_files(install_client,install_service,install_ip,install_mirror,install_vm,install_mac,install_type)
  return
end

# Configure Packer JS client

def configure_packer_js_client(install_client,install_arch,install_mac,install_ip,install_model,publisherhost,install_service,install_file,install_memory,install_cpu,
                               install_network,install_license,install_mirror,install_vm,install_type,install_locale,install_label,install_timezone,install_shell)
  create_packer_js_install_files(install_client,install_service,install_ip,install_mirror,install_vm,install_mac,install_type,install_arch,install_file)
  return
end
