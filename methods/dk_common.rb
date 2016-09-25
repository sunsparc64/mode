# Common Docker code

# Install docker

def install_docker()
	if $os_name.match(/Darwin/)
		[ "docker", "docker-compose", "docker-machine" ].each do |check_file|
			file_name = "/usr/local/bin/"+check_file
			if !File.exist?(file_name) and !File.symlink?(file_name)
				message = "Information:\tInstalling #{check_file}"
				command = "brew install #{check_file}"
				execute_command(message,command)
			end
		end
	end
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

