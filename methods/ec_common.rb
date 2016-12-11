# AWS common code

# Initiates AWS EC2 Image connection

def initiate_aws_ec2_image(install_access,install_secret,install_region)
	ec2 = Aws::EC2::Image.new(
		:region 						=>	install_region, 
  	:access_key_id 			=>	install_access,
  	:secret_access_key 	=>	install_secret
	)
	return ec2
end

# Initiate AWS EC2 Instance connection

def initiate_aws_ec2_instance(install_access,install_secret,install_region)
	ec2 = Aws::EC2::Instance.new(
		:region 						=>	install_region, 
  	:access_key_id 			=>	install_access,
  	:secret_access_key 	=>	install_secret
	)
	return ec2
end

# Initiate AWS EC2 Client connection

def initiate_aws_ec2_client(install_access,install_secret,install_region)
	ec2 = Aws::EC2::Client.new(
		:region 						=>	install_region, 
  	:access_key_id 			=>	install_access,
  	:secret_access_key 	=>	install_secret
	)
	return ec2
end

# Initiate and AWS EC2 Resource connection

def initiate_aws_ec2_resource(install_access,install_secret,install_region)
	ec2 = Aws::EC2::Resource.new(
		:region 						=>	install_region, 
  	:access_key_id 			=>	install_access,
  	:secret_access_key 	=>	install_secret
	)
	return ec2
end	

# Get AWS reservations

def get_aws_reservations(install_access,install_secret,install_region)
	ec2    		   = initiate_aws_ec2_client(install_access,install_secret,install_region)
	reservations = ec2.describe_instances({ }).reservations
	return ec2,reservations
end

# List AWS instances

def list_aws_instances(install_access,install_secret,install_region)
	ec2,reservations = get_aws_reservations(install_access,install_secret,install_region)
	reservations.each do |reservation|
		reservation["instances"].each do |instance|
			instance_id = instance.instance_id
			image_id    = instance.image_id
			status      = instance.state.name
			if status.match(/running/)
				public_ip = instance.public_ip_address
			else
				public_ip = "NA"
			end
			string = instance_id+" image="+image_id+" ip="+public_ip+" status="+status
			handle_output(string)
		end
	end
	return
end

# Get list of AWS images

def get_aws_images(install_access,install_secret,install_region)
	ec2    = initiate_aws_ec2_client(install_access,install_secret,install_region)
	images = ec2.describe_images({ owners: ["self"] }).images
	return ec2,images
end

# List AWS images

def list_aws_images(install_access,install_secret,install_region)
	ec2,images = get_aws_images(install_access,install_secret,install_region)
	images.each do |image|
		puts image.name
	end
	return
end

# Get AWS image ID

