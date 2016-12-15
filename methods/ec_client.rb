# Client routines for AWS

# Populate AWS User Data YAML

def populate_aws_user_data_yaml()
	yaml = []
	yaml.push("#cloud-config")
	yaml.push("write_files:")
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

def build_aws_config(install_name,install_access,install_secret,install_region)
	check_packer_is_installed()
	exists = check_if_aws_image_exists(install_name,install_secret,install_region)
	if exists == "yes"
		handle_output("Warning:\tAWS image already exists for '#{install_name}'")
		exit()
	end
	client_dir = $client_base_dir+"/packer/aws/"+install_name
	json_file  = client_dir+"/"+install_name+".json"
	message    = "Information:\tBuilding Packer AWS instance using AMI name '#{install_name}' using '#{json_file}'"
	command    = "packer build #{json_file}"
	execute_command(message,command)
	return
end

# List AWS instances

def list_aws_vms()
	check_aws_cli_is_installed()
	return
end

# Connect to AWS VM

def connect_to_aws_vm(install_access,install_secret,install_region,install_id,install_ip,install_key,install_keyfile,install_admin)
	if !install_admin.match(/[A-Z]|[a-z]|[0-9]/)
		handle_output("Warning:\tNo user given")
		exit()
	end
	if !install_key.match(/[A-Z]|[a-z]|[0-9]/) and !install_keyfile.match(/[A-Z]|[a-z]|[0-9]/)
		handle_output("Warning:\tNo key given")
		exit()
	end
	if !install_id.match(/[0-9]/) and !install_id.match(/[A-Z]|[a-z]|[0-9]/)
		handle_output("Warning:\tNo IP or Instance ID given")
		exit()
	end
	if !install_ip.match(/[0-9]/)
		install_ip = get_aws_instance_ip(install_access,install_secret,install_region,install_id)
	end
	if install_keyfile.match(/[A-Z]|[a-z]|[0-9]/)
		command = "ssh -i #{install_keyfile} #{install_admin}@#{install_ip}"	
	else
		command = "ssh -i #{install_key} #{install_admin}@#{install_ip}"	
	end
	if $verbos_mode == 1
		handle_output("Information:\tExecuting '#{command}'")
	end
	exec "#{command}"
	return
end

# Stop AWS instance

def stop_aws_instance(install_access,install_secret,install_region,install_ami,install_id)
  if install_id.match(/[0-9]/)
  	if install_id.match(/,/)
  		install_ids = install_id.split(/,/)
  	else
  		install_ids = [install_id]
  	end
  	install_ids.each do |install_id|
  		handle_output("Information:\tStopping Instance ID #{install_id}")
	  	ec2 = initiate_aws_ec2_client(install_access,install_secret,install_region)
	  	ec2.stop_instances(instance_ids:[install_id])
	  end
  end
  return
end

# Start AWS instance

def boot_aws_vm(install_access,install_secret,install_region,install_ami,install_id)
  if install_id.match(/[0-9]/)
  	if install_id.match(/,/)
  		install_ids = install_id.split(/,/)
  	else
  		install_ids = [install_id]
  	end
  	install_ids.each do |install_id|
  		handle_output("Information:\tStarting Instance ID #{install_id}")
	  	ec2 = initiate_aws_ec2_client(install_access,install_secret,install_region)
	  	ec2.start_instances(instance_ids:[install_id])
	  end
  end
  return
end

# Delete AWS instance

def delete_aws_vm(install_access,install_secret,install_region,install_ami,install_id)
	if install_id.match(/[0-9]/)
  	if install_id.match(/,/)
  		install_ids = install_id.split(/,/)
  	else
  		install_ids = [install_id]
  	end
  	install_ids.each do |install_id|
	  	ec2 = initiate_aws_ec2_client(install_access,install_secret,install_region)
  		handle_output("Information:\tTerminating Instance ID #{install_id}")
	  	ec2.terminate_instances(instance_ids:[install_id])
	  end
	else
  	if install_id.match(/all/)
  		ec2,reservations = get_aws_reservations(install_access,install_secret,install_region)
			reservations.each do |reservation|
				reservation["instances"].each do |instance|
					install_id = instance.instance_id
					status = instance.state.name
					if !status.match(/terminated/)	
			  		handle_output("Information:\tTerminating Instance ID #{install_id}")
				  	ec2.terminate_instances(instance_ids:[install_id])
				  else
				  	handle_output("Information:\tInstance ID #{install_id} already terminated")
				  end
			  end
			end
		end
  end
	return
end

