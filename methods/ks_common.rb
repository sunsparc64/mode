
# Common routines for server and client configuration

# Question/config structure

Ks = Struct.new(:type, :question, :ask, :parameter, :value, :valid, :eval)

# Client Linux distribution

def check_linux_distro(linux_distro)
  if !linux_distro.match(/redhat|centos/)
    handle_output("Warning:\tNo Linux distribution given")
    handle_output("Use redhat or centos")
    exit
  end
  return
end

# Build alternate RPM list

def build_ks_alt_rpm_list(install_service,install_arch)
  rpm_list = []
  base_url = "http://yum.puppetlabs.com/el/5/"
  dep_url  = base_url+"/dependencies/"+install_arch
  prod_url = base_url+"/products/"+install_arch
  if install_service.match(/[a-z,A-Z]_[5,6]/)
    rpm_suffix    = "el5."+install_arch+".rpm"
    noarch_suffix = "el5.noarch.rpm"
    rpm_list.push("#{dep_url}/#{install_arch}/ruby-1.8.7.374-2.#{rpm_suffix}")
    rpm_list.push("#{dep_url}/#{install_arch}/ruby-augeas-0.4.1-2.#{rpm_suffix}")
    rpm_list.push("#{dep_url}/#{install_arch}/ruby-rgen-0.6.5-1.#{noarch_suffix}")
    rpm_list.push("#{dep_url}/#{install_arch}/ruby-shadow-1.4.1-8.#{rpm_suffix}")
    rpm_list.push("#{dep_url}/#{install_arch}/ruby-libs-1.8.7.374-2.#{rpm_suffix}")
    rpm_list.push("#{dep_url}/#{install_arch}/rubygem-json-1.5.5-2.#{rpm_suffix}")
    rpm_list.push("#{dep_url}/#{install_arch}/augeas-libs-0.10.0-4.#{rpm_suffix}")
    rpm_list.push("#{dep_url}/#{install_arch}/rubygems-1.3.7-1.#{noarch_suffix}")
    rpm_list.push("#{dep_url}/#{install_arch}/ruby-rdoc-1.8.7.374-2.#{rpm_suffix}")
    rpm_list.push("#{dep_url}/#{install_arch}/ruby-irb-1.8.7.374-2.#{rpm_suffix}")
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
    handle_output("Available Kickstart ISOs:")
    handle_output("") 
  end
  iso_list.each do |iso_file_name|
    iso_file_name = iso_file_name.chomp
    if iso_file_name.match(/VMvisor/)
      (linux_distro,iso_version,iso_arch) = get_vsphere_version_info(iso_file_name)
    else
      (linux_distro,iso_version,iso_arch) = get_linux_version_info(iso_file_name)
    end
    handle_output("ISO file:\t#{iso_file_name}")
    handle_output("Distribution:\t#{linux_distro}")
    handle_output("Version:\t#{iso_version}")
    handle_output("Architecture:\t#{iso_arch}")
    iso_version      = iso_version.gsub(/\./,"_")
    install_service  = linux_distro+"_"+iso_version+"_"+iso_arch
    repo_version_dir = $repo_base_dir+"/"+install_service
    if File.directory?(repo_version_dir)
      handle_output("Information:\tService Name #{install_service} (exists)")
    else
      handle_output("Information:\tService Name #{install_service}")
    end
    handle_output("") 
  end
  return
end
