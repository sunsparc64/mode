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
  		handle_output("Information:\tStopping Instance ID #{install_id}")
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
  		handle_output("Information:\tStarting Instance ID #{install_id}")
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

# Create AWS image from instance

def create_sdk_aws_image(install_client,install_access,install_secret,install_region,install_id)
	if !install_id.match(/[0-9]/)
		handle_output("Warning:\tNo Instance ID specified")
		exit()
	end
	if install_client.match(/[A-Z]|[a-z]|[0-9]/)
		ec2,images = get_aws_images(install_access,install_secret,install_region)
		images.each do |image|
			image_name = image.name
			if image_name.match(/^#{install_client}$/)
				handle_output("Warning:\tImage with name '#{install_client}' already exists")
				exit()
			end
		end
	end
	ec2   	 = initiate_aws_ec2_client(install_access,install_secret,install_region)
	image 	 = ec2.create_image({ dry_run: false, instance_id: install_id, name: install_client })
	image_id = image.image_id
	handle_output("Information:\tCreated image #{image_id} with name '#{install_client}' from instance #{install_id}")
	return
end

# Create AWS instance string

def create_sdk_aws_instance(install_client,install_access,install_secret,install_region)
  image_id      = $q_struct["source_ami"].value
  min_count     = $q_struct["min_count"].value
  max_count    	= $q_struct["max_count"].value
  dry_run    		= $q_struct["dry_run"].value
  instance_type = $q_struct["instance_type"].value
  ec2_resource  = initiate_aws_ec2_resource(install_access,install_secret,install_region)
  instances     = ec2_resource.create_instances(image_id:image_id, min_count:min_count, max_count:max_count, instance_type:instance_type, dry_run:dry_run)
  instances.each do |instance|
  	instance_id = instance.id
	  handle_output("Information:\tInstance ID:\t#{instance_id}")
  end
end

# Export AWS instance

def export_sdk_aws_image(install_client,install_access,install_secret,install_region,install_ami,install_id,install_prefix,install_bucket,install_container,install_comment,install_target,install_format,install_acl)
	s3 = initiate_aws_s3_client(install_access,install_secret,install_region)
	handle_output("Information:\tCreating S3 bucket: #{install_bucket}")
	location  = s3.create_bucket({ acl: install_acl, bucket: install_bucket, create_bucket_configuration: { location_constraint: install_region, }, }).location
	handle_output("Information:\tBucket location: #{location}")
#	ec2.create_instance_export_task({ description: install_comment, instance_id: install_id, target_environment: install_target, export_to_s3_task: { disk_image_format: install_format, container_format: install_container, s3_bucket: install_bucket, s3_prefix: install_prefix, }, })
	return
end

# Configure Packer AWS client

def configure_sdk_aws_client(install_client,install_type,install_ami,install_region,install_size,install_access,install_secret,install_number)
  create_sdk_aws_install_files(install_client,install_type,install_ami,install_region,install_size,install_access,install_secret,install_number)
  return
end

# Create AWS client

def create_sdk_aws_install_files(install_client,install_type,install_ami,install_region,install_size,install_access,install_secret,install_number)
	user_data_file = ""
	if !install_ami.match(/^ami/)
		if install_client.match(/[A-Z]|[a-z]|[0-9]/)
			ec2,install_ami = get_aws_image(install_client,install_access,install_secret,install_region)
		end
	end
  populate_aws_questions(install_client,install_ami,install_region,install_size,install_access,install_secret,user_data_file,install_type,install_number)
  install_service = "aws"
  process_questions(install_service)
  create_sdk_aws_instance(install_client,install_access,install_secret,install_region)
  return
end
