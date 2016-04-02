# Common packer code

# Check packer is installed

def check_packer_is_installed()
	$packer_bin = %x[which packer].chomp
	if !$packer_bin.match(/packer/)
		if $os_mach.match(/64/)
			packer_bin = "packer_"+$packer_version+"_"+$os_name.downcase+"_amd64.zip"
			packer_url = "https://releases.hashicorp.com/packer/"+$packer_version+"/"+packer_bin
		else
			packer_bin = "packer_"+$packer_version+"_"+$os_name.downcase+"_386.zip"
			packer_url = "https://releases.hashicorp.com/packer/"+$packer_version+"/"+packer_bin
		end
		tmp_file = "/tmp/"+packer_bin
		if !File.exist?(tmp_file)
			message = "Information:\tFetching Packer from "+packer_url
			command = "wget -O #{tmp_file} #{packer_url}"
			execute_command(message,command)
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
