# Docker client code

# List docker VMs

def list_docker_clients()
	message = "Information:\tListing docker instances"
	command = "docker-machine ls"
	output  = execute_command(message,command)
	puts output
	return
end


# Check docker VM exists

def check_docker_exists(install_client)
	exists  = "no"
	message = "Information:\tChecking docker instances for #{install_client}"
	command = "docker-machine ls"
	output  = execute_command(message,command)
	output  = output.split(/\n/)
	output.each do |line|
		line  = line.chomp
		items = line.split(/\s+/)
		host  = items[0]
		if host.match(/^#{install_client}$/)
			exists = "yes"
			return exists
		end
	end
	return exists
end

# Add docker client

def configure_docker_client(install_vm,install_client,install_ip,install_network)
	install_docker()
	if install_vm.match(/box/)
		if install_network.match(/hostonly/)
			if install_ip.empty?
				install_ip = $default_vbox_ip
			end
		end
		docker_vm = "virtualbox"
	else
		if install_network.match(/hostonly/)
			if install_ip.empty?
				install_ip = $default_fusion_ip
			end
		end
		docker_vm = "vmwarefusion"
	end
	exists = check_docker_exists(install_client)
	if exists == "no"
		message = "Information:\tCreating docker VM #{install_client}"
		if install_vm.match(/box/)
			if !install_ip.empty?
				command = "docker-machine create --driver #{docker_vm} --#{docker_vm}-hostonly-cidr #{install_ip}/#{$default_cidr} #{install_client}"
			else
				command = "docker-machine create --driver #{docker_vm} #{install_client}"
			end
		else
			command = "docker-machine create --driver #{docker_vm} #{install_client}"
		end
		execute_command(message,command)
	else
		handle_output("Information:\tDocker instance '#{install_client}' already exists")
	end
	return
end

def unconfigure_docker_client(install_client)
	exists = check_docker_exists(install_client)
	if exists == "yes"
		message = "Information:\tDeleting docker instance #{install_client}"
		command = "docker-machine rm --force #{install_client}"
		execute_command(message,command)
	else
		handle_output("Information:\tDocker instance #{install_client} does not exist")
	end
	return
end
