# Code common to ESX

# Import a disk to ESX

def import_esx_disk(install_client,install_server,install_serveradmin,install_serverpassword,install_datastore,remote_vmx_file,remote_vmdk_file)
	remote_vmdk_file = File.basename(remote_vmdk_file)
	new_vmdk_file    = File.basename(remote_vmdk_file,".old")
	new_vmdk_dir     = Pathname.new(remote_vmdk_file)
	new_vmdk_dir     = new_vmdk_dir.dirname.to_s
	command = "cd "+new_vmdk_dir+" ; vmkfstools -i "+remote_vmdk_file+" -d thin "+new_vmdk_file
	execute_ssh_command(install_server,install_serveradmin,install_serverpassword,command)
	return
end

# Import vmx file to ESX inventory

def import_esx_vm(install_server,install_serveradmin,install_serverpassword,remote_vmx_file)
	command = "vim-cmd solo/registervm "+remote_vmx_file
	execute_ssh_command(install_server,install_serveradmin,install_serverpassword,command)
	return
end