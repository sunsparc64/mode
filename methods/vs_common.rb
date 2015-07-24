
# Common routines for server and client configuration

# Question/config structure

Vs = Struct.new(:type, :question, :ask, :parameter, :value, :valid, :eval)

def check_promisc_mode()
  promisc_file="/Library/Preferences/VMware Fusion/promiscAuthorized"
  if !File.exists?(promisc_file)
    %x[sudo touch "/Library/Preferences/VMware Fusion/promiscAuthorized"]
  end
  return
end

# List available ISOs

def list_vs_isos()
  search_string = "VMvisor"
  iso_list      = check_iso_base_dir(search_string)
  if iso_list.length > 0
	puts "Available vSphere ISOs:"
  	puts
  end
  iso_list.each do |iso_file|
    iso_file    = iso_file.chomp
    iso_info    = File.basename(iso_file)
    iso_info    = iso_info.split(/-/)
    vs_distro   = iso_info[0]
    vs_distro   = vs_distro.downcase
    iso_version = iso_info[3]
    iso_arch    = iso_info[4].split(/\./)[1]
    iso_release = iso_info[4].split(/\./)[0]
    puts "ISO file:\t"+iso_file
    puts "Distribution:\t"+vs_distro
    puts "Version:\t"+iso_version
    puts "Release:\t"+iso_release
    puts "Architecture:\t"+iso_arch
    iso_version      = iso_version.gsub(/\./,"_")
    service_name     = vs_distro+"_"+iso_version+"_"+iso_arch
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