# Delete AWS instance

def reboot_aws_vm(install_access,install_secret,install_region,install_ami,install_id)
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

# Create AWS image from instance

def create_aws_image(install_name,install_access,install_secret,install_region,install_id)
	if !install_id.match(/[0-9]/)
		handle_output("Warning:\tNo Instance ID specified")
		exit()
	end
	if install_name.match(/[A-Z]|[a-z]|[0-9]/)
		ec2,images = get_aws_images(install_access,install_secret,install_region)
		images.each do |image|
			image_name = image.name
			if image_name.match(/^#{install_name}$/)
				handle_output("Warning:\tImage with name '#{install_name}' already exists")
				exit()
			end
		end
	end
	ec2   	 = initiate_aws_ec2_client(install_access,install_secret,install_region)
	image 	 = ec2.create_image({ dry_run: false, instance_id: install_id, name: install_name })
	image_id = image.image_id
	handle_output("Information:\tCreated image #{image_id} with name '#{install_name}' from instance #{install_id}")
	return
end

# Create AWS instance string

def create_aws_instance(install_access,install_secret,install_region)
  image_id      	= $q_struct["source_ami"].value
  min_count     	= $q_struct["min_count"].value
  max_count    		= $q_struct["max_count"].value
  dry_run    			= $q_struct["dry_run"].value
  instance_type 	= $q_struct["instance_type"].value
  key_name      	= $q_struct["key_name"].value
  security_groups = $q_struct["security_groups"].value
  if security_groups.match(/,/)
  	security_groups = security_groups.split(/,/)
  else
  	security_groups = [ security_groups ]
  end
  if !key_name.match(/[A-Z]|[a-z]|[0-9]/)
  	handle_output("Warning:\tNo key specified")
  	exit()
  end
  if !image_id.match(/^ami/)
  	old_image_id = image_id
  	ec2,image_id = get_aws_image(image_id,install_access,install_secret,install_region)
  	handle_output("Information:\tFound Image ID #{image_id} for #{old_image_id}")
  end
  ec2_resource  = initiate_aws_ec2_resource(install_access,install_secret,install_region)
  instances     = ec2_resource.create_instances(image_id: image_id, min_count: min_count, max_count: max_count, instance_type: instance_type, dry_run: dry_run, key_name: key_name, security_groups: security_groups,)
  instances.each do |instance|
  	instance_id = instance.id
	  handle_output("Information:\tInstance ID:\t#{instance_id}")
  end
end

# Export AWS instance

def export_aws_image(install_access,install_secret,install_region,install_ami,install_id,install_prefix,install_bucket,install_container,install_comment,install_target,install_format,install_acl)
	if $nosuffix == 0
		install_bucket = get_aws_bucket_name(install_name,install_region)
	end
	s3  = create_aws_s3_bucket(install_access,install_secret,install_region,install_bucket)
	ec2 = initiate_aws_ec2_client(install_access,install_secret,install_region)
	begin
		ec2.create_instance_export_task({ description: install_comment, instance_id: install_id, target_environment: install_target, export_to_s3_task: { disk_image_format: install_format, container_format: install_container, s3_bucket: install_bucket, s3_prefix: install_prefix, }, })
	rescue Aws::EC2::Errors::NotExportable
		handle_output("Warning:\tOnly imported instances can be exported")
	end
	return
end

# Configure Packer AWS client

def configure_aws_client(install_name,install_type,install_ami,install_region,install_size,install_access,install_secret,install_number,install_key,install_group)
	if !install_name.match(/[A-Z]|[a-z]|[0-9]/) or install_name.match(/^none$/)
		handle_output("Warning:\tNo name specified for AWS image")
	end
	if $nosuffix == 0
		install_name = get_aws_ami_name(install_name,install_region)
	end
  create_aws_install_files(install_name,install_type,install_ami,install_region,install_size,install_access,install_secret,install_number,install_key,install_group)
  return
end

# Create AWS client

def create_aws_install_files(install_name,install_type,install_ami,install_region,install_size,install_access,install_secret,install_number,install_key,install_group)
	install_keyfile = ""
	user_data_file  = ""
	if !install_ami.match(/^ami/)
		ec2,install_ami = get_aws_image(install_ami,install_access,install_secret,install_region)
	end
  populate_aws_questions(install_name,install_ami,install_region,install_size,install_access,install_secret,user_data_file,install_type,install_number,install_key,install_keyfile,install_group)
  install_service = "aws"
  process_questions(install_service)
  create_aws_instance(install_access,install_secret,install_region)
  return
end
