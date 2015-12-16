# Common packer code

# Check packer is installed

def check_packer_is_installed()
	$packer_bin = %x[which packer].chomp
	if !$packer_bin.match(/packer/)
		if $os_arch.match(/64/)
			packer_bin = "packer_"+$packer_version+"_"+$os_name.downcase+"_amd64.zip"
			packer_url = "https://releases.hashicorp.com/packer/"+$packer_version+"/"+packer_bin
		else
			packer_url = "packer_"+$packer_version+"_"+$os_name.downcase+"_386.zip"
			packer_url = "https://releases.hashicorp.com/packer/"+$packer_version+"/"+packer_bin
		end
		message = "Information:\tFetching Packer from "+packer_url
		command = "wget -O /tmp/#{packer_bin} #{packer_url}"
		execute_command(message,command)
		message = "Information:\tExtracting and installing Packer"
		command = "cd /usr/bin ; /tmp/#{packer_bin}"
		execute_command(message,command)
	end
	return
end