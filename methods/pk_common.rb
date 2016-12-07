# Common packer code

# Get packer version

def get_packer_version()
	packer_version = %x[#{$packer_bin} --version].chomp
	return packer_version
end

# Check packer is installed

def check_packer_is_installed()
	$packer_bin = %x[which packer].chomp
	if $packer_bin.match(/packer/)
		packer_version = get_packer_version
		packer_version = packer_version.split(/\./)[1]
		packer_version = packer_version.to_i
	else
		packer_version = 0
	end
	if !$packer_bin.match(/packer/) or packer_version < 12
		if $packer_bin.match(/packer/) and packer_version < 12
			handle_output("Warning:\tOlder version of Packer found")
			handle_output("Warning:\tUpgrading Packer")
		end
		if $os_mach.match(/64/)
			packer_bin = "packer_"+$packer_version+"_"+$os_name.downcase+"_amd64.zip"
			packer_url = "https://releases.hashicorp.com/packer/"+$packer_version+"/"+packer_bin
		else
			packer_bin = "packer_"+$packer_version+"_"+$os_name.downcase+"_386.zip"
			packer_url = "https://releases.hashicorp.com/packer/"+$packer_version+"/"+packer_bin
		end
		tmp_file = "/tmp/"+packer_bin
		if !File.exist?(tmp_file)
			wget_file(packer_url,tmp_file)
		end
		if !File.directory?("/usr/local/bin") and !File.symlink?("/usr/local/bin")
			message = "Information:\tCreating /usr/local/bin"
			command = "mkdir /usr/local/bin"
			execute_command(message,command)
		end
		message = "Information:\tExtracting and installing Packer"
		command = "cd /tmp ; unzip -o #{tmp_file} ; cp /tmp/packer /usr/local/bin ; chmod +x /usr/local/bin/packer"
		execute_command(message,command)
	end
	return
end
