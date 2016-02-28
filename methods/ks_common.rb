
# Common routines for server and client configuration

# Question/config structure

Ks = Struct.new(:type, :question, :ask, :parameter, :value, :valid, :eval)

# Client Linux distribution

def check_linux_distro(linux_distro)
  if !linux_distro.match(/redhat|centos/)
    puts "Warning:\tNo Linux distribution given"
    puts "Use redhat or centos"
    exit
  end
  return
end

# Build alternate RPM list

def build_ks_alt_rpm_list(service_name,client_arch)
  rpm_list = []
  base_url = "http://yum.puppetlabs.com/el/5/"
  dep_url  = base_url+"/dependencies/"+client_arch
  prod_url = base_url+"/products/"+client_arch
  if service_name.match(/[a-z,A-Z]_[5,6]/)
    rpm_suffix    = "el5."+client_arch+".rpm"
    noarch_suffix = "el5.noarch.rpm"
    rpm_list.push("#{dep_url}/#{client_arch}/ruby-1.8.7.374-2.#{rpm_suffix}")
    rpm_list.push("#{dep_url}/#{client_arch}/ruby-augeas-0.4.1-2.#{rpm_suffix}")
    rpm_list.push("#{dep_url}/#{client_arch}/ruby-rgen-0.6.5-1.#{noarch_suffix}")
    rpm_list.push("#{dep_url}/#{client_arch}/ruby-shadow-1.4.1-8.#{rpm_suffix}")
    rpm_list.push("#{dep_url}/#{client_arch}/ruby-libs-1.8.7.374-2.#{rpm_suffix}")
    rpm_list.push("#{dep_url}/#{client_arch}/rubygem-json-1.5.5-2.#{rpm_suffix}")
    rpm_list.push("#{dep_url}/#{client_arch}/augeas-libs-0.10.0-4.#{rpm_suffix}")
    rpm_list.push("#{dep_url}/#{client_arch}/rubygems-1.3.7-1.#{noarch_suffix}")
    rpm_list.push("#{dep_url}/#{client_arch}/ruby-rdoc-1.8.7.374-2.#{rpm_suffix}")
    rpm_list.push("#{dep_url}/#{client_arch}/ruby-irb-1.8.7.374-2.#{rpm_suffix}")
  end
  rpm_list.push("#{prod_url}/facter-#{$facter_version}-1.#{rpm_suffix}")
  hiera_url = prod_url.gsub(/x86_64/,"i386")
  rpm_list.push("#{hiera_url}/hiera-#{$hiera_version}-1.#{noarch_suffix}")
  rpm_list.push("#{prod_url}/puppet-#{$puppet_version}-1.#{noarch_suffix}")
  return rpm_list
end

# Get VSphere info from ISO file name

def get_vsphere_version_info(iso_file_name)
  iso_info     = File.basename(iso_file_name)
  iso_info     = iso_info.split(/-/)
  linux_distro = iso_info[0]
  iso_version  = iso_info[3]
  iso_arch     = iso_info[4].split(/\./)[1]
  return linux_distro,iso_version,iso_arch
end

# List ISOs

def list_ks_isos()
  search_string = "CentOS|rhel|SL|OracleLinux|Fedora"
  iso_list      = check_iso_base_dir(search_string)
  if iso_list.length > 0
    puts "Available Kickstart ISOs:"
    puts
  end
  iso_list.each do |iso_file_name|
    iso_file_name = iso_file_name.chomp
    if iso_file_name.match(/VMvisor/)
      (linux_distro,iso_version,iso_arch) = get_vsphere_version_info(iso_file_name)
    else
      (linux_distro,iso_version,iso_arch) = get_linux_version_info(iso_file_name)
    end
    puts "ISO file:\t"+iso_file_name
    puts "Distribution:\t"+linux_distro
    puts "Version:\t"+iso_version
    puts "Architecture:\t"+iso_arch
    iso_version      = iso_version.gsub(/\./,"_")
    service_name     = linux_distro+"_"+iso_version+"_"+iso_arch
    repo_version_dir = $repo_base_dir+"/"+service_name
    if File.directory?(repo_version_dir)
      puts "Information:\tService Name "+service_name+" (exists)"
    else
      puts "Information:\tService Name "+service_name
    end
    puts
  end
  return
end
