
# Code common to all services

# Set up some global variables/defaults

def set_global_vars()
  $script_name              = "mode"
  $script                   = $0
  $script_file              = Pathname.new($script).realpath
  $script_dir               = File.dirname($script_file)
  $wiki_dir                 = $script_dir+"/"+File.basename($script,".rb")+".wiki"
  $wiki_url                 = "https://github.com/lateralblast/mode.wiki.git"
  $verbose_mode             = 0
  $test_mode                = 0
  $download_mode            = 1
  $iso_base_dir             = "/export/isos"
  $repo_base_dir            = "/export/repo"
  $image_base_dir           = "/export/images"
  $pkg_base_dir             = "/export/pkgs"
  $ldom_base_dir            = "/ldoms"
  $zone_base_dir            = "/zones"
  $iso_mount_dir            = "/cdrom"
  $ai_base_dir              = "/export/auto_install"
  $client_base_dir          = "/export/clients"
  $lxc_base_dir             = "/lxc"
  $lxc_image_dir            = "/export/images"
  $work_dir                 = ""
  $tmp_dir                  = ""
  $alt_repo_name            = "alt"
  $alt_prefix_name          = "solaris"
  $home_dir                 = ENV["HOME"]
  $dhcpd_file               = "/etc/inet/dhcpd4.conf"
  $fusion_dir               = ""
  $default_zpool            = "rpool"
  $default_ai_port          = "10081"
  $default_host             = ""
  $default_hostname         = %x["hostname"].chomp
  $default_nic              = ""
  $default_net              = "net0"
  $default_timezone         = "Australia/Victoria"
  $default_windows_timezone = "Eastern Standard Time"
  $default_terminal         = "sun"
  $default_country          = "AU"
  $local_opencsw_mirror     = "http://192.168.1.250/pub/Software/OpenCSW"
  $default_opencsw          = "testing"
  $default_ubuntu_mirror    = $default_country.downcase+".archive.ubuntu.com"
  $default_centos_mirror    = "mirror.centos.org"
  $default_sl_mirror        = "ftp.scientificlinux.org/linux"
  $default_epel_mirror      = "download.fedoraproject.org"
  $local_sl_mirror          = "mirror.aarnet.edu.au/pub"
  $local_ubuntu_mirror      = "mirror.aarnet.edu.au"
  $local_centos_mirror      = "mirror.aarnet.edu.au/pub"
  $local_epel_mirror        = "mirror.aarnet.edu.au"
  $default_timeserver       = "0."+$default_country.downcase+".pool.ntp.org"
  $default_keymap           = "US-English"
  $default_disable_autoconf = "true"
  $default_disable_dhcp     = "true"
  $default_environment      = "en_US.UTF-8"
  $default_keyboard         = "US"
  $default_language         = "en_US"
  $default_locale           = "en_US"
  $default_windows_locale   = "en_US"
  $default_windows_bootzise = "350"
  $default_debian_language  = "en"
  $default_ubuntu_software  = "OpenSSH server"
  $default_debian_interface = "eth0"
  $default_no_mirror        = "true"
  $default_use_mirror       = "false"
  $default_system_locale    = "C"
  $default_nameserver       = "8.8.8.8"
  $default_name_service     = "none"
  $default_security         = "none"
  $default_netmask          = "255.255.255.0"
  $default_cidr             = "24"
  $default_domainname       = "lab.net"
  $default_search           = "local"
  $default_files            = "files"
  $default_hosts            = "files dns"
  $default_root_password    = "P455w0rd"
  $default_admin_password   = "P455w0rd"
  $default_maas_admin       = "root"
  $default_maas_email       = $default_maas_admin+"@"+$default_host
  $default_mass_password    = $default_admin_password
  $default_server_admin     = "root"
  $default_server_password  = "P455w0rd"
  $default_vnc_password     = "P455w0rd"
  $use_alt_repo             = 0
  $destroy_fs               = "n"
  $use_defaults             = 0
  $default_apache_allow     = ""
  $default_admin_name       = "Sys Admin"
  $default_admin_user       = "sysadmin"
  $default_organisation     = "Multi OS Deployment Server"
  $default_server_admin     = "root"
  $default_admin_group      = "wheel"
  $default_admin_home       = "/home/"+$default_admin_user
  $default_admin_shell      = "/bin/bash"
  $default_admin_uid        = "200"
  $default_admin_gid        = "200"
  $preseed_admin_uid        = "1000"
  $preseed_admin_gid        = "1000"
  $tftp_dir                 = "/etc/netboot"
  $default_cluster          = "SUNWCprog"
  $default_install          = "initial_install"
  $default_nfs4_domain      = "dynamic"
  $default_auto_reg         = "disable"
  $q_struct                 = {}
  $q_order                  = []
  $text_mode                = 1
  $backup_dir               = ""
  $openssh_win_url          = "http://www.mls-software.com/files/setupssh-7.2p2-1-v1.exe"
  $ovftool_tar_url          = "https://github.com/richardatlateralblast/ottar/blob/master/vmware-ovftools.tar.gz?raw=true"
  $ovftool_dmg_url          = "https://github.com/richardatlateralblast/ottar/blob/master/VMware-ovftool-4.1.0-2459827-mac.x64.dmg?raw=true"
  $ovftool_bin              = "/Applications/VMware OVF Tool/ovftool"
  $rpm2cpio_url             = "http://svnweb.freebsd.org/ports/head/archivers/rpm2cpio/files/rpm2cpio?revision=259745&view=co"
  $rpm2cpio_bin             = ""
  $vbox_disk_type           = "sas"
  $default_vm_size          = "20G"
  $default_vm_mem           = "1024"
  $default_vm_vcpu          = "1"
  $serial_mode              = 0
  $os_name                  = ""
  $yes_to_all               = 0
  $default_cdom_mau         = "1"
  $default_gdom_mau         = "1"
  $default_cdom_vcpu        = "8"
  $default_gdom_mem         = "4G"
  $default_gdom_vcpu        = "8"
  $default_gdom_mem         = "4G"
  $default_gdom_size        = "10G"
  $default_cdom_name        = "initial"
  $default_dpool            = "dpool"
  $default_gdom_vnet        = "vnet0"
  $use_sudo                 = 1
  $do_ssh_keys              = 0
  $default_vm_network       = "hostonly"
  $default_vm_hw_version    = "8"
  $default_hostonly_ip      = "192.168.2.254"
  $default_fusion_ip        = "192.168.2.1"
  $default_vbox_ip          = "192.168.3.1"
  $default_server_size      = "small"
  $default_manifest_name    = "modest"
  $vbox_additions_iso       = "/Applications/VirtualBox.app//Contents/MacOS/VBoxGuestAdditions.iso"
  $openbsd_base_url         = "http://ftp.openbsd.org/pub/OpenBSD"
  $default_x86_virtual      = "VirtualBox"
  $default_x86_vm_net       = "enp0s3"
  $default_ext_network      = "192.168.1.0"
  $puppet_rpm_base_url      = "http://yum.puppetlabs.com"
  $centos_rpm_base_url      = "http://"+$local_centos_mirror+"/centos"
  $default_vm_utc           = "off"
  $valid_os_list            = [ 'Solaris', 'VMware-VMvisor', 'CentOS', 'OracleLinux', 'SLES', 'openSUSE',
                                'Ubuntu', 'Debian', 'Fedora', 'RHEL', 'SL', 'Purity', 'Windows', 'JeOS' ]
  $valid_linux_os_list      = [ 'CentOS', 'OracleLinux', 'SLES', 'openSUSE', 'Ubuntu', 'Debian', 'Fedora', 'RHEL', 'SL', 'Purity' ]
  $valid_arch_list          = [ 'x86_64', 'i386', 'sparc' ]
  $valid_console_list       = [ 'text', 'console', 'x11', 'headless' ]
  $valid_method_list        = [ 'ks', 'xb', 'vs', 'ai', 'js', 'ps', 'lxc', 'ay', 'image', 'ldom', 'cdom', 'gdom' ]
  $valid_type_list          = [ 'iso', 'flar', 'ova', 'snapshot', 'service', 'boot', 'cdrom', 'net', 'disk', 'client', 'dvd', 'server',
                                'vcsa', 'packer', 'docker', 'amazon-ebs', 'image', 'ami', 'instance', 'bucket', 'acl', 'snapshot', 'key',
                                'keypair', 'ssh', 'stack', 'object', 'cf', 'cloudformation', 'public', 'private' ]
  $valid_mode_list          = [ 'client', 'server', 'osx' ]
  $valid_vm_list            = [ 'vbox', 'fusion', 'zone', 'lxc', 'cdom', 'ldom', 'gdom', 'parallels' ]
  $valid_aws_format_list    = [ 'VMDK', 'RAW', 'VHD' ]
  $valid_aws_target_list    = [ 'citrix', 'vmware', 'windows' ]
  $valid_aws_acl_list       = [ 'private', 'public-read', 'public-read-write', 'authenticated-read' ]
  $execute_host             = "localhost"
  $default_options          = ""
  $do_checksums             = 0
  $default_ipfamily         = "ipv4"
  $default_datastore        = "datastore1"
  $default_server_network   = "vmnetwork1"
  $default_server_vlanid    = "0"
  $default_server_vswitch   = "vSwitch0"
  $default_diskmode         = "thin"
  $default_sitename         = $default_domainname.split(".")[0]
  $default_vcsa_size        = "tiny"
  $default_thindiskmode     = "true"
  $default_sshenable        = "true"
  $default_httpd_port       = "8888"
  $default_slice_size       = "8192"
  $default_boot_disk_size   = "350"
  $default_install_shell    = "ssh"
  $default_ssh_wait_timeout = "20m"
  $output_text              = []
  $default_output_format    = "text"
  $vbox_bin                 = "/usr/local/bin/VBoxManage"
  $enable_vnc               = 1
  $enable_strict            = 0
  $vnc_port                 = "5961"
  $novnc_dir                = $script_dir+"/noVNC"
  $novnc_url                = "git://github.com/kanaka/noVNC"
  $default_aws_type         = "amazon-ebs"
  $default_aws_size         = "t2.micro"
  $default_aws_region       = "ap-southeast-2"
  $default_aws_ami          = "ami-fedafc9d"
  $default_aws_creds        = $home_dir+"/.aws/credentials"
  $default_aws_suffix       = $script_name
  $default_aws_bucket       = $script_name+".bucket"
  $default_aws_instances    = "1,1"
  $default_aws_dryrun       = "false"
  $default_aws_format       = "VMDK"
  $default_aws_target       = "vmware"
  $default_aws_container    = "ova"
  $default_aws_acl          = "private"
  $default_aws_grant        = "CanonicalUser"
  $default_aws_import_id    = "c4d8eabf8db69dbe46bfe0e517100c554f01200b104d59cd408e777ba442a322"
  $default_aws_group        = "default"
  $default_user_ssh_config  = $home_dir+"/.ssh/config"
  $default_ssh_key_dir      = $home_dir+"/.ssh"
  $default_aws_ssh_key_dir  = $home_dir+"/.ssh/aws"
  $default_aws_base_object  = "uploads"
  $default_cf_ssh_location  = "0.0.0.0/0"
  $default_aws_user         = "ec2-user"

  # VMware Fusion Global variables
  
  $vmrun_bin = ""
  $vmapp_bin = ""

  # Declare some package versions

  $facter_version  = "1.7.4"
  $hiera_version   = "1.3.1"
  $puppet_version  = "3.4.2"
  $packer_version  = "0.12.0"
  $vagrant_version = "1.8.1"

  # Set some global OS types

  $os_name = %x[uname].chomp
  $os_arch = %x[uname -p].chomp
  $os_mach = %x[uname -m].chomp
  if $os_name.match(/SunOS|Darwin/)
    $os_info = %x[uname -a].chomp
    $os_rel  = %x[uname -r].chomp
    if $os_name.match(/SunOS/)
      $os_ver = $os_rel.split(/\./)[1]
      $os_rev = $os_rel.split(/\./)[1]
    else
      $os_ver = $os_rel.split(/\./)[0]
      if File.exist?("/et/release")
        $os_rev = %x[cat /etc/release |grep Solaris |head -1].chomp
        if $os_rev.match(/Oracle/)
          $os_ver = $os_rev.split(/\s+/)[3].split(/\./)[1]
        end
      end
    end
    if $os_rel.match(/5\.11/) and $os_name.match(/SunOS/)
      $os_update   = %x[uname -v].chomp
      $default_net = "net0"
    end
  end

  $id = %x[/usr/bin/id -u]
  $id = Integer($id)
  
  if $os_arch.match(/sparc/)
    if $os_test = %x[uname -r].split(/\./)[1].to_i > 9
      $valid_vm_list = [ 'zone', 'cdom', 'gdom' ]
    end
  else
    case $os_name
    when /SunOS/
      $valid_vm_list = [ 'vbox', 'zone' ]
      platform = %x[prtdiag |grep 'System Configuration'].chomp
    when /Linux/
      $valid_vm_list = [ 'vbox', 'lxc' ]
      if File.exist?("/sbin/dmidecode")
        dmidecode_bin = "/sbin/dmidecode"
      else
        dmidecode_bin = "/usr/sbin/dmidecode"
      end
      platform = %x[#{dmidecode_bin} |grep 'Product Name'].chomp
      if File.exist?("/bin/lsb_release")
        lsb_bin = "/bin/lsb_release"
      else
        lsb_bin = "/usr/bin/lsb_release"
      end
      $os_info = %x[#{lsb_bin} -i -s].chomp
      $os_rel  = %x[#{lsb_bin} -r -s].chomp
    when /Darwin/
      $valid_vm_list = [ 'vbox', 'fusion', 'parallels', 'aws' ]
    end
    case platform
    when /VMware/
      $default_gateway_ip  = "130.194.2.254"
      $default_hostonly_ip = "130.194.2.254"
      if $os_name.match(/Linux/)
        $default_net = "eth0"
      end
    when /VirtualBox/
      $default_gateway_ip  = "130.194.3.254"
      $default_hostonly_ip = "130.194.3.254"
      if $os_info.match(/RedHat|CentOS/) and $os_rel.match(/^7/)
        $default_net = "enp0s3"
      else
        $default_net = "eth0"
      end
    else
      $default_gateway_ip  = "130.194.3.254"
      $default_hostonly_ip = "130.194.3.254"
      if $os_name.match(/Linux/)
        $default_net = "eth0"
        network_test = %x[ifconfig -a |grep eth0].chomp
        if !network_test.match(/eth0/)
          $default_net = %x[sudo sh -c 'route |grep default'].split(/\s+/)[-1].chomp
        end
      end
    end
  end
  return
end

set_global_vars()

# Calculate CIDR

def netmask_to_cidr(netmask)
  require 'netaddr'
  cidr = NetAddr::CIDR.create('0.0.0.0/'+netmask).netmask
  return cidr
end

$default_cidr = netmask_to_cidr($default_netmask)

# Code to run on quiting

def quit()
  if $output_format.match(/html/)
    $output_text.push("</body>")
    $output_text.push("</html>")
    puts $output_text.join("\n")
  end
  exit
end

# Print script usage information

def print_usage()
  switches     = []
  long_switch  = ""
  short_switch = ""
  help_info    = ""
  handle_output("")
  handle_output("Usage: #{$script}")
  handle_output("")
  file_array  = IO.readlines $0
  option_list = file_array.grep(/\[ "--/)
  option_list.each do |line|
    if !line.match(/file_array/)
      help_info    = line.split(/# /)[1]
      switches     = line.split(/,/)
      long_switch  = switches[0].gsub(/\[/,"").gsub(/\s+/,"")
      short_switch = switches[1].gsub(/\s+/,"")
      if short_switch.match(/REQ|BOOL/)
        short_switch = ""
      end
      if long_switch.gsub(/\s+/,"").length < 7
        handle_output("#{long_switch},\t\t\t#{short_switch}\t#{help_info}")
      else
        if long_switch.gsub(/\s+/,"").length < 15
          handle_output("#{long_switch},\t\t#{short_switch}\t#{help_info}")
        else
          handle_output("#{long_switch},\t#{short_switch}\t#{help_info}")
        end
      end
    end
  end
  handle_output("")
  return
end

# Handle output

def handle_output(text)
  if $output_format.match(/html/)
    if text == ""
      text = "<br>"
    end
  end
  if $output_format.match(/text/)
    puts text 
  end
  $output_text.push(text)
  return
end

# HTML header

def html_header(pipe,title)
  pipe.push("<html>")
  pipe.push("<header>")
  pipe.push("<title>")
  pipe.push(title)
  pipe.push("</title>")
  pipe.push("</header>")
  pipe.push("<body>")
  return pipe
end

# HTML footer

def html_footer(pipe)
  pipe.push("</body>")
  pipe.push("</html>")
  return pipe
end

# Get version

def get_version()
  file_array = IO.readlines $0
  version    = file_array.grep(/^# Version/)[0].split(":")[1].gsub(/^\s+/,'').chomp
  packager   = file_array.grep(/^# Packager/)[0].split(":")[1].gsub(/^\s+/,'').chomp
  name       = file_array.grep(/^# Name/)[0].split(":")[1].gsub(/^\s+/,'').chomp
  return version,packager,name
end

# Print script version information

def print_version()
  (version,packager,name) = get_version()
  handle_output("#{name} v. #{version} #{packager}")
  return
end

# Write array to file

def write_array_to_file(file_array,file_name,file_mode)
  dir_name = Pathname.new(file_name).dirname
  FileUtils.mkpath(dir_name)
  if file_mode.match(/a/)
    file_mode = "a"
  else
    file_mode = "w"
  end
  file = File.open(file_name,file_mode)
  file_array.each do |line|
    if !line.match(/\n/)
      line = line+"\m"
    end
    file.write(line)
  end
  file.close
  print_contents_of_file("",file_name)
  return
end

# Get SSH config

def get_user_ssh_config(install_ip,install_id,install_client)
  user_ssh_config = ConfigFile.new
  if install_ip.match(/[0-9]/)
    host_list = user_ssh_config.search(/#{install_id}/)
  end
  if install_id.match(/[0-9]/)
    host_list = user_ssh_config.search(/#{install_ip}/)
  end
  if install_client.match(/[0-9]|[a-z]/)
    host_list = user_ssh_config.search(/#{install_client}/)
  end
  if !host_list
    host_list = "none"
  else
    if !host_list.match(/[A-Z]|[a-z]|[0-9]/)
      host_list = "none"
    end
  end
  return host_list
end


# List hosts in SSH config

def list_user_ssh_config(install_ip,install_id,install_client)
  host_list = get_user_ssh_config(install_ip,install_id,install_client)
  if !host_list.match(/none/)
    handle_output(host_list)
  end
  return
end

# Update SSH config

def update_user_ssh_config(install_ip,install_id,install_client,install_keyfile,install_admin)
  host_list   = get_user_ssh_config(install_ip,install_id,install_client)
  if host_list.match(/none/)
    host_string = "Host "
    ssh_config  = $default_user_ssh_config
    if install_client.match(/[A-Z]|[a-z]|[0-9]/)
      host_string = host_string+" "+install_client
    end
    if install_id.match(/[A-Z]|[a-z]|[0-9]/)
      host_string = host_string+" "+install_id
    end
    if !File.exist?(ssh_config)
      file = File.open(ssh_config,"w")
    else
      file = File.open(ssh_config,"a")
    end
    file.write(host_string+"\n")
    if install_keyfile.match(/[A-Z]|[a-z]|[0-9]/)
      file.write("    IdentityFile "+install_keyfile+"\n")
    end
    if install_admin.match(/[A-Z]|[a-z]|[0-9]/)
      file.write("    User "+install_admin+"\n")
    end
    if install_ip.match(/[A-Z]|[a-z]|[0-9]/)
      file.write("    HostName "+install_ip+"\n")
    end
    file.close
  end
  return
end

# Remove SSH config

def delete_user_ssh_config(install_ip,install_id,install_client)
  host_list   = get_user_ssh_config(install_ip,install_id,install_client)
  if !host_list.match(/none/)
    host_info  = host_list.split(/\n/)[0].chomp
    handle_output("Warning:\tRemoving entries for '#{host_info}'")
    ssh_config = $default_user_ssh_config
    ssh_data   = File.readlines(ssh_config)
    new_data   = []
    found_host = 0
    ssh_data.each do |line|
      if line.match(/^Host/)
        if line.match(/#{install_client}|#{install_id}|#{install_ip}/) 
          found_host = 1
        else
          found_host = 0
        end
      end
      if found_host == 0
        new_data.push(line)
      end
    end
    file = File.open(ssh_config,"w")
    new_data.each do |line|
      file.write(line)
    end
    file.close
  end
  return
end

# Generate a client MAC address if not given one

def create_install_mac(install_mac)
  if !install_mac.match(/[0-9]/)
    install_mac = (1..6).map{"%0.2X"%rand(256)}.join(":")
    if $verbose_mode == 1
      handle_output("Information:\tGenerated MAC address #{install_mac}")
    end
  end
  return install_mac
end

# Check VNC is installed

def check_vnc_install()
  if !File.directory?($novnc_dir)
    message = "Information:\tCloning noVNC from "+$novnc_url
    command = "git clone #{$novnc_url}"
    execute_command(message,command)
  end
end

# Get default host

def get_default_host()
  if !$default_host.match(/[0-9]/)
    message = "Determining:\tDefault host IP"
    if $os_name.match(/SunOS/)
      command = "ipadm show-addr #{$default_net} |grep net |head -1 |awk '{print $4}' |cut -f1 -d'/'"
    end
    if $os_name.match(/Darwin/)
      $default_net = "en0"
      command      = "ifconfig #{$default_net} |grep inet |grep -v inet6"
    end
    if $os_name.match(/Linux/)
      command = "ifconfig #{$default_net} |grep inet |grep -v inet6"
    end
    $default_host = execute_command(message,command)
    $default_host = $default_host.chomp
    if $default_host.match(/inet/)
      $default_host = $default_host.gsub(/^\s+/,"").split(/\s+/)[1]
    end
    if $default_host.match(/addr:/)
      $default_host = $default_host.split(/:/)[1].split(/ /)[0]
    end
  end
end

# Set config file locations

def set_local_config()
  if $os_name.match(/Linux/)
    if $os_info.match(/RedHat|CentOS/)
      $tftp_dir   = "/var/lib/tftpboot"
      $dhcpd_file = "/etc/dhcp/dhcpd.conf"
    else
      $tftp_dir   = "/tftpboot"
      $dhcpd_file = "/etc/dhcp/dhcpd.conf"
    end
  end
  if $os_name.match(/Darwin/)
    $tftp_dir   = "/private/tftpboot"
    $dhcpd_file = "/usr/local/etc/dhcpd.conf"
  end
end

# Check local configuration
# Create work directory if it doesn't exist
# If not running on Solaris, run in test mode
# Useful for generating client config files

def check_local_config(install_mode)
  set_vmrun_bin()
  set_vboxmanage_bin()
  if $do_ssh_keys == 1
    check_ssh_keys()
  end
  if $verbose_mode == 1
    handle_output("Information:\tHome directory #{$home_dir}")
  end
  if !$work_dir.match(/[a-z,A-Z,0-9]/)
    dir_name = File.basename($script,".*")
    if $id == 0
      $work_dir = "/opt/"+dir_name
    else
      $work_dir = $home_dir+"/."+dir_name
    end
  end
  if $verbose_mode == 1
    handle_output("Information:\tSetting work directory to #{$work_dir}")
  end
  if !$tmp_dir.match(/[a-z,A-Z,0-9]/)
    $tmp_dir = $work_dir+"/tmp"
  end
  if $verbose_mode == 1
    handle_output("Information:\tSetting temporary directory to #{$work_dir}")
  end
  # Get OS name and set system settings appropriately
  check_dir_exists($work_dir)
  check_dir_owner($work_dir,$id)
  check_dir_exists($tmp_dir)
  if $os_name.match(/Linux/)
    $os_rel = %x[lsb_release -r |awk '{print $2}'].chomp
  end
  if $os_info.match(/Ubuntu/)
    $lxc_base_dir = "/var/lib/lxc"
  end
  get_default_host()
  if !$default_apache_allow.match(/[0-9]/)
    if $default_ext_network.match(/[0-9]/)
      $default_apache_allow = $default_host.split(/\./)[0..2].join(".")+" "+$default_ext_network
    else
      $default_apache_allow = $default_host.split(/\./)[0..2].join(".")
    end
  end
  if install_mode.match(/server/)
    if $os_name.match(/Darwin/)
      $tftp_dir   = "/private/tftpboot"
      $dhcpd_file = "/usr/local/etc/dhcpd.conf"
    end
    if $os_name.match(/SunOS/) and $os_rel.match(/11/)
      check_dpool()
      check_tftpd()
      check_local_publisher()
      install_sol11_pkg("pkg:/system/boot/network")
      install_sol11_pkg("installadm")
      install_sol11_pkg("lftp")
      check_dir_exists("/etc/netboot")
    end
    if $os_name.match(/SunOS/) and !$os_rel.match(/11/)
      check_dir_exists("/tftpboot")
    end
    if $verbose_mode == 1
      handle_output("Information:\tSetting apache allow range to #{$default_apache_allow}")
    end
    if $os_name.match(/SunOS/)
      if $os_name.match(/SunOS/) and $os_rel.match(/11/)
        check_dpool()
      end
      if $default_options.match(/puppet/)
        check_sol_puppet()
      end
      check_sol_bind()
    end
    if $os_name.match(/Linux/)
      if $os_info.match(/RedHat|CentOS/)
        check_yum_xinetd()
        check_yum_tftpd()
        check_yum_dhcpd()
        check_yum_httpd()
        $tftp_dir   = "/var/lib/tftpboot"
        $dhcpd_file = "/etc/dhcp/dhcpd.conf"
        check_dhcpd_config("")
        check_tftpd_config()
      else
        check_apt_tftpd()
        check_apt_dhcpd()
        $tftp_dir   = "/tftpboot"
        $dhcpd_file = "/etc/dhcp/dhcpd.conf"
      end
    end
  else
    if $os_name.match(/Linux/)
      if $os_info.match(/RedHat|CentOS/)
        $tftp_dir   = "/var/lib/tftpboot"
        $dhcpd_file = "/etc/dhcp/dhcpd.conf"
      else
        $tftp_dir   = "/tftpboot"
        $dhcpd_file = "/etc/dhcp/dhcpd.conf"
      end
    end
    if $os_name.match(/Darwin/)
      $tftp_dir   = "/private/tftpboot"
      $dhcpd_file = "/usr/local/etc/dhcpd.conf"
    end
  end
  # If runnning on OS X check we have brew installed
  if $os_name.match(/Darwin/)
    if !File.exists?("/usr/local/bin/brew")
      message = "Installing:\tBrew for OS X"
      command = "ruby -e \"$(curl -fsSL https://raw.github.com/Homebrew/homebrew/go/install)\""
      execute_command(message,command)
    end
  end
  # Set location of VMware Fusion
  if $os_name.match(/Darwin/)
    set_fusion_dir()
  end
  $backup_dir = $work_dir+"/backup"
  check_dir_exists($backup_dir)
  bin_dir     = $work_dir+"/bin"
  check_dir_exists(bin_dir)
  $rpm2cpio_bin=bin_dir+"/rpm2cpio"
  if !File.exist?($rpm2cpio_bin)
    if $download_mode == 1
      wget_file($rpm2cpio_url,$rpm2cpio_bin)
      if File.exist?($rpm2cpio_bin)
        system("chmod +x #{$rpm2cpio_bin}")
      end
    end
  end
  return
end

# Print valid list

def print_valid_list(message,valid_list)
  handle_output("")
  handle_output(message)
  handle_output("")
  handle_output("Available options:")
  handle_output("")
  valid_list.each do |item|
    handle_output(item)
  end
  handle_output("")
  return
end

# Print change log

def print_changelog()
  if File.exist?("changelog")
    changelog = File.readlines("changelog")
    changelog = changelog.reverse
    changelog.each_with_index do |line, index|
      line = line.gsub(/^# /,"")
      if line.match(/^[0-9]/)
        handle_output(line)
        text = changelog[index-1].gsub(/^# /,"")
        handle_output(text)
        handle_output("")
      end
    end
  end
  return
end

# Check default dpool

def check_dpool()
  message = "Information:\tChecking for alternate pool for LDoms"
  command = "zfs list |grep '^dpool'"
  output  = execute_command(message,command)
  if !output.match(/dpool/)
    $default_dpool = "rpool"
  end
  return
end

# Copy packages to local packages directory

def download_pkg(remote_file)
  local_file = File.basename(remote_file)
  if !File.exist?(local_file)
    message = "Information:\tFetching "+remote_file+" to "+local_file
    command = "wget #{remote_file} -O #{local_file}"
    execute_command(message,command)
  end
  return
end

# Get install type from file

def get_install_type_from_file(install_file)
  case install_file.downcase
  when /vcsa/
    install_type = "vcsa"
  else
    install_type = File.extname(install_file).downcase.split(/\./)[1]
  end
  return install_type
end

# Check password

def check_password(install_password)
  if !install_password.match(/[A-Z]/)
    handle_output("Warning:\tPassword does not contain and upper case character")
    exit
  end
  if !install_password.match(/[0-9]/)
    handle_output("Warning:\tPassword does not contain a number")
    exit
  end
  return
end

# Check ovftool is installed

def check_ovftool_exists()
  if $os_name.match(/Darwin/)
    check_osx_ovftool()
  end
  return
end

# Detach DMG

def detach_dmg(tmp_dir)
  %x[sudo hdiutil detach "#{tmp_dir}"]
  return
end

# Attach DMG

def attach_dmg(ovftool_dmg)
  tmp_dir = %x[sudo sh -c 'echo Y | hdiutil attach "#{pkg_file}" |tail -1 |cut -f3-'].chomp
  if !tmp_dir.match(/[a-z,A-Z]/)
    tmp_dir = %x[ls -rt /Volumes |grep "#{app_name}" |tail -1].chomp
    tmp_dir = "/Volumes/"+tmp_dir
  end
  if $werbose_mode == 1
    handle_output("Information:\tDMG mounted on #{tmp_dir}")
  end
  return tmp_dir
end

# Check OSX ovftool

def check_osx_ovftool()
  ovftool_bin = "/Applications/VMware OVF Tool/ovftool"
  if !File.exist?(ovftool_bin)
    handle_output("Warning:\tOVF Tool not installed")
    wget_file($ovftool_dmg_url,ovftool_dmg)
    handle_output("Information:\tInstalling OVF Tool")
    ovftool_dmg = $ovftool_dmg_url.split(/\?/)[0]
    ovftool_dmg = File.basename(ovftool_dmg)
    tmp_dir  = attach_dmg(ovftool_dmg)
    pkg_file = tmp_dir+"/VMware OVF Tool.pkg"
    message = "Information:\tInstalling package "+pkg_file
    command = "/usr/sbin/installer -pkg #{pkg_bin} -target /"
    execute_command(message,command)
    detach_dmg(tmp_dir)
  end
  return
end

# SCP file to remote host

def scp_file(install_server,install_serveradmin,install_serverpassword,local_file,remote_file)
  if $verbose_mode == 1
    handle_output("Information:\tCopying file \""+local_file+"\" to \""+install_server+":"+remote_file+"\"")
  end
  Net::SCP.start(install_server,install_serveradmin,:password => install_serverpassword, :paranoid => false) do |scp|
    scp.upload! local_file, remote_file
  end
  return
end

# Execute SSH command

def execute_ssh_command(install_server,install_serveradmin,install_serverpassword,command)
  if $verbose_mode == 1
    handle_output("Information:\tExecuting command \""+command+"\" on server "+install_server)
  end
  Net::SSH.start(install_server,install_serveradmin,:password => install_serverpassword, :paranoid => false) do |ssh|
    ssh.exec!(command)
  end
  return
end

# Get client config

def get_client_config(install_client,install_service,install_method,install_type,install_vm)
  config_files  = []
  client_dir    = ""
  config_prefix = ""
  if install_vm.match(/[a-z]/)
    eval"[show_#{install_vm}_vm_config(install_client)]"
  else
    client_dir = get_client_dir(install_client)
    if install_type.match(/packer/) or client_dir.match(/packer/)
      install_method = "packer"
      client_dir     = get_packer_client_dir(install_client,install_vm)
    else
      if !install_service.match(/[a-z]/)
        install_service = get_install_service_from_client_name(install_client)
      end
      if !install_method.match(/[a-z]/)
        install_method  = get_install_method(install_client,install_service)
      end
    end
    config_prefix = client_dir+"/"+install_client
    case install_method
    when /packer/
      config_files[0] = config_prefix+".json"
      config_files[1] = config_prefix+".cfg"
      config_files[2] = config_prefix+"_first_boot.sh"
      config_files[3] = config_prefix+"_post.sh"
      config_files[4] = client_dir+"/Autounattend.xml"
      config_files[5] = client_dir+"/post_install.ps1"
    when /config|cfg|ks|Kickstart/
      config_files[0] = config_prefix+".cfg"
    when /post/
      case method
      when /ps/
        config_files[0] = config_prefix+"_post.sh"
      end
    when /first/
      case method
      when /ps/
        config_files[0] = config_prefix+"_first_boot.sh"
      end
    end
    config_files.each do |config_file|
      if File.exist?(config_file)
        print_contents_of_file("",config_file)
      end
    end
  end
  return
end

# Get client install service for a client

def get_install_service(install_client)
  client_dir      = get_client_dir(install_client)
  install_service = client_dir.split(/\//)[-2]
  return install_service
end

# Get install method from service

def get_install_method(install_client,install_service)
  if !install_service.match(/[a-z]/)
    install_service = get_install_service(install_client)
  end
  service_dir = $repo_base_dir+"/"+install_service
  if File.directory?(service_dir) or File.symlink?(service_dir)
    if $verbose_mode == 1
      handle_output("Information:\tFound directory #{service_dir}")
      handle_output("Information:\tDetermining service type")
    end
  else
    handle_output("Warning:\tService #{install_service} does not exist")
  end
  install_method = ""
  test_file = service_dir+"/vmware-esx-base-osl.txt"
  if File.exist?(test_file)
    install_method = "vs"
  else
    test_file = service_dir+"/repodata"
    if File.exist?(test_file)
      install_method = "ks"
    else
      test_dir = service_dir+"/preseed"
      if File.directory?(test_dir)
        install_method = "ps"
      end
    end
  end
  return install_method
end

# Unconfigure a server

def unconfigure_server(install_service)
  install_method = get_install_method(install_service)
  if install_method.match(/[a-z]/)
    eval"[unconfigure_#{install_method}_server(install_service)]"
  else
    handle_output("Warning:\tCould not determine service type for #{install_service}")
  end
  return
end

# list OS install ISOs

def list_os_isos(install_os)
  case install_os
  when /linux/
    search_string = "CentOS|OracleLinux|SUSE|SLES|SL|Fedora|ubuntu|debian|purity"
  when /sol/
    search_string = "sol"
  when /esx|vmware|vsphere/
    search_string = "VMvisor"
  else
    list_all_isos()
    return
  end
  eval"[list_#{install_os}_isos(search_string)]"
  return
end

# List all isos

def list_all_isos()
  $valid_method_list.each do |install_method|
    eval"[list_#{install_method}_isos()]"
  end
  return
end

# Get install method from service name

def get_install_method_from_service(install_service)
  case install_service
  when /vmware/
    install_method = "vs"
  when /centos|oel|rhel|fedora|sl/
    install_method = "ks"
  when /ubuntu|debian/
    install_method = "ps"
  when /suse|sles/
    install_method = "ay"
  when /sol_6|sol_7|sol_8|sol_9|sol_10/
    install_method = "js"
  when /sol_11/
    install_method = "ai"
  end
  return install_method
end

# Get install service from ISO file name

def get_install_service_from_file(install_file)
  install_service = ""
  install_service    = ""
  service_version = ""
  install_arch    = ""
  install_release = ""
  install_method  = ""
  install_label   = ""
  if install_file.match(/amd64|x86_64/)
    install_arch = "x86_64"
  else
    install_arch = "i386"
  end
  case install_file
  when /ubuntu/
    install_service = "ubuntu"
    service_version = install_file.split(/-/)[1].gsub(/\./,"_").gsub(/_iso/,"")
    service_version = service_version+"_"+install_arch
    install_method  = "ps"
    install_release = install_file.split(/-/)[1]
  when /purity/
    install_service    = "purity"
    service_version = install_file.split(/_/)[1]
    install_method  = "ps"
    install_arch    = "x86_64"
  when /vCenter-Server-Appliance|VCSA/
    install_service    = "vcsa"
    service_version = install_file.split(/-/)[3..4].join(".").gsub(/\./,"_").gsub(/_iso/,"")
    install_method  = "image"
    install_release = install_file.split(/-/)[3..4].join(".").gsub(/\.iso/,"")
    install_arch    = "x86_64"
  when /VMvisor-Installer/
    install_service    = "vsphere"
    install_arch    = "x86_64"
    service_version = install_file.split(/-/)[3].gsub(/\./,"_")+"_"+install_arch
    install_method  = "vs"
    install_release = install_file.split(/-/)[3].gsub(/update/,"")
  when /CentOS/
    install_service    = "centos"
    service_version = install_file.split(/-/)[1..2].join(".").gsub(/\./,"_").gsub(/_iso/,"")
    install_os      = install_service
    install_method  = "ks"
    install_release = install_file.split(/-/)[1]
  when /Fedora-Server/
    install_service    = "fedora"
    if install_file.match(/DVD/)
      service_version = install_file.split(/-/)[-1].gsub(/\./,"_").gsub(/_iso/,"_")
      service_arch    = install_file.split(/-/)[-2].gsub(/\./,"_").gsub(/_iso/,"_")
      install_release = install_file.split(/-/)[-1].gsub(/\.iso/,"")
    else
      service_version = install_file.split(/-/)[-2].gsub(/\./,"_").gsub(/_iso/,"_")
      service_arch    = install_file.split(/-/)[-3].gsub(/\./,"_").gsub(/_iso/,"_")
      install_release = install_file.split(/-/)[-2].gsub(/\.iso/,"")
    end
    service_version = service_version+"_"+service_arch
    install_method  = "ks"
  when /OracleLinux/
    install_service    = "oel"
    service_version = install_file.split(/-/)[1..2].join(".").gsub(/\./,"_").gsub(/R|U/,"")
    service_arch    = install_file.split(/-/)[-2]
    service_version = service_version+"_"+service_arch
    install_release = install_file.split(/-/)[1..2].join(".").gsub(/[a-z,A-Z]/,"")
    install_method  = "ks"
  when /openSUSE/
    install_service    = "opensuse"
    service_version = install_file.split(/-/)[1].gsub(/\./,"_").gsub(/_iso/,"")
    service_arch    = install_file.split(/-/)[-1].gsub(/\./,"_").gsub(/_iso/,"")
    service_version = service_version+"_"+service_arch
    install_method  = "ay"
    install_release = install_file.split(/-/)[1]
  when /rhel/
    install_service    = "rhel"
    service_version = install_file.split(/-/)[2..3].join(".").gsub(/\./,"_").gsub(/_iso/,"")
    install_method  = "ks"
    install_release = install_file.split(/-/)[2]
  when /SLE/
    install_service    = "sles"
    service_version = install_file.split(/-/)[1]
    service_arch    = install_file.split(/-/)[4]
    service_version = service_version+"_"+service_arch
    install_method  = "ay"
    install_release = install_file.split(/-/)[1]
  when /sol/
    install_service    = "sol"
    install_release = install_file.split(/-/)[1].gsub(/_/,".")
    if install_release.to_i > 10
      if install_file.match(/1111/)
        install_release = "11.0"
      end
      install_method  = "ai"
      install_arch    = "x86_64"
    else
      install_release = install_file.split(/-/)[1..2].join(".").gsub(/u/,"")
      install_method  = "js"
      install_arch    = "i386"
    end
    service_version = install_release+"_"+install_arch
    service_version = service_version.gsub(/\./,"_")
  when /[0-9][0-9][0-9][0-9]|Win|Srv/
    install_service = "windows"
    mount_iso(install_file)
    wim_file = $iso_mount_dir+"/sources/install.wim"
    if File.exist?(wim_file)
      wiminfo_bin = %x[which wiminfo]
      if !wiminfo_bin.match(/wiminfo/)
        message = "Information:\tInstall wiminfo (wimlib)"
        command = "brew install wimlib"
        execute_command(message,command)
        wiminfo_bin = %x[which wiminfo]
        if !wiminfo_bin.match(/wiminfo/)
          handle_output("Warning:\tCannnot find wiminfo (required to determine version of windows from ISO)")
          exit
        end
      end
      message = "Information:\tDeterming version of Windows from: "+wim_file
      command = "wiminfo \"#{wim_file}\" 1| grep ^Description"
      output  = execute_command(message,command)
      install_label   = output.chomp.split(/\:/)[1].gsub(/^\s+/,"").gsub(/CORE/,"")
      service_version = output.split(/Description:/)[1].gsub(/^\s+|SERVER|Server/,"").downcase.gsub(/\s+/,"_").split(/_/)[1..-1].join("_")
      message = "Information:\tDeterming architecture of Windows from: "+wim_file
      command = "wiminfo \"#{wim_file}\" 1| grep ^Architecture"
      output  = execute_command(message,command)
      install_arch = output.chomp.split(/\:/)[1].gsub(/^\s+/,"")
      umount_iso()
    end
    service_version = service_version+"_"+install_release+"_"+install_arch
    service_version = service_version.gsub(/__/,"_")
    install_method  = "pe"
  end
  install_os      = install_service
  install_service = install_os+"_"+service_version.gsub(/__/,"_")
  if $verbose_mode == 1
    handle_output("Information:\tSetting service name to #{install_service}")
    handle_output("Information:\tSetting OS name to #{install_os}")
  end
  return install_service,install_os,install_method,install_release,install_arch,install_label
end

# Get Install method from ISO file name

def get_install_method_from_iso(install_file)
  if install_file.match(/\//)
    install_file = File.basename(install_file)
  end
  case install_file
  when /VMware-VMvisor/
    install_method = "vs"
  when /CentOS|OracleLinux|^SL|Fedora|rhel/
    install_method = "ks"
  when /ubuntu|debian|purity/
    install_method = "ps"
  when /SUSE|SLE/
    install_method = "ay"
  when /sol-6|sol-7|sol-8|sol-9|sol-10/
    install_method = "js"
  when /sol-11/
    install_method = "ai"
  when /Win|WIN|srv/
    install_method = "pe"
  end
  return install_method
end

# Configure a service

def configure_server(install_method,install_arch,publisher_host,publisher_port,install_service,install_file)
  if !install_method.match(/[a-z,A-Z]/)
    if !install_file.match(/[a-z,A-Z]/)
      handle_output("Warning:\tCould not determine service name")
      exit
    else
      install_method = get_install_method_from_iso(install_file)
    end
  end
  eval"[configure_#{install_method}_server(install_arch,publisher_host,publisher_port,install_service,install_file)]"
  return
end

# Generate MAC address

def generate_mac_address(install_vm)
  if install_vm.match(/fusion|vm|vbox/)
    install_mac = "00:05:"+(1..4).map{"%0.2X"%rand(256)}.join(":")
  else
    install_mac = (1..6).map{"%0.2X"%rand(256)}.join(":")
  end
  return install_mac
end

# List all image services - needs code

def list_image_services()
  return
end

# List all image ISOs - needs code

def list_image_isos()
  return
end

# List all services

def list_all_services()
  $valid_method_list.each do |install_method|
    eval"[list_#{install_method}_services()]"
  end
  handle_output("") 
  return
end

# Check IP validity

def check_ip(install_ip)
  invalid_ip = 0
  ip_fields  = install_ip.split(/\./)
  if !ip_fields.length == 4
    invalid_ip = 1
  end
  ip_fields.each do |ip_field|
    if ip_field.match(/[a-z,A-Z]/) or ip_field.to_i > 255
      invalid_ip = 1
    end
  end
  if invalid_ip == 1
    handle_output("Warning:\tInvalid IP Address")
    exit
  end
  return
end

# Check hostname validity

def check_hostname(install_client)
  install_client = install_client.split()
  install_client.each do |char|
    if !char.match(/[a-z,A-Z,0-9]|-/)
      handle_output("Invalid hostname: #{install_client.join()}")
      exit
    end
  end
end

# Get ISO list

def get_iso_list(install_os,install_method,install_release,install_arch)
  search_string = ""
  full_list = check_iso_base_dir(search_string)
  if !install_os.match(/[a-z]/) and !install_method.match(/[a-z]/) and !install_release.match(/[a-z]/) and ! install_arch.match(/[a-z]/)
    return full_list
  end
  temp_list = []
  iso_list  = []
  case install_os.downcase
  when /pe|win/
    install_os = "OEM|win|Win|EVAL|eval"
  when /oel|oraclelinux/
    install_os = "OracleLinux"
  when /sles/
    install_os = "SLES"
  when /centos/
    install_os = "CentOS"
  when /suse/
    install_os = "openSUSE"
  when /ubuntu/
    install_os = "ubuntu"
  when /debian/
    install_os = "debian"
  when /purity/
    install_os = "purity"
  when /fedora/
    install_os = "Fedora"
  when /scientific|sl/
    install_os = "SL"
  when /redhat|rhel/
    install_os = "rhel"
  when /sol/
    install_os = "sol"
  when /^linux/
    install_os = "CentOS|OracleLinux|SLES|openSUSE|ubuntu|debian|Fedora|rhel|SL"
  when /vmware|vsphere|esx/
    install_os = "VMware-VMvisor"
  end
  case install_method
  when /kick|ks/
    install_method = "CentOS|OracleLinux|Fedora|rhel|SL|VMware"
  when /jump|js/
    install_method = "sol-10"
  when /ai/
    install_method = "sol-11"
  when /yast|ay/
    install_method = "SLES|openSUSE"
  when /preseed|ps/
    install_method = "debian|ubuntu|purity"
  end
  if install_release.match(/[0-9]/)
    case install_os
    when "OracleLinux"
      if install_release.match(/\./)
        (major,minor)   = install_release.split(/\./)
        install_release = "-R"+major+"-U"+minor
      else
        install_release = "-R"+install_release
      end
    when /sol/
      if install_release.match(/\./)
        (major,minor)   = install_release.split(/\./)
        if install_release.match(/^10/)
          install_release = major+"-u"+minor
        else
          install_release = major+"_"+minor
        end
      end
      install_release = "-"+install_release
    else
      install_release = "-"+install_release
    end
  end
  if install_arch.match(/[a-z,A-Z]/)
    if install_os.match(/sol/)
      install_arch = install_arch.gsub(/i386|x86_64/,"x86")
    end
    if install_os.match(/ubuntu/)
      install_arch = install_arch.gsub(/x86_64/,"amd64")
    else
      install_arch = install_arch.gsub(/amd64/,"x86_64")
    end
  end
  search_strings = []
  [ install_os, install_method, install_release, install_arch ].each do |search_string|
    if search_string.match(/[a-z,A-Z,0-9]/)
      search_strings.push(search_string)
    end
  end
  temp_list = full_list
  search_strings.each do |search_string|
    temp_list = temp_list.grep(/#{search_string}/) 
  end
  if temp_list.length > 0
    iso_list = temp_list
  end
  return iso_list
end

# List ISOs

def list_isos(install_os,install_method,install_release,install_arch)
  if !$output_format.match(/html/)
    handle_output("") 
  end
  iso_list = get_iso_list(install_os,install_method,install_release,install_arch)
  iso_list.each do |iso_file|
    if $output_format.match(/html/)
      handle_output("<tr>#{iso_file}</tr>")
    else
      handle_output(iso_file)
      handle_output("")
    end
  end
  return
end

# Connect to virtual serial port

def connect_to_virtual_serial(install_client,install_vm)
  if install_vm.match(/ldom|gdom/)
    connect_to_gdom_console(install_client)
  else
    handle_output("")
    handle_output("Connecting to serial port of #{install_client}")
    handle_output("")
    handle_output("To disconnect from this session use CTRL-Q")
    handle_output("")
    handle_output("If you wish to re-connect to the serial console of this machine,")
    handle_output("run the following command:")
    handle_output("")
    handle_output("#{$script} --action=console --vm=#{install_vm} --client=#{install_client}")
    handle_output("")
    handle_output("or:")
    handle_output("")
    handle_output("socat UNIX-CONNECT:/tmp/#{install_client} STDIO,raw,echo=0,escape=0x11,icanon=0")
    handle_output("")
    handle_output("")
    system("socat UNIX-CONNECT:/tmp/#{install_client} STDIO,raw,echo=0,escape=0x11,icanon=0")
  end
  return
end

# Set some VMware ESXi VM defaults

def configure_vmware_esxi_defaults()
  $default_vm_mem      = "4096"
  $default_vm_vcpu     = "2"
  $client_os           = "ESXi"
  $vbox_disk_type      = "ide"
  return
end

# Set some VMware vCenter defaults

def configure_vmware_vcenter_defaults()
  $default_vm_mem      = "4096"
  $default_vm_vcpu     = "2"
  $client_os           = "ESXi"
  $vbox_disk_type      = "ide"
  return
end

# Get Install Service from client name

def get_install_service_from_client_name(install_client)
  install_service = ""
  message    = "Information:\tFinding client configuration directory for #{install_client}"
  command    = "find #{$client_base_dir} -name #{install_client} |grep '#{install_client}$'"
  client_dir = execute_command(message,command).chomp
  if $verbose_mode == 1
    if File.directory?(client_dir)
      handle_output("Information:\tNo client directory found for #{install_client}")
    else
      handle_output("Information:\tClient directory found #{client_dir}")
      if client_dir.match(/packer/)
        handle_output = "Information:\tInstall method is Packer"
      end
    end
  end
  return install_service
end


# Get client directory

def get_client_dir(install_client)
  message    = "Information:\tFinding client configuration directory for #{install_client}"
  command    = "find #{$client_base_dir} -name #{install_client} |grep '#{install_client}$'"
  client_dir = execute_command(message,command).chomp
  if $verbose_mode == 1
    if File.directory?(client_dir)
      handle_output("Information:\tNo client directory found for #{install_client}")
    else
      handle_output("Information:\tClient directory found #{client_dir}")
    end
  end
  return client_dir
end

# Delete client directory

def delete_client_dir(install_client)
  client_dir = get_client_dir(install_client)
  if File.directory?(client_dir)
    if client_dir.match(/[a-z]/)
      if $os_name.match(/SunOS/)
        destroy_zfs_fs(client_dir)
      else
        message = "Information:\tRemoving client configuration files for #{install_client}"
        command = "rm #{client_dir}/*"
        execute_command(message,command)
        message = "Information:\tRemoving client configuration directory #{client_dir}"
        command = "rmdir #{client_dir}"
        execute_command(message,command)
      end
    end
  end
  return
end

# List clients for an install service

def list_clients(install_service)
  case install_service.downcase
  when /ai/
    list_ai_clients()
    return
  when /js|jumpstart/
    search_string = "sol_6|sol_7|sol_8|sol_9|sol_10"
  when /ks|kickstart/
    search_string = "centos|redhat|rhel|scientific|fedora"
  when /ps|preseed/
    search_string = "debian|ubuntu"
  when /vmware|vsphere|esx|vs/
    search_string = "vmware"
  when /ay|autoyast/
    search_string = "suse|sles"
  when /xb/
    search_string = "bsd|coreos"
  end
  service_list = Dir.entries($client_base_dir)
  service_list = service_list.grep(/#{search_string}|#{install_service}/)
  if service_list.length > 0
    if $output_format.match(/html/)
      if install_service.match(/[a-z,A-Z]/)
        handle_output("<h1>Available #{install_service} clients:</h1>")
      else
        handle_output("<h1>Available clients:</h1>")
      end
      handle_output("<table border=\"1\">")
      handle_output("<tr>")
      handle_output("<th>Client</th>")
      handle_output("<th>Service</th>")
      handle_output("<th>IP</th>")
      handle_output("<th>MAC</th>")
      handle_output("</tr>")
    else
      handle_output("")
      if install_service.match(/[a-z,A-Z]/)
        handle_output("Available #{install_service} clients:")
      else
        handle_output("Available clients:")
      end
      handle_output("")
    end
    service_list.each do |install_service|
      if install_service.match(/#{search_string}|#{install_service}/) and install_service.match(/[a-z,A-Z]/)
        repo_version_dir = $client_base_dir+"/"+install_service
        if File.directory?(repo_version_dir) or File.symlink?(repo_version_dir)
          client_list      = Dir.entries(repo_version_dir)
          client_list.each do |install_client|
            if install_client.match(/[a-z,A-Z,0-9]/)
              client_dir  = repo_version_dir+"/"+install_client
              install_ip  = get_install_ip(install_client)
              install_mac = get_install_mac(install_client)
              if File.directory?(client_dir)
                if $output_format.match(/html/)
                  handle_output("<tr>")
                  handle_output("<td>#{install_client}</td>")
                  handle_output("<td>#{install_service}</td>")
                  handle_output("<td>#{install_ip}</td>")
                  handle_output("<td>#{install_mac}</td>")
                  handle_output("</tr>")
                else
                  handle_output("#{install_client}\t[ service = #{install_service}, ip = #{install_ip}, mac = #{install_mac} ] ")
                end
              end
            end
          end
        end
      end
    end
    if $output_format.match(/html/)
      handle_output("</table>")
    end
  end
  handle_output("")
  return
end

# List appliances

def list_ovas()
  file_list = Dir.entries($iso_base_dir)
  handle_output("")
  handle_output("Virtual Appliances:")
  handle_output("")
  file_list.each do |file_name|
    if file_name.match(/ova$/)
      handle_output(file_name)
    end
  end
  handle_output("")
end

# Check directory ownership

def check_dir_owner(dir_name,uid)
  test_uid = File.stat(dir_name).uid
  if test_uid != uid.to_i
    message = "Information:\tChanging ownership of "+dir_name+" to "+uid.to_s
    command = "sudo sh -c 'chown -R #{uid.to_s} #{dir_name}'"
    execute_command(message,command)
  end
  return
end

# Print contents of file

def print_contents_of_file(message,file_name)
  if $verbose_mode == 1 or $output_format.match(/html/)
    if File.exist?(file_name)
      output = %x[cat '#{file_name}']
      if $output_format.match(/html/)
        handle_output("<table border=\"1\">")
        handle_output("<tr>")
        if message.length > 1
          handle_output("<th>#{message}</th>")
        else
          handle_output("<th>#{file_name}</th>")
        end
        handle_output("<tr>")
        handle_output("<td>")
        handle_output("<pre>")
        handle_output("#{output}")
        handle_output("</pre>")
        handle_output("</td>")
        handle_output("</tr>")
        handle_output("</table>")
      else
        if $verbose_mode == 1
          handle_output("")
          if message.length > 1
            handle_output("Information:\t#{message}")
          else
            handle_output("Information:\tContents of file #{file_name}")
          end
          handle_output("")
          handle_output(output)
          handle_output("")
        end
      end
    else
      handle_output("Warning:\tFile #{file_name} does not exist")
    end
  end
  return
end

# Show output of command

def show_output_of_command(message,output)
  if $output_format.match(/html/)
    handle_output("<table border=\"1\">")
    handle_output("<tr>")
    handle_output("<th>#{message}</th>")
    handle_output("<tr>")
    handle_output("<td>")
    handle_output("<pre>")
    handle_output("#{output}")
    handle_output("</pre>")
    handle_output("</td>")
    handle_output("</tr>")
    handle_output("</table>")
  else
    if $verbose_mode == 1
      handle_output("")
      handle_output("Information:\t#{message}:")
      handle_output("")
      handle_output(output)
      handle_output("")
    end
  end
  return
end

# Add NFS export

def add_nfs_export(export_name,export_dir,publisher_host)
  network_address  = publisher_host.split(/\./)[0..2].join(".")+".0"
  if $os_name.match(/SunOS/)
    if $os_rel.match(/11/)
      message  = "Enabling:\tNFS share on "+export_dir
      command  = "zfs set sharenfs=on #{$default_zpool}#{export_dir}"
      output   = execute_command(message,command)
      message  = "Setting:\tNFS access rights on "+export_dir
      command  = "zfs set share=name=#{export_name},path=#{export_dir},prot=nfs,anon=0,sec=sys,ro=@#{network_address}/24 #{$default_zpool}#{export_dir}"
      output   = execute_command(message,command)
    else
      dfs_file = "/etc/dfs/dfstab"
      message  = "Checking:\tCurrent NFS exports for "+export_dir
      command  = "cat #{dfs_file} |grep '#{export_dir}' |grep -v '^#'"
      output   = execute_command(message,command)
      if !output.match(/#{export_dir}/)
        backup_file(dfs_file)
        export  = "share -F nfs -o ro=@#{network_address},anon=0 #{export_dir}"
        message = "Adding:\tNFS export for "+export_dir
        command = "echo '#{export}' >> #{dfs_file}"
        execute_command(message,command)
        message = "Refreshing:\tNFS exports"
        command = "shareall -F nfs"
        execute_command(message,command)
      end
    end
  else
    dfs_file = "/etc/exports"
    message  = "Checking:\tCurrent NFS exports for "+export_dir
    command  = "cat #{dfs_file} |grep '#{export_dir}' |grep -v '^#'"
    output   = execute_command(message,command)
    if !output.match(/#{export_dir}/)
      if $os_name.match(/Darwin/)
        export = "#{export_dir} -alldirs -maproot=root -network #{network_address} -mask #{$default_netmask}"
      else
        export = "#{export_dir} #{network_address}/24(ro,no_root_squash,async,no_subtree_check)"
      end
      message = "Adding:\tNFS export for "+export_dir
      command = "echo '#{export}' >> #{dfs_file}"
      execute_command(message,command)
      message = "Refreshing:\tNFS exports"
      if $os_name.match(/Darwin/)
        command = "nfsd stop ; nfsd start"
      else
        command = "/sbin/exportfs -a"
      end
      execute_command(message,command)
    end
  end
  return
end

# Remove NFS export

def remove_nfs_export(export_dir)
  if $os_name.match(/SunOS/)
    zfs_test = %x[zfs list |grep #{export_dir}].chomp
    if zfs_test.match(/#{export_dir}/)
      message = "Disabling:\tNFS share on "+export_dir
      command = "zfs set sharenfs=off #{$default_zpool}#{export_dir}"
      execute_command(message,command)
    else
      if $verbose_mode == 1
        handle_output("Information:\tZFS filesystem #{$default_zpool}#{export_dir} does not exist")
      end
    end
  else
    dfs_file = "/etc/exports"
    message  = "Checking:\tCurrent NFS exports for "+export_dir
    command  = "cat #{dfs_file} |grep '#{export_dir}' |grep -v '^#'"
    output   = execute_command(message,command)
    if output.match(/#{export_dir}/)
      backup_file(dfs_file)
      tmp_file = "/tmp/dfs_file"
      message  = "Removing:\tExport "+export_dir
      command  = "cat #{dfs_file} |grep -v '#{export_dir}' > #{tmp_file} ; cat #{tmp_file} > #{dfs_file} ; rm #{tmp_file}"
      execute_command(message,command)
      if $os_name.match(/Darwin/)
        message  = "Restarting:\tNFS daemons"
        command  = "nfsd stop ; nfsd start"
        execute_command(message,command)
      else
        message  = "Restarting:\tNFS daemons"
        command  = "service nfsd restart"
        execute_command(message,command)
      end
    end
  end
  return
end

# Check we are running on the right architecture

def check_same_arch(install_arch)
  if !$os_arch.match(/#{install_arch}/)
    handle_output("Warning:\tSystem and Zone Architecture do not match")
    exit
  end
  return
end

# Delete file

def delete_file(file_name)
  if File.exist?(file_name)
    message = "Removing:\tFile "+file_name
    command = "rm #{file_name}"
    execute_command(message,command)
  end
end

# Get root password crypt

def get_root_password_crypt()
  password = $q_struct["root_password"].value
  result   = get_password_crypt(password)
  return result
end

# Get account password crypt

def get_admin_password_crypt()
  password = $q_struct["admin_password"].value
  result   = get_password_crypt(password)
  return result
end

# Check SSH keys

def check_ssh_keys()
  ssh_key = $home_dir+"/.ssh/id_rsa.pub"
  if !File.exist?(ssh_key)
    if $verbose_mode == 1
      handle_output("Generating:\tPublic SSH key file #{ssh_key}")
    end
    system("ssh-keygen -t rsa")
  end
  return
end

# Check IPS tools installed on OS other than Solaris

def check_ips()
  if $os_name.match(/Darwin/)
    check_osx_ips()
  end
  return
end

# Check Apache enabled

def check_apache_config()
  if $os_name.match(/Darwin/)
    service = "apache"
    check_osx_service_is_enabled(service)
  end
  return
end

# Check DHCPd config

def check_dhcpd_config(publisher_host)
  get_default_host()
  network_address   = $default_host.split(/\./)[0..2].join(".")+".0"
  broadcast_address = $default_host.split(/\./)[0..2].join(".")+".255"
  gateway_address   = $default_host.split(/\./)[0..2].join(".")+".254"
  output = ""
  if File.exist?($dhcpd_file)
    message = "Checking:\tDHCPd config for subnet entry"
    command = "cat #{$dhcpd_file} | grep 'subnet #{network_address}'"
    output  = execute_command(message, command)
  end
  if !output.match(/subnet/) and !output.match(/#{network_address}/)
    tmp_file    = "/tmp/dhcpd"
    backup_file = $dhcpd_file+".premode"
    file = File.open(tmp_file,"w")
    file.write("\n")
    if $os_name.match(/SunOS|Linux/)
      file.write("default-lease-time 900;\n")
      file.write("max-lease-time 86400;\n")
    end
    if $os_name.match(/Linux/)
      file.write("option space pxelinux;\n")
      file.write("option pxelinux.magic code 208 = string;\n")
      file.write("option pxelinux.configfile code 209 = text;\n")
      file.write("option pxelinux.pathprefix code 210 = text;\n")
      file.write("option pxelinux.reboottime code 211 = unsigned integer 32;\n")
      file.write("option architecture-type code 93 = unsigned integer 16;\n")
    end
    file.write("\n")
    if $os_name.match(/SunOS/)
      file.write("authoritative;\n")
      file.write("\n")
      file.write("option arch code 93 = unsigned integer 16;\n")
      file.write("option grubmenu code 150 = text;\n")
      file.write("\n")
      file.write("log-facility local7;\n")
      file.write("\n")
      file.write("class \"PXEBoot\" {\n")
      file.write("  match if (substring(option vendor-class-identifier, 0, 9) = \"PXEClient\");\n")
      file.write("  if option arch = 00:00 {\n")
      file.write("    filename \"default-i386/boot/grub/pxegrub2\";\n")
      file.write("  } else if option arch = 00:07 {\n")
      file.write("    filename \"default-i386/boot/grub/grub2netx64.efi\";\n")
      file.write("  }\n")
      file.write("}\n")
      file.write("\n")
      file.write("class \"SPARC\" {\n")
      file.write("  match if not (substring(option vendor-class-identifier, 0, 9) = \"PXEClient\");\n")
      file.write("  filename \"http://#{publisher_host}:5555/cgi-bin/wanboot-cgi\";\n")
      file.write("}\n")
      file.write("\n")
      file.write("allow booting;\n")
      file.write("allow bootp;\n")
    end
    if $os_name.match(/Linux/)
      file.write("class \"pxeclients\" {\n")
      file.write("  match if substring (option vendor-class-identifier, 0, 9) = \"PXEClient\";\n")
      file.write("  if option architecture-type = 00:07 {\n")
      file.write("    filename \"uefi/shim.efi\";\n")
      file.write("  } else {\n")
      file.write("    filename \"pxelinux/pxelinux.0\";\n")
      file.write("  }\n")
      file.write("}\n")
    end
    file.write("\n")
    if $os_name.match(/SunOS|Linux/)
      file.write("subnet #{network_address} netmask #{$default_netmask} {\n")
      file.write("  option broadcast-address #{broadcast_address};\n")
      file.write("  option routers #{gateway_address};\n")
      file.write("  next-server #{$default_host};\n")
      file.write("}\n")
    end
    file.write("\n")
    file.close
    if File.exist?($dhcpd_file)
      message = "Archiving DHCPd configuration file "+$dhcpd_file+" to "+backup_file
      command = "cp #{$dhcpd_file} #{backup_file}"
      execute_command(message,command)
    end
    message = "Creating DHCPd configuration file "+$dhcpd_file
    command = "cp #{tmp_file} #{$dhcpd_file}"
    execute_command(message,command)
    if $os_name.match(/SunOS/) and $os_rel.match(/5\.11/)
      message = "Setting\tDHCPd listening interface to "+$default_net
      command = "svccfg -s svc:/network/dhcp/server:ipv4 setprop config/listen_ifnames = astring: #{$default_net}"
      execute_command(message,command)
      message = "Refreshing\tDHCPd service"
      command = "svcadm refresh svc:/network/dhcp/server:ipv4"
      execute_command(message,command)
    end
    restart_dhcpd()
  end
  return
end

# Check package is installed

def check_rhel_package(package)
  message = "Checking:\t"+package+" is installed"
  command = "rpm -q #{package}"
  output  = execute_command(message,command)
  if !output.match(/#{package}/)
    message = "installing:\t"+package
    command = "yum -y install #{package}"
    execute_command(message,command)
  end
  return
end

# Check firewall is enabled

def check_rhel_service(service)
  message = "Checking:\t"+service+" is installed"
  command = "service #{service} status |grep dead"
  output  = execute_command(message,command)
  if output.match(/dead/)
    message = "Enabling:\t"+service
    if $os_rel.match(/^7/)
      command = "systemctl enable #{service}.service"
      command = "systemctl start #{service}.service"
    else
      command = "chkconfig --level 345 #{service} on"
    end
    execute_command(message,command)
  end
  return
end

# Check service is enabled

def check_rhel_firewall(service,port_info)
  if $os_rel.match(/^7/)
    message = "Information:\tChecking firewall configuration for "+service
    command = "firewall-cmd --list-services |grep #{service}"
    output  = execute_command(message,command)
    if !output.match(/#{service}/)
      message = "Information:\tAdding firewall rule for "+service
      command = "firewall-cmd --add-service=#{service} --permanent"
      execute_command(message,command)
    end
    if port_info.match(/[0-9]/)
      message = "Information:\tChecking firewall configuration for "+port_info
      command = "firewall-cmd --list-all |grep #{port_info}"
      output  = execute_command(message,command)
      if !output.match(/#{port_info}/)
        message = "Information:\tAdding firewall rule for "+port_info
        command = "firewall-cmd --zone=public --add-port=#{port_info} --permanent"
        execute_command(message,command)
      end
    end
  else
    if port_info.match(/[0-9]/)
      (port_no,protocol) = port_info.split(/\//)
      message = "Information:\tChecking firewall configuration for "+service+" on "+port_info
      command = "iptables --list-rules |grep #{protocol} |grep #{port_no}"
      output  = execute_command(message,command)
      if !output.match(/#{protocol}/)
        message = "Information:\tAdding firewall rule for "+service
        command = "iptables -I INPUT -p #{protocol} --dport #{port_no} -j ACCEPT ; service iptables save"
        execute_command(message,command)
      end
    end
  end
  return
end

# Check httpd enabled on Centos / Redhat

def check_yum_xinetd()
  check_rhel_package("xinetd")
  check_rhel_firewall("xinetd","")
  check_rhel_service("xinetd")
  return
end

# Check TFTPd enabled on CentOS / RedHat

def check_yum_tftpd()
  check_dir_exists($tftp_dir)
  check_rhel_package("tftp-server")
  check_rhel_firewall("tftp","")
  check_rhel_service("tftp")
  return
end

# Check DHCPd enabled on CentOS / RedHat

def check_yum_dhcpd()
  check_rhel_package("dhcp")
  check_rhel_firewall("dhcp","69/udp")
  check_rhel_service("dhcpd")
  return
end

# Check httpd enabled on Centos / Redhat

def check_yum_httpd()
  check_rhel_package("httpd")
  check_rhel_firewall("http","80/tcp")
  check_rhel_service("httpd")
  return
end

# Check TFTPd enabled on Debian / Ubuntu

def check_apt_tftpd()
  message    = "Checking:\tTFTPd is installed"
  command    = "dpkg -l tftpd |grep '^ii'"
  output     = execute_command(message,command)
  if !output.match(/tftp/)
    message = "installing:\tTFTPd"
    command = "apt-get -y install tftpd"
    execute_command(message,command)
  end
  return
end

# Check DHCPd enabled on Debian / Ubuntu

def check_apt_dhcpd()
  message = "Checking:\tDHCPd is installed"
  command = "dpkg -l isc-dhcp-server |grep '^ii'"
  output  = execute_command(message,command)
  if !output.match(/dhcp/)
    message = "installing:\tDHCPd"
    command = "yum -y install isc-dhcp-server"
    execute_command(message,command)
    message = "Enabling:\tDHCPd"
    command = "chkconfig dhcpd on"
    execute_command(message,command)
  end
  return
end

# Restart a service

def restart_service(service)
  refresh_service(service)
  return
end

# Restart xinetd

def restart_xinetd()
  service = "xinetd"
  service = get_install_service(service)
  refresh_service(service)
  return
end

# Restart tftpd

def restart_tftpd()
  service = "tftp"
  service = get_install_service(service)
  refresh_service(service)
  return
end

# Check tftpd config for Linux(turn on in xinetd config file /etc/xinetd.d/tftp)

def check_tftpd_config()
  if $os_name.match(/Linux/)
    tftpd_file = "/etc/xinetd.d/tftp"
    tmp_file   = "/tmp/tftp"
    if $os_info.match(/Ubuntu|Debian/)
      check_apt_tftpd
    else
      check_yum_tftpd
    end
    check_dir_exists($tftp_dir)
    if File.exist?(tftpd_file)
      disable_test =%x[cat #{tftpd_file} |grep disable |awk -F= '{print $2}']
    else
      disable_test = "yes"
    end
    if disable_test.match(/yes/)
      if File.exist?(tftpd_file)
        message = "Information:\tBacking up "+tftpd_file+" to "+tftpd_file+".premode"
        command = "cp #{tftpd_file} #{tftpd_file}.premode"
        execute_command(message,command)
      end
      file=File.open(tmp_file,"w")
      file.write("service tftp\n")
      file.write("{\n")
      file.write("\tprotocol        = udp\n")
      file.write("\tport            = 69\n")
      file.write("\tsocket_type     = dgram\n")
      file.write("\twait            = yes\n")
      file.write("\tuser            = root\n")
      if $os_name.match(/Ubuntu|Debian/)
        file.write("\tserver          = /usr/sbin/in.tftpd\n")
        file.write("\tserver_args     = /tftpboot\n")
      else
        file.write("\tserver          = /usr/sbin/in.tftpd\n")
        file.write("\tserver_args     = /var/lib/tftpboot -s\n")
      end
      file.write("\tdisable         = no\n")
      file.write("}\n")
      file.close
      message = "Creating:\tTFTPd configuration file "+tftpd_file
      command = "cp #{tmp_file} #{tftpd_file} ; rm #{tmp_file}"
      execute_command(message,command)
      restart_xinetd()
      restart_tftpd()
    end
  end
  return
end

# Check tftpd directory

def check_tftpd_dir()
  if $os_name.match(/SunOS/)
    old_tftp_dir = "/tftpboot"
    if !File.symlink?(old_tftp_dir)
      File.symlink($tftp_dir,old_tftp_dir)
    end
    message = "Checking:\tTFTPd service boot directory configuration"
    command = "svcprop -p inetd_start/exec svc:network/tftp/udp6"
    output  = execute_command(message,command)
    if !output.match(/netboot/)
      message = "Setting:\tTFTPd boot directory to "+$tftp_dir
      command = "svccfg -s svc:network/tftp/udp6 setprop inetd_start/exec = astring: '(\"/usr/sbin/in.tftpd\\ -s\\ /etc/netboot\")'"
      execute_command(message,command)
    end
  end
  return
end

# Check tftpd

def check_tftpd()
  check_tftpd_dir()
  if $os_name.match(/SunOS/)
    enable_service("svc:/network/tftp/udp6:default")
  end
  if $os_name.match(/Darwin/)
    check_osx_tftpd()
  end
  return
end

# Get client IP

def get_install_ip(install_client)
  install_ip  = ""
  hosts_file = "/etc/hosts"
  if File.exists?(hosts_file) or File.symlink?(hosts_file)
    file_array = IO.readlines(hosts_file)
    file_array.each do |line|
      line = line.chomp
      if line.match(/#{install_client}\s+/)
        install_ip = line.split(/\s+/)[0]
      end
    end
  end
  return install_ip
end

# Get client MAC

def get_install_mac(install_client)
  install_mac   = ""
  found_client = 0
  if File.exists?($dhcpd_file) or File.symlink?($dhcpd_file)
    file_array = IO.readlines($dhcpd_file)
    file_array.each do |line|
      line = line.chomp
      if line.match(/#{install_client} /)
        found_client = 1
      end
      if line.match(/hardware ethernet/) and found_client == 1
        install_mac = line.split(/\s+/)[3].gsub(/\;/,"")
        return install_mac
      end
    end
  end
  return install_mac
end

# Add hosts entry

def add_hosts_entry(install_client,install_ip)
  hosts_file = "/etc/hosts"
  message    = "Checking:\tHosts file for "+install_client
  command    = "cat #{hosts_file} |grep -v '^#' |grep '#{install_client}' |grep '#{install_ip}'"
  output     = execute_command(message,command)
  if !output.match(/#{install_client}/)
    backup_file(hosts_file)
    message = "Adding:\t\tHost "+install_client+" to "+hosts_file
    command = "echo \"#{install_ip}\\t#{install_client}.local\\t#{install_client}\\t# #{$default_admin_user}\" >> #{hosts_file}"
    output  = execute_command(message,command)
    if $os_name.match(/Darwin/)
      pfile   = "/Library/LaunchDaemons/homebrew.mxcl.dnsmasq.plist"
      if File.exist?(pfile)
        service = "dnsmasq"
        service = get_install_service(service)
        refresh_service(service)
      end
    end
  end
  return
end

# Remove hosts entry

def remove_hosts_entry(install_client,install_ip)
  tmp_file   = "/tmp/hosts"
  hosts_file = "/etc/hosts"
  message    = "Checking:\tHosts file for "+install_client
  if install_ip.match(/[0-9]/)
    command = "cat #{hosts_file} |grep -v '^#' |grep '#{install_client}' |grep '#{install_ip}'"
  else
    command = "cat #{hosts_file} |grep -v '^#' |grep '#{install_client}'"
  end
  output = execute_command(message,command)
  copy   = []
  if output.match(/#{install_client}/)
    file_info=IO.readlines(hosts_file)
    file_info.each do |line|
      if !line.match(/#{install_client}/)
        if install_ip.match(/[0-9]/)
          if !line.match(/^#{install_ip}/)
            copy.push(line)
          end
        else
          copy.push(line)
        end
      end
    end
    File.open(tmp_file,"w") {|file| file.puts copy}
    message = "Updating:\tHosts file "+hosts_file
    if $os_name.match(/Darwin/)
      command = "sudo sh -c 'cp #{tmp_file} #{hosts_file} ; rm #{tmp_file}'"
    else
      command = "cp #{tmp_file} #{hosts_file} ; rm #{tmp_file}"
    end
    execute_command(message,command)
  end
  return
end

# Add host to DHCP config

def add_dhcp_client(install_client,install_mac,install_ip,install_arch,install_service)
  if !install_mac.match(/:/)
    install_mac = install_mac[0..1]+":"+install_mac[2..3]+":"+install_mac[4..5]+":"+install_mac[6..7]+":"+install_mac[8..9]+":"+install_mac[10..11]
  end
  tmp_file = "/tmp/dhcp_"+install_client
  if !install_arch.match(/sparc/)
    tftp_pxe_file = install_mac.gsub(/:/,"")
    tftp_pxe_file = tftp_pxe_file.upcase
    if install_service.match(/sol/)
      suffix = ".bios"
    else
      if install_service.match(/bsd/)
        suffix = ".pxeboot"
      else
        suffix = ".pxelinux"
      end
    end
    tftp_pxe_file = "01"+tftp_pxe_file+suffix
  else
    tftp_pxe_file = "http://#{$default_host}:5555/cgi-bin/wanboot-cgi"
  end
  message = "Checking:\fIf DHCPd configuration contains "+install_client
  command = "cat #{$dhcpd_file} | grep '#{install_client}'"
  output  = execute_command(message,command)
  if !output.match(/#{install_client}/)
    backup_file($dhcpd_file)
    file = File.open(tmp_file,"w")
    file_info=IO.readlines($dhcpd_file)
    file_info.each do |line|
      file.write(line)
    end
    file.write("\n")
    file.write("host #{install_client} {\n")
    file.write("  fixed-address #{install_ip};\n")
    file.write("  hardware ethernet #{install_mac};\n")
    if install_service.match(/[a-z,A-Z]/)
      file.write("  filename \"#{tftp_pxe_file}\";\n")
    end
    file.write("}\n")
    file.close
    message = "Updating:\tDHCPd file "+$dhcpd_file
    command = "cp #{tmp_file} #{$dhcpd_file} ; rm #{tmp_file}"
    execute_command(message,command)
    restart_dhcpd()
  end
  check_dhcpd()
  check_tftpd()
  return
end

# Remove host from DHCP config

def remove_dhcp_client(install_client)
  found     = 0
  copy      = []
  if !File.exist?($dhcpd_file)
    handle_output("Warning:\tFile #{$dhcpd_file} does not exist")
  else
    file_info = IO.readlines($dhcpd_file)
    file_info.each do |line|
      if line.match(/^host #{install_client}/)
        found = 1
      end
      if found == 0
        copy.push(line)
      end
      if found == 1 and line.match(/\}/)
        found=0
      end
    end
    File.open($dhcpd_file,"w") {|file| file.puts copy}
  end
  return
end

# Backup file

def backup_file(file_name)
  date_string = get_date_string()
  backup_file = File.basename(file_name)+"."+date_string
  backup_file = $backup_dir+backup_file
  message     = "Archiving:\tFile "+file_name+" to "+backup_file
  command     = "cp #{file_name} #{backup_file}"
  execute_command(message,command)
  return
end

# Wget a file

def wget_file(file_url,file_name)
  if $download_mode == 1
    wget_test = %[which wget].chomp
    if wget_test.match(/bin/)
      command  = "wget #{file_url} -O #{file_name}"
    else
      command  = "curl -o #{file_name } #{file_url}"
    end
    file_dir = File.dirname(file_name)
    check_dir_exists(file_dir)
    message  = "Fetching:\tURL "+file_url+" to "+file_name
    execute_command(message,command)
  end
  return
end
# Find client MAC

def get_install_mac(install_client)
  ethers_file = "/etc/ethers"
  output      = ""
  found       = 0
  if File.exist?(ethers_file)
    message    = "Checking:\tFile "+ethers_file+" for "+install_client+" MAC address"
    command    = "cat #{ethers_file} |grep '#{install_client} '|awk '{print $2}'"
    install_mac = execute_command(message,command)
    install_mac = install_mac.chomp
  end
  if !output.match(/[0-9]/)
    file=IO.readlines($dhcpd_file)
    file.each do |line|
      line=line.chomp
      if line.match(/#{install_client}/)
        found=1
      end
      if found == 1
        if line.match(/ethernet/)
          install_mac = line.split(/ ethernet /)[1]
          install_mac = install_mac.gsub(/\;/,"")
          return install_mac
        end
      end
    end
  end
  return install_mac
end

# Check if a directory exists
# If not create it

def check_dir_exists(dir_name)
  output  = ""
  if !File.directory?(dir_name) and !File.symlink?(dir_name)
    if dir_name.match(/[a-z,A-Z]/)
      message = "Information:\tCreating: "+dir_name
      command = "mkdir -p '#{dir_name}'"
      output  = execute_command(message,command)
    end
  end
  return output
end

# Check a filesystem / directory exists

def check_fs_exists(dir_name)
  output = ""
  if $os_name.match(/SunOS/)
    output = check_zfs_fs_exists(dir_name)
  else
    check_dir_exists(dir_name)
  end
  return output
end

# Check if a ZFS filesystem exists
# If not create it

def check_zfs_fs_exists(dir_name)
  output = ""
  if !File.directory?(dir_name)
    if $os_name.match(/SunOS/)
      if dir_name.match(/clients/)
        root_dir = dir_name.split(/\//)[0..-2].join("/")
        if !File.directory?(root_dir)
          check_zfs_fs_exists(root_dir)
        end
      end
      if dir_name.match(/ldoms|zones/)
        zfs_name = $default_dpool+dir_name
      else
        zfs_name = $default_zpool+dir_name
      end
      if dir_name.match(/vmware_|openbsd_|coreos_/) or $os_rel.to_i > 10
        install_service = File.basename(dir_name)
        mount_dir    = $tftp_dir+"/"+install_service
        if !File.directory?(mount_dir)
          Dir.mkdir(mount_dir)
        end
      else
        mount_dir = dir_name
      end
      message      = "Information:\tCreating "+dir_name+" with mount point "+mount_dir
      command      = "zfs create -o mountpoint=#{mount_dir} #{zfs_name}"
      execute_command(message,command)
      if dir_name.match(/vmware_|openbsd_|coreos_/) or $os_rel.to_i > 10
        message = "Information:\tSymlinking "+mount_dir+" to "+dir_name
        command = "ln -s #{mount_dir} #{dir_name}"
        execute_command(message,command)
      end
    else
      check_dir_exists(dir_name)
    end
  end
  return output
end

# Destroy a ZFS filesystem

def destroy_zfs_fs(dir_name)
  output = ""
  zfs_list = %x[zfs list |grep -v NAME |awk '{print $5}' |grep "^#{dir_name}$"].chomp
  if zfs_list.match(/#{dir_name}/)
    zfs_name = %x[zfs list |grep -v NAME |grep "#{dir_name}$" |awk '{print $1}'].chomp
    if $destroy_fs !~ /y|n/
      while $destroy_fs !~ /y|n/
        print "Destroy ZFS filesystem "+zfs_name+" [y/n]: "
        $destroy_fs = gets.chomp
      end
    end
    if $destroy_fs.match(/y|Y/)
      if File.directory?(dir_name)
        if dir_name.match(/netboot/)
          install_service = "svc:/network/tftp/udp6:default"
          disable_service(install_service)
        end
        message = "Warning:\tDestroying "+dir_name
        command = "zfs destroy -r -f #{zfs_name}"
        output  = execute_command(message,command)
        if dir_name.match(/netboot/)
          enable_service(install_service)
        end
      end
    end
  end
  if File.directory?(dir_name)
    Dir.rmdir(dir_name)
  end
  return output
end

# Routine to execute command
# Prints command if verbose switch is on
# Does not execute cerver/client import/create operations in test mode

def execute_command(message,command)
  if command.match(/prlctl/) and !$os_name.match(/Darwin/)
    return
  else
    if command.match(/prlctl/)
      parallels_test = %x[which prlctl].chomp
      if !parallels_test.match(/prlctl/)
        return
      end
    end
  end
  output  = ""
  execute = 0
  if $verbose_mode == 1
    if message.match(/[a-z,A-Z,0-9]/)
      handle_output(message)
    end
  end
  if $test_mode == 1
    if !command.match(/create|update|import|delete|svccfg|rsync|cp|touch|svcadm|VBoxManage|vmrun|docker/)
      execute = 1
    end
  else
    execute = 1
  end
  if execute == 1
    if $id != 0
      if !command.match(/brew |hg|pip|VBoxManage|netstat|df|vmrun|noVNC|docker|packer/)
        if $use_sudo != 0
          command = "sudo sh -c '"+command+"'"
        end
      end
    end
    if $verbose_mode == 1
      handle_output("Executing:\t#{command}")
    end
    if $execute_host.match(/localhost/)
      if command.match(/VBoxManage/)
        if $vbox_bin.match(/[a-z]/)
          output = %x[#{command}]
        end
      else
        output = %x[#{command}]
      end
    else
      Net::SSH.start(hostname, username, :password => password, :paranoid => false) do |ssh_session|
        output = ssh_session.exec!(command)
      end
    end
  end
  if $verbose_mode == 1
    if output.length > 1
      if !output.match(/\n/)
        handle_output("Output:\t\t#{output}")
      else
        multi_line_output = output.split(/\n/)
        multi_line_output.each do |line|
          handle_output("Output:\t\t#{line}")
        end
      end
    end
  end
  return output
end

# Convert current date to a string that can be used in file names

def get_date_string()
  time        = Time.new
  time        = time.to_a
  date        = Time.utc(*time)
  date_string = date.to_s.gsub(/\s+/,"_")
  date_string = date_string.gsub(/:/,"_")
  date_string = date_string.gsub(/-/,"_")
  if $verbose_mode == 1
    handle_output("Information:\tSetting date string to #{date_string}")
  end
  return date_string
end

# Create an encrypted password field entry for a give password

def get_password_crypt(password)
  crypt = UnixCrypt::MD5.build(password)
  return crypt
end

# Restart DHCPd

def restart_dhcpd()
  if $os_name.match(/SunOS/)
    function         = "refresh"
    smf_install_service = "svc:/network/dhcp/server:ipv4"
    output           = handle_smf_service(function,smf_install_service)
  else
    install_service = "dhcpd"
    refresh_service(install_service)
  end
  return output
end

# Check DHPCPd is running

def check_dhcpd()
  message = "Checking:\tDHCPd is running"
  if $os_name.match(/SunOS/)
    command = "svcs -l svc:/network/dhcp/server:ipv4"
    output  = execute_command(message,command)
    if output.match(/disabled/)
      function         = "enable"
      smf_install_service = "svc:/network/dhcp/server:ipv4"
      output           = handle_smf_service(function,smf_install_service)
    end
    if output.match(/maintenance/)
      function         = "refresh"
      smf_install_service = "svc:/network/dhcp/server:ipv4"
      output           = handle_smf_service(function,smf_install_service)
    end
  end
  if $os_name.match(/Darwin/)
    command = "ps aux |grep '/usr/local/bin/dhcpd' |grep -v grep"
    output  = execute_command(message,command)
    if !output.match(/dhcp/)
      service = "dhcp"
      check_osx_service_is_enabled(service)
      install_service = "dhcp"
      refresh_service(install_service)
    end
    check_osx_tftpd()
  end
  return output
end

# Get service basename

def get_service_base_name(install_service)
  install_service = install_service.gsub(/_i386|_x86_64|_sparc/,"")
  return install_service
end

# Get service name

def get_install_service(install_service)
  if $os_name.match(/SunOS/)
    if install_service.match(/apache/)
      install_service = "svc:/network/http:apache22"
    end
    if install_service.match(/dhcp/)
      install_service = "svc:/network/dhcp/server:ipv4"
    end
  end
  if $os_name.match(/Darwin/)
    if install_service.match(/apache/)
      install_service = "org.apache.httpd"
    end
    if install_service.match(/dhcp/)
      install_service = "homebrew.mxcl.isc-dhcp"
    end
    if install_service.match(/dnsmasq/)
      install_service = "homebrew.mxcl.dnsmasq"
    end
    if install_service.match(/^puppet$/)
      install_service = "com.puppetlabs.puppet.plist"
    end
    if install_service.match(/^puppetmaster$/)
      install_service = "com.puppetlabs.puppetmaster.plist"
    end
  end
  if $os_name.match(/RedHat|CentOS|SuSE|Ubuntu/)
  end
  return install_service
end

# Enable service

def enable_service(install_service)
  install_service = get_install_service(install_service)
  if $os_name.match(/SunOS/)
    output = enable_smf_service(install_service)
  end
  if $os_name.match(/Darwin/)
    output = enable_osx_service(install_service)
  end
  if $os_name.match(/Linux/)
    output = enable_linux_service(install_service)
  end
  return output
end

# Disable service

def disable_service(install_service)
  install_service = get_install_service(install_service)
  if $os_name.match(/SunOS/)
    output = disable_smf_service(install_service)
  end
  if $os_name.match(/Darwin/)
    output = disable_osx_service(install_service)
  end
  return output
end

# Refresh / Restart service

def refresh_service(install_service)
  install_service = get_install_service(install_service)
  if $os_name.match(/SunOS/)
    output = refresh_smf_service(install_service)
  end
  if $os_name.match(/Darwin/)
    output = refresh_osx_service(install_service)
  end
  if $os_name.match(/Linux/)
    restart_linux_service(install_service)
  end
  return output
end

# Calculate route

def get_ipv4_default_route(install_ip)
  octets             = install_ip.split(/\./)
  octets[3]          = "254"
  ipv4_default_route = octets.join(".")
  return ipv4_default_route
end

# Create a ZFS filesystem for ISOs if it doesn't exist
# Eg /export/isos
# This could be an NFS mount from elsewhere
# If a directory already exists it will do nothing
# It will check that there are ISOs in the directory
# If none exist it will exit

def check_iso_base_dir(search_string)
  iso_list = []
  if $verbose_mode == 1
    handle_output("Checking:\t#{$iso_base_dir}")
  end
  check_fs_exists($iso_base_dir)
  message  = "Getting:\t"+$iso_base_dir+" contents"
  if search_string.match(/[a-z,A-Z]/)
    command  = "ls #{$iso_base_dir}/*.iso |egrep \"#{search_string}\" |grep -v '2.iso' |grep -v 'supp-server'"
  else
    command  = "ls #{$iso_base_dir}/*.iso |grep -v '2.iso' |grep -v 'supp-server'"
  end
  iso_list = execute_command(message,command)
  if search_string.match(/sol_11/)
    if !iso_list.grep(/full/)
      handle_output("Warning:\tNo full repository ISO images exist in #{$iso_base_dir}")
      if $test_mode != 1
        exit
      end
    end
  end
  iso_list = iso_list.split(/\n/)
  return iso_list
end

# Check client architecture

def check_install_arch(install_arch,opt)
  if !install_arch.match(/i386|sparc|x86_64/)
    if opt["F"] or opt["O"]
      if opt["A"]
        handle_output("Information:\tSetting architecture to x86_64")
        install_arch = "x86_64"
      end
    end
    if opt["n"]
      install_service = opt["n"]
      service_arch = install_service.split("_")[-1]
      if service_arch.match(/i386|sparc|x86_64/)
        install_arch = service_arch
      end
    end
  end
  if !install_arch.match(/i386|sparc|x86_64/)
    handle_output("Warning:\tInvalid architecture specified")
    handle_output("Warning:\tUse --arch i386, --arch x86_64 or --arch sparc")
    exit
  end
  return install_arch
end

# Check client MAC

def check_install_mac(install_mac,install_vm)
  if !install_mac.match(/:/)
    if install_mac.length != 12
      handle_output("Warning:\tInvalid MAC address")
      install_mac = generate_mac_address(install_vm)
      handle_output("Information:\tGenerated new MAC address: #{install_mac}")
    else
      chars       = install_mac.split(//)
      install_mac = chars[0..1].join+":"+chars[2..3].join+":"+chars[4..5].join+":"+chars[6..7].join+":"+chars[8..9].join+":"+chars[10..11].join
    end
  end
  macs = install_mac.split(":")
  if macs.length != 6
    handle_output("Warning:\tInvalid MAC address")
    exit
  end
  macs.each do |mac|
    if mac =~ /[G-Z]|[g-z]/ or mac.length != 2
      handle_output("Warning:\tInvalid MAC address")
      install_mac = generate_mac_address(install_vm)
      handle_output("Information:\tGenerated new MAC address: #{install_mac}")
    end
  end
  return install_mac
end

# Check install IP

def check_install_ip(install_ip)
  ips = install_ip.split(".")
  if ips.length != 4
    handle_output("Warning:\tInvalid IP Address")
    exit
  end
  ips.each do |ip|
    if ip =~ /[a-z,A-Z]/ or ip.length > 3 or ip.to_i > 254
      handle_output("Warning:\tInvalid IP Address")
      exit
    end
  end
  return
end


# Add apache proxy

def add_apache_proxy(publisher_host,publisher_port,service_base_name)
  if $os_name.match(/SunOS/)
    apache_config_file = "/etc/apache2/2.2/httpd.conf"
  end
  if $os_name.match(/Darwin/)
    apache_config_file = "/etc/apache2/httpd.conf"
  end
  if $os_name.match(/Linux/)
    apache_config_file = "/etc/httpd/conf/httpd.conf"
  end
  apache_check = %x[cat #{apache_config_file} |grep #{service_base_name}]
  if !apache_check.match(/#{service_base_name}/)
    message = "Archiving:\t"+apache_config_file+" to "+apache_config_file+".no_"+service_base_name
    command = "cp #{apache_config_file} #{apache_config_file}.no_#{service_base_name}"
    execute_command(message,command)
    message = "Adding:\t\tProxy entry to "+apache_config_file
    command = "echo 'ProxyPass /"+service_base_name+" http://"+publisher_host+":"+publisher_port+" nocanon max=200' >>"+apache_config_file
    execute_command(message,command)
    install_service = "apache"
    enable_service(install_service)
    refresh_service(install_service)
  end
  return
end

# Remove apache proxy

def remove_apache_proxy(service_base_name)
  if $os_name.match(/SunOS/)
    apache_config_file = "/etc/apache2/2.2/httpd.conf"
  end
  if $os_name.match(/Darwin/)
    apache_config_file = "/etc/apache2/httpd.conf"
  end
  if $os_name.match(/Linux/)
    apache_config_file = "/etc/httpd/conf/httpd.conf"
  end
  message      = "Checking:\tApache confing file "+apache_config_file+" for "+service_base_name
  command      = "cat #{apache_config_file} |grep '#{service_base_name}'"
  apache_check = execute_command(message,command)
  if apache_check.match(/#{service_base_name}/)
    restore_file = apache_config_file+".no_"+service_base_name
    if File.exist?(restore_file)
      message = "Restoring:\t"+restore_file+" to "+apache_config_file
      command = "cp #{restore_file} #{apache_config_file}"
      execute_command(message,command)
      install_service = "apache"
      refresh_service(install_service)
    end
  end
end

# Add apache alias

def add_apache_alias(service_base_name)
  if service_base_name.match(/^\//)
    apache_alias_dir  = service_base_name
    service_base_name = File.basename(service_base_name)
  else
    apache_alias_dir = $repo_base_dir+"/"+service_base_name
  end
  if $os_name.match(/SunOS/)
    apache_config_file = "/etc/apache2/2.2/httpd.conf"
  end
  if $os_name.match(/Darwin/)
    apache_config_file = "/etc/apache2/httpd.conf"
  end
  if $os_name.match(/Linux/)
    apache_config_file = "/etc/httpd/conf/httpd.conf"
    if $os_info.match(/CentOS|RedHat/)
      apache_doc_root = "/var/www/html"
      apache_doc_dir  = apache_doc_root+"/"+service_base_name
    end
  end
  if $os_name.match(/SunOS/)
    tmp_file     = "/tmp/httpd.conf"
    message      = "Checking:\tApache confing file "+apache_config_file+" for "+service_base_name
    command      = "cat #{apache_config_file} |grep '/#{service_base_name}'"
    apache_check = execute_command(message,command)
    if !apache_check.match(/#{service_base_name}/)
      message = "Archiving:\tApache config file "+apache_config_file+" to "+apache_config_file+".no_"+service_base_name
      command = "cp #{apache_config_file} #{apache_config_file}.no_#{service_base_name}"
      execute_command(message,command)
      if $verbose_mode == 1
        handle_output("Adding:\t\tDirectory and Alias entry to #{apache_config_file}")
      end
      message = "Copying:\tApache config file so it can be edited"
      command = "cp #{apache_config_file} #{tmp_file} ; chown #{$id} #{tmp_file}"
      execute_command(message,command)
      output = File.open(tmp_file,"a")
      output.write("<Directory #{apache_alias_dir}>\n")
      output.write("Options Indexes FollowSymLinks\n")
      output.write("Allow from #{$default_apache_allow}\n")
      output.write("</Directory>\n")
      output.write("Alias /#{service_base_name} #{apache_alias_dir}\n")
      output.close
      message = "Updating:\tApache config file"
      command = "cp #{tmp_file} #{apache_config_file} ; rm #{tmp_file}"
      execute_command(message,command)
    end
    if $os_name.match(/SunOS|Linux/)
      if $os_name.match(/Linux/)
        install_service = "httpd"
      else
        install_service = "apache"
      end
      enable_service(install_service)
      refresh_service(install_service)
    end
    if $os_name.match(/Linux/)
      if $os_info.match(/RedHat/)
        if $os_ver.match(/^7|^6\.7/)
          httpd_p = "httpd_sys_rw_content_t"
          message = "Information:\tFixing permissions on "+$client_base_dir
          command = "chcon -R -t #{httpd_p} #{$client_base_dir}"
          execute_command(message,command)
        end
      end
    end
  end
  return
end

# Remove apache alias

def remove_apache_alias(service_base_name)
  remove_apache_proxy(service_base_name)
end

# Mount full repo isos under iso directory
# Eg /export/isos
# An example full repo file name
# /export/isos/sol-11_1-repo-full.iso
# It will attempt to mount them
# Eg /cdrom
# If there is something mounted there already it will unmount it

def mount_iso(iso_file)
  handle_output("Information:\tProcessing: #{iso_file}")
  output  = check_dir_exists($iso_mount_dir)
  message = "Checking:\tExisting mounts"
  command = "df |awk '{print $NF}' |grep '^#{$iso_mount_dir}$'"
  output  = execute_command(message,command)
  if output.match(/[a-z,A-Z]/)
    message = "Information:\tUnmounting: "+$iso_mount_dir
    command = "umount "+$iso_mount_dir
    output  = execute_command(message,command)
  end
  message = "Information:\tMounting ISO "+iso_file+" on "+$iso_mount_dir
  if $os_name.match(/SunOS/)
    command = "mount -F hsfs "+iso_file+" "+$iso_mount_dir
  end
  if $os_name.match(/Darwin/)
    command = "sudo hdiutil attach -nomount \"#{iso_file}\" |head -1 |awk '{print $1}'"
    if $verbose_mode == 1
      handle_output("Executing:\t#{command}")
    end
    disk_id = %x[#{command}]
    disk_id = disk_id.chomp
    command = "sudo mount -t cd9660 -o ro "+disk_id+" "+$iso_mount_dir
  end
  if $os_name.match(/Linux/)
    command = "mount -t iso9660 -o loop "+iso_file+" "+$iso_mount_dir
  end
  output = execute_command(message,command)
  readme = $iso_mount_dir+"/README.TXT"
  if File.exist?(readme)
    text = IO.readlines(readme)
    if text.grep(/UDF/)
      umount_iso()
      if $os_name.match(/Darwin/)
        command = "sudo hdiutil attach -nomount \"#{iso_file}\" |head -1 |awk '{print $1}'"
        if $verbose_mode == 1
          handle_output("Executing:\t#{command}")
        end
        disk_id = %x[#{command}]
        disk_id = disk_id.chomp
        command = "sudo mount -t udf -o ro "+disk_id+" "+$iso_mount_dir
        output  = execute_command(message,command)
      end
    end
  end
  if iso_file.match(/sol/)
    if iso_file.match(/\-ga\-/)
      if iso_file.match(/sol\-10/)
        iso_test_dir = $iso_mount_dir+"/boot"
      else
        iso_test_dir = $iso_mount_dir+"/installer"
      end
    else
      iso_test_dir = $iso_mount_dir+"/repo"
    end
  else
    case iso_file
    when /VM/
      iso_test_dir = $iso_mount_dir+"/upgrade"
    when /Win|Srv|[0-9][0-9][0-9][0-9]/
      iso_test_dir = $iso_mount_dir+"/sources"
    when /SLE/
      iso_test_dir = $iso_mount_dir+"/suse"
    when /CentOS|SL/
      iso_test_dir = $iso_mount_dir+"/repodata"
    when /rhel|OracleLinux|Fedora/
      if iso_file.match(/rhel-server-5/)
        iso_test_dir = $iso_mount_dir+"/Server"
      else
        iso_test_dir = $iso_mount_dir+"/Packages"
      end
    when /VCSA/
      iso_test_dir = $iso_mount_dir+"/vcsa"
    when /install|FreeBSD/
      iso_test_dir = $iso_mount_dir+"/etc"
    when /coreos/
      iso_test_dir = $iso_mount_dir+"/coreos"
    else
      iso_test_dir = $iso_mount_dir+"/install"
    end
  end
  if !File.directory?(iso_test_dir) and !File.exist?(iso_test_dir) and !iso_file.match(/DVD2\.iso|2of2\.iso|repo-full|VCSA/)
    handle_output("Warning:\tISO did not mount, or this is not a repository ISO")
    handle_output("Warning:\t#{iso_test_dir} does not exit")
    if $test_mode != 1
      umount_iso()
      exit
    end
  end
  return
end

# Check my directory exists

def check_my_dir_exists(dir_name)
  if !File.directory?(dir_name) and !File.symlink?(dir_name)
    if $verbose_mode == 1
      handle_output("Information:\tCreating directory '#{dir_name}'")
    end
    system("mkdir #{dir_name}")
  else
    if $verbose_mode == 1
      handle_output("Information:\tDirectory '#{dir_name}' already exists")
    end
  end
  return
end

# Check ISO mounted for OS X based server

def check_osx_iso_mount(mount_dir,iso_file)
  check_dir_exists(mount_dir)
  test_dir = mount_dir+"/boot"
  if !File.directory?(test_dir)
    message = "Mounting:\ISO "+iso_file+" on "+mount_dir
    command = "hdiutil mount #{iso_file} -mountpoint #{mount_dir}"
    output  = execute_command(message,command)
  end
  return output
end

# Copy repository from ISO to local filesystem

def copy_iso(iso_file,repo_version_dir)
  if $verbose_mode == 1
    handle_output("Checking:\tIf we can copy data from full repo ISO")
  end
  if iso_file.match(/sol/)
    iso_test_dir = $iso_mount_dir+"/repo"
    if File.directory?(iso_test_dir)
      iso_repo_dir = iso_test_dir
    else
      iso_test_dir = $iso_mount_dir+"/publisher"
      if File.directory?(iso_test_dir)
        iso_repo_dir = $iso_mount_dir
      else
        handle_output("Warning:\tRepository source directory does not exist")
        if $test_mode != 1
          exit
        end
      end
    end
    test_dir = repo_version_dir+"/publisher"
  else
    iso_repo_dir = $iso_mount_dir
    case iso_file
    when /CentOS|rhel|OracleLinux|Fedora/
      test_dir = repo_version_dir+"/isolinux"
    when /VCSA/
      test_dir = repo_version_dir+"/vcsa"
    when /VM/
      test_dir = repo_version_dir+"/upgrade"
    when /install|FreeBSD/
      test_dir = repo_version_dir+"/etc"
    when /coreos/
      test_dir = repo_version_dir+"/coreos"
    when /SLES/
      test_dir = repo_version_dir+"/suse"
    else
      test_dir = repo_version_dir+"/install"
    end
  end
  if !File.directory?(repo_version_dir) and !File.symlink?(repo_version_dir) and !iso_file.match(/2\.iso/)
    handle_output("Warning:\tRepository directory #{repo_version_dir} does not exist")
    if $test_mode != 1
      exit
    end
  end
  if !File.directory?(test_dir) or iso_file.match(/DVD2\.iso|2of2\.iso/)
    if iso_file.match(/sol/)
      if !File.directory?(iso_repo_dir)
        handle_output("Warning:\tRepository source directory #{iso_repo_dir} does not exist")
        if $test_mode != 1
          exit
        end
      end
      message = "Copying:\t"+iso_repo_dir+" contents to "+repo_version_dir
      command = "rsync -a #{iso_repo_dir}/* #{repo_version_dir}"
      output  = execute_command(message,command)
      if $os_name.match(/SunOS/)
        message = "Rebuilding:\tRepository in "+repo_version_dir
        command = "pkgrepo -s #{repo_version_dir} rebuild"
        output  = execute_command(message,command)
      end
    else
      check_dir_exists(test_dir)
      message = "Copying:\t"+iso_repo_dir+" contents to "+repo_version_dir
      command = "rsync -a #{iso_repo_dir}/* #{repo_version_dir}"
      if repo_version_dir.match(/sles_12/)
        if !iso_file.match(/2\.iso/)
          output  = execute_command(message,command)
        end
      else
        handle_output(message)
        output  = execute_command(message,command)
      end
    end
  end
  return
end

# List domains/zones/etc instances

def list_doms(dom_type,dom_command)
  message = "Information:\nAvailable #{dom_type}(s)"
  command = dom_command
  output  = execute_command(message,command)
  output  = output.split("\n")
  if output.length > 0
    if $output_format.match(/html/)
      handle_output("<h1>Available #{dom_type}(s)</h1>")
      handle_output("<table border=\"1\">")
      handle_output("<tr>")
      handle_output("<th>Service</th>")
      handle_output("</tr>")
    else
      handle_output("") 
      handle_output("Available #{dom_type}(s):")
      handle_output("") 
    end
    output.each do |line|
      line = line.chomp
      line = line.gsub(/\s+$/,"")
      if $output_format.match(/html/)
        handle_output("<tr>")
        handle_output("<td>#{line}</td>")
        handle_output("</tr>")
      else
        handle_output(line)
      end
    end
    if $output_format.match(/html/)
      handle_output("</table>")
    end
  end
  return
end

# List services

def list_services(service_type,service_command)
  dom_type    = service_type+" service"
  dom_command = service_command
  list_doms(dom_type,dom_command)
  return
end

# Unmount ISO

def umount_iso()
  if $os_name.match(/Darwin/)
    command = "df |grep '#{$iso_mount_dir}$' |head -1 |awk '{print $1}'"
    if $verbose_mode == 1
      handle_output("Executing:\t#{command}")
    end
    disk_id = %x[#{command}]
    disk_id = disk_id.chomp
  end
  if $os_name.match(/Darwin/)
    message = "Detaching:\tISO device "+disk_id
    command = "sudo hdiutil detach #{disk_id}"
    execute_command(message,command)
  else
    message = "Unmounting:\tISO mounted on "+$iso_mount_dir
    command = "umount #{$iso_mount_dir}"
    execute_command(message,command)
  end
  return
end

# Clear a service out of maintenance mode

def clear_service(smf_service)
  message    = "Checking:\tStatus of service "+smf_service
  command    = "sleep 5 ; svcs -a |grep '#{install_service}' |awk '{print $1}'"
  output     = execute_command(message,command)
  if output.match(/maintenance/)
    message    = "Clearing:\tService "+smf_service
    command    = "svcadm clear #{smf_service}"
    output     = execute_command(message,command)
  end
  return
end


# Occassionally DHCP gets stuck if it's restart to often
# Clear it out of maintenance mode

def clear_solaris_dhcpd()
  smf_service = "svc:/network/dhcp/server:ipv4"
  clear_service(smf_service)
  return
end

# Brew install a package on OS X

def brew_install(pkg_name)
  command = "brew install #{pkg_name}"
  message = "Information:\tInstalling #{pkg_name}"
  execute_command(message,command)
  return
end

