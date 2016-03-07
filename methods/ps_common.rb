# Common PS code

# List available Ubuntu ISOs

def list_ps_isos()
  search_string = "ubuntu|debian|purity"
  iso_list      = check_iso_base_dir(search_string)
  if iso_list.length > 0
    puts "Available Preseed (Ubuntu/Debian) ISOs:"
    puts
  end
  iso_list.each do |iso_file_name|
	  iso_file_name = iso_file_name.chomp
	  (linux_distro,iso_version,iso_arch) = get_linux_version_info(iso_file_name)
	  puts "ISO file:\t"+iso_file_name
	  puts "Distribution:\t"+linux_distro
	  puts "Version:\t"+iso_version
	  puts "Architecture:\t"+iso_arch
	  iso_version      = iso_version.gsub(/\./,"_")
	  service_name     = linux_distro+"_"+iso_version+"_"+iso_arch
	  repo_version_dir = $repo_base_dir+"/"+service_name
	  if File.directory?(repo_version_dir)
	    puts "Service Name:\t"+service_name+" (exists)"
	  else
	    puts "Service Name:\t"+service_name
	  end
	  puts
	end
  return
end