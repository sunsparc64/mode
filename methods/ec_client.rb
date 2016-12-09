# Client routines for AWS

# Populate AWS User Data YAML

def populate_aws_user_data_yaml()
	yaml = []
	yaml.push("#cloud-config")
	yaml.push("write-files:")
	yaml.push("- path: /etc/sudoers.d/99-requiretty")
	yaml.push("  permissions: 440")
	yaml.push("  content: |")
	yaml.push("    Defaults !requiretty")
	return yaml
end

# Create Userdata yaml file

def create_aws_user_data_file(output_file)
	yaml = populate_aws_user_data_yaml()
	file = File.open(output_file,"w")
  yaml.each do |item|
    line = item+"\n"
    file.write(line)
  end
  file.close
	print_contents_of_file("",output_file)
  return
end

# Build AWS client

def build_aws_config(install_access,install_secret,install_region,install_client)
	check_packer_is_installed()
	exists = check_if_aws_image_exists(install_access,install_secret,install_region,install_client)
	if exists == "yes"
		handle_output("Warning:\tAWS image already exists for '#{install_client}'")
		exit
	end
	client_dir = $client_base_dir+"/packer/aws/"+install_client
	json_file  = client_dir+"/"+install_client+".json"
	message    = "Information:\tBuilding Packer AWS instance '#{install_client}' using '#{json_file}'"
	command    = "packer build #{json_file}"
	execute_command(message,command)
	return
end

# List AWS instances

def list_aws_vms()
	check_aws_cli_is_installed()
	return
end

# Stop AWS instance

def stop_aws_instance(install_client,install_access,install_secret,install_region,install_ami,install_id)
  if $nosuffix == 0
    install_client = get_aws_ami_name(install_client,install_region)
  end
  if install_id.match(/[0-9]/)
  	if install_id.match(/,/)
  		install_ids = install_id.split(/,/)
  	else
  		install_ids = [install_id]
  	end
  	install_ids.each do |install_id|
  		handle_output("Information\tStopping Instance ID #{install_id}")
	  	ec2 = initiate_aws_ec2_client(install_access,install_secret,install_region)
	  	ec2.stop_instances(instance_ids:[install_id])
	  end
  end
  return
end

# Start AWS instance

def boot_aws_vm(install_client,install_access,install_secret,install_region,install_ami,install_id)
  if $nosuffix == 0
    install_client = get_aws_ami_name(install_client,install_region)
  end
  if install_id.match(/[0-9]/)
  	if install_id.match(/,/)
  		install_ids = install_id.split(/,/)
  	else
  		install_ids = [install_id]
  	end
  	install_ids.each do |install_id|
  		handle_output("Information\tStarting Instance ID #{install_id}")
	  	ec2 = initiate_aws_ec2_client(install_access,install_secret,install_region)
	  	ec2.start_instances(instance_ids:[install_id])
	  end
  end
  return
end

# Delete AWS instance

def delete_aws_vm(install_client,install_access,install_secret,install_region,install_ami,install_id)
  if $nosuffix == 0
	  install_client = get_aws_ami_name(install_client,install_region)
	end
	if install_id.match(/[0-9]/)
  	if install_id.match(/,/)
  		install_ids = install_id.split(/,/)
  	else
  		install_ids = [install_id]
  	end
  	install_ids.each do |install_id|
  		handle_output("Information\tDeleting Instance ID #{install_id}")
	  	ec2 = initiate_aws_ec2_client(install_access,install_secret,install_region)
	  	ec2.terminate_instances(instance_ids:[install_id])
	  end
  end
	return
end

# Delete AWS instance

def reboot_aws_vm(install_client,install_access,install_secret,install_region,install_ami,install_id)
  if $nosuffix == 0
	  install_client = get_aws_ami_name(install_client,install_region)
	end
	if install_id.match(/[0-9]/)
  	if install_id.match(/,/)
  		install_ids = install_id.split(/,/)
  	else
  		install_ids = [install_id]
  	end
  	install_ids.each do |install_id|
  		handle_output("Information\tRebooting Instance ID #{install_id}")
	  	ec2 = initiate_aws_ec2_client(install_access,install_secret,install_region)
	  	ec2.reboot_instances(instance_ids:[install_id])
	  end
  end
	return
end

# Create JSON file for AWS SDK

def create_sdk_aws_json()
  install_service = $q_struct["type"].value
  install_access  = $q_struct["access_key"].value
  install_secret  = $q_struct["secret_key"].value
  install_ami     = $q_struct["source_ami"].value
  install_region  = $q_struct["region"].value
  install_size    = $q_struct["instance_type"].value
  install_admin   = $q_struct["ssh_username"].value
  install_client  = $q_struct["ami_name"].value
  user_data_file  = $q_struct["user_data_file"].value
  client_dir      = $client_base_dir+"/aws/"+install_client
  json_file       = client_dir+"/"+install_client+".json"
  check_dir_exists(client_dir)
  json_data = {
    :builders => [
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
    ]
  }
  json_output = JSON.pretty_generate(json_data)
  delete_file(json_file)
  File.write(json_file,json_output)
  print_contents_of_file("",json_file)
  return json_data
end

# Configure Packer AWS client

def configure_sdk_aws_client(install_client,install_type,install_ami,install_region,install_size,install_access,install_secret)
  create_sdk_aws_install_files(install_client,install_type,install_ami,install_region,install_size,install_access,install_secret)
  return
end

# Create AWS client

def create_sdk_aws_install_files(install_client,install_type,install_ami,install_region,install_size,install_access,install_secret)
  client_dir     = $client_base_dir+"/aws/"+install_client
  user_data_file = client_dir+"/userdata.yaml"
  check_dir_exists(client_dir)
  populate_aws_questions(install_client,install_ami,install_region,install_size,install_access,install_secret,user_data_file,install_type)
  install_service = "aws"
  process_questions(install_service)
  create_aws_user_data_file(user_data_file)
  create_packer_aws_json()
  return
end