def get_aws_image(install_client,install_access,install_secret,install_region)
	image_id 	 = "none"
	ec2,images = get_aws_images(install_access,install_secret,install_region)
	images.each do |image|
		if image.name.match(/^#{install_client}/)
			image_id = image.image_id
			return ec2,image_id
		end
	end
	return ec2,image_id
end

# Delete AWS image

def delete_aws_image(install_client,install_access,install_secret,install_region)
	ec2,image_id = get_aws_image(install_client,install_access,install_secret,install_region)
	if image_id == "none"
		handle_output("Warning:\tNo AWS Image exists for '#{install_client}'")
		exit
	else
		handle_output("Information:\tDeleting Image ID #{image_id} for '#{install_client}'")
		ec2.deregister_image({ dry_run: false, image_id: image_id, })
	end
	return
end

# Check if AWS image exists

def check_if_aws_image_exists(install_client,install_access,install_secret,install_region)
	exists     = "no"
	ec2,images = get_aws_images(install_access,install_secret,install_region)
	images.each do |image|
		if image.name.match(/^#{install_client}/)
			exists = "yes"
			return exists
		end
	end
	return exists
end

# Get vagrant version

def get_vagrant_version()
	vagrant_version = %x[$vagrant_bin --version].chomp
	return vagrant_version
end

# Check vagrant aws plugin is installed

def check_vagrant_aws_is_installed()
	check_vagrant_is_installed()
	plugin_list = %x[vagrant plugin list]
	if !plugin_list.match(/aws/)
		message = "Information:\tInstalling Vagrant AWS Plugin"
		command = "vagrant plugin install vagrant-aws"
		execute_command(message,command)
	end
	return
end

# Check vagrant is installed

def check_vagrant_is_installed()
	$vagrant_bin = %x[which vagrant].chomp
	if !$vagrant_bin.match(/vagrant/)
		if $os_name.match(/Darwin/)
			vagrant_pkg = "vagrant_"+$vagrant_version+"_"+$os_name.downcase+".dmg"
			vagrant_url = "https://releases.hashicorp.com/vagrant/"+$vagrant_version+"/"+vagrant_pkg
		else
			if $os_mach.match(/64/)
				vagrant_pkg = "vagrant_"+$vagrant_version+"_"+$os_name.downcase+"_amd64.zip"
				vagrant_url = "https://releases.hashicorp.com/vagrant/"+$vagrant_version+"/"+vagrant_pkg
			else
				vagrant_pkg = "vagrant_"+$vagrant_version+"_"+$os_name.downcase+"_386.zip"
				vagrant_url = "https://releases.hashicorp.com/vagrant/"+$vagrant_version+"/"+vagrant_pkg
			end
		end
		tmp_file = "/tmp/"+vagrant_pkg
		if !File.exist?(tmp_file)
			wget_file(vagrant_url,tmp_file)
		end
		if !File.directory?("/usr/local/bin") and !File.symlink?("/usr/local/bin")
			message = "Information:\tCreating /usr/local/bin"
			command = "mkdir /usr/local/bin"
			execute_command(message,command)
		end
		if $os_name.match(/Darwin/)
			message = "Information:\tMounting Vagrant Image"
			command = "hdiutil attach #{vagrant_pkg}"
			execute_command(message,command)
			message = "Information:\tInstalling Vagrant Image"
			command = "installer -package /Volumes/Vagrant/Vagrant.pkg -target /"
			execute_command(message,command)
		else
			message = "Information:\tInstalling Vagrant"
		end
		execute_command(message,command)
	end
	return
end

# get AWS credentials

def get_aws_creds(install_creds)
	install_access = ""
	install_secret = ""
  if File.exist?(install_creds)
    file_creds = File.readlines(install_creds)
    file_creds.each do |line|
      line = line.chomp
      if !line.match(/^#/)
        if line.match(/:/)
          (install_access,install_secret) = line.split(/:/)
        end
        if line.match(/AWS_ACCESS_KEY|aws_access_key_id/)
        	install_access = line.gsub(/export|AWS_ACCESS_KEY|aws_access_key_id|=|"|\s+/,"")
        end
        if line.match(/AWS_SECRET_KEY|aws_secret_access_key/)
        	install_secret = line.gsub(/export|AWS_SECRET_KEY|aws_secret_access_key|=|"|\s+/,"")
        end
      end
    end
  else
    handle_output("Warning:\tCredentials file '#{install_creds}' does not exit")
  end
	return install_access,install_secret
end

# Check AWS CLI is installed

def check_if_aws_cli_is_installed()
	aws_cli = %x[which aws]
	if !aws_cli.match(/aws/)
		handle_output("Warning:\tAWS CLI not installed")
		if $os_name.match(/Darwin/)
			handle_output("Information:\tInstalling AWS CLI")
			brew_install("awscli")
		end
	end
	return
end

# Create AWS Creds file

def create_aws_creds_file(install_creds,install_access,install_secret)
	file = File.open(install_creds,"w")
	file.write("export AWS_ACCESS_KEY=\"\"\n")
	file.write("export AWS_SECRET_KEY=\"\"\n")
	file.close
	return
end

