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