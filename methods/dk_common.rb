# Common Docker code

# Install docker

def install_docker()
	if $os_name.match(/Darwin/)
		if !Dir.exist?("/Applications/Docker.app")
			puts "Information:\tDocker no installed"
			puts "Download:\thttps://docs.docker.com/docker-for-mac/"
			exit
		end
	end
	return
end

# Get docker image list

def get_docker_image_list()
  message   = "Information:\tListing docker images"
  command   = "docker image list"
  output    = execute_command(message,command)
  images    = output.split(/\n/)
  return images
end

# Get docker instance list

def get_docker_instance_list()
  message   = "Information:\tListing docker images"
  command   = "docker ps"
  output    = execute_command(message,command)
  instances = output.split(/\n/)
  return instances
end

# Get docker image id from name

def get_docker_image_id_from_name(install_client)
  image_id = "none"
  images   = get_docker_image_list
  images.each do |image|
    values     = image.split(/\s+/)
    image_name = values[0]
    image_id   = values[2]
    if image_name.match(/#{install_client}/)
      return image_id
    end
  end
  return image_id
end

# Delete docker image

def delete_docker_image(install_client,install_id)
  if install_id.length > 12 or install_id.match(/[A-Z]|[g-z]/)
    install_id = get_docker_image_id_from_name(install_client)
  end
  if install_id.match(/^#{$empty_value}$/)
    handle_output("Information:\tNo image found")
    quit()
  end
  message   = "Information:\tListing docker images"
  command   = "docker image rm #{install_id}"
  output    = execute_command(message,command)
  handle_output(output)
  return
end

# Check docker is installed

def check_docker_is_installed()
	installed = "yes"
	if $os_name.match(/Darwin/)
		[ "docker", "docker-compose", "docker-machine" ].each do |check_file|
			file_name = "/usr/local/bin/"+check_file
			if !File.exist?(file_name) and !File.symlink?(file_name)
				installed = "no"
			end
		end
	end
	if installed == "no"
		puts "Information:\tDocker not installed"
		exit
	end
	return
end

# List docker instances

def list_docker_instances(install_client,install_id)
  instances = get_docker_instance_list()
	instances.each do |instance|
    if instance.match(/#{install_client}/) or install_client.match(/^#{$empty_value}$|^all$/)
      if instance.match(/#{install_id}/) or install_id.match(/^#{$empty_value}$|^all$/)
        handle_output(instance)
      end
    end
	end
	return
end

# List docker images 

def list_docker_images(install_client,install_id)
  images =get_docker_image_list()
  images.each do |image|
    if image.match(/#{install_client}/) or install_client.match(/^#{$empty_value}$|^all$/)
      if image.match(/#{install_id}/) or install_id.match(/^#{$empty_value}$|^all$/)
        handle_output(image)
      end
    end
  end
  return
end

