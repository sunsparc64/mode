# Common PS code

# List available Ubuntu ISOs

def list_ps_isos()
  search_string = "ubuntu|debian|purity"
  iso_list      = check_iso_base_dir(search_string)
  if iso_list.length > 0
    handle_output("Available Preseed (Ubuntu/Debian) ISOs:")
   	handle_output("") 
  end
  iso_list.each do |iso_file_name|
	  iso_file_name = iso_file_name.chomp
	  (linux_distro,iso_version,iso_arch) = get_linux_version_info(iso_file_name)
	  handle_output("ISO file:\t#{iso_file_name}")
	  handle_output("Distribution:\t#{linux_distro}")
	  handle_output("Version:\t#{iso_version}")
	  handle_output("Architecture:\t#{iso_arch}")
	  iso_version      = iso_version.gsub(/\./,"_")
	  service_name     = linux_distro+"_"+iso_version+"_"+iso_arch
	  repo_version_dir = $repo_base_dir+"/"+service_name
	  if File.directory?(repo_version_dir)
	    handle_output("Service Name:\t#{service_name} (exists)")
	  else
	    handle_output("Service Name:\t#{service_name}")
	  end
	 	handle_output("") 
	end
  return
end