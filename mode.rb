#!/usr/bin/env ruby

# Name:         mode (Multi OS Deployment Engine)
# Version:      3.2.6
# Release:      1
# License:      CC-BA (Creative Commons By Attribution)
#               http://creativecommons.org/licenses/by/4.0/legalcode
# Group:        System
# Source:       N/A
# URL:          http://lateralblast.com.au/
# Distribution: UNIX
# Vendor:       Lateral Blast
# Packager:     Richard Spindler <richard@lateralblast.com.au>
# Description:  Script to automate creation of server configuration for
#               Solaris and other OS

# Additional notes:
#
# - Swapped Dir.exist for File.directory so ruby 2.x is not required
# - Swapped Dir.home for ENV["HOME"] so ruby 2.x is not required

require 'rubygems'
require 'getopt/long'
require 'builder'
require 'parseconfig'
require 'unix_crypt'
require 'pathname'
require 'netaddr'
require 'json'
require 'pathname'
require 'ipaddr'

begin
  require 'net/ssh'
  require 'nokogiri'
  require 'mechanize'
  require 'uri'
  require 'socket'
  require 'net/http'
  require 'net/scp'
  require 'terminfo'
rescue LoadError
end

# Set up some global variables/defaults

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
$default_domainname       = "lab.net"
$default_search           = "local"
$default_files            = "files"
$default_hosts            = "files dns"
$default_root_password    = "XXXX"
$default_admin_password   = "YYYY"
$default_maas_admin       = "root"
$default_maas_email       = $default_maas_admin+"@"+$default_host
$default_mass_password    = $default_admin_password
$default_server_admin     = "root"
$default_server_password  = "XXXX"
$use_alt_repo             = 0
$destroy_fs               = "n"
$use_defaults             = 0
$default_apache_allow     = ""
$default_admin_name       = "Sys Admin"
$default_admin_user       = "sysadmin"
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
$valid_os_list            = [ 'sol', 'VMware-VMvisor', 'CentOS', 'OracleLinux', 'SLES', 'openSUSE', 'ubuntu', 'debian', 'Fedora', 'rhel', 'SL', 'purity' ]
$valid_linux_os_list      = [ 'CentOS', 'OracleLinux', 'SLES', 'openSUSE', 'ubuntu', 'debian', 'Fedora', 'rhel', 'SL', 'purity' ]
$valid_arch_list          = [ 'x86_64', 'i386', 'sparc' ]
$valid_console_list       = [ 'text', 'console', 'x11', 'headless' ]
$valid_method_list        = [ 'ks', 'xb', 'vs', 'ai', 'js', 'ps', 'lxc', 'ay', 'image' ]
$valid_type_list          = [ 'iso', 'flar', 'ova', 'snapshot', 'service', 'boot', 'cdrom', 'net', 'disk', 'client', 'dvd', 'server', 'vcsa', 'packer' ]
$valid_mode_list          = [ 'client', 'server', 'osx' ]
$valid_vm_list            = [ 'vbox', 'fusion', 'zone', 'lxc', 'cdom', 'gdom', 'parallels' ]
$execute_host             = "localhost"
$default_options          = ""
$do_checksums             = 0
$default_ipfamily         = "ipv4"
$default_datastore        = "datastore1"
$default_server_network   = "VM Network"
$default_diskmode         = "thin"
$default_sitename         = $default_domainname.split(".")[0]
$default_vcsa_size        = "tiny"
$default_thindiskmode     = "true"
$default_sshenable        = "true"
$default_httpd_port       = "8888"

# Declare some package versions

$facter_version = "1.7.4"
$hiera_version  = "1.3.1"
$puppet_version = "3.4.2"
$packer_version = "0.8.6"

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
    $valid_vm_list = [ 'vbox', 'fusion', 'parallels' ]
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

# Calculate CIDR

def netmask_to_cidr(netmask)
  cidr = NetAddr::CIDR.create('0.0.0.0/'+netmask).netmask
  return cidr
end

$default_cidr = netmask_to_cidr($default_netmask)

# Load methods

if File.directory?("./methods")
  file_list = Dir.entries("./methods")
  for file in file_list
    if file =~ /rb$/
      require "./methods/#{file}"
    end
  end
end

# Create required directories

check_dir_exists($work_dir)
[ $iso_base_dir, $repo_base_dir, $image_base_dir, $pkg_base_dir, $client_base_dir ].each do |dir_name|
  check_zfs_fs_exists(dir_name)
end

# Print script usage information

def print_usage()
  switches     = []
  long_switch  = ""
  short_switch = ""
  help_info    = ""
  puts ""
  puts "Usage: "+$script
  puts ""
  file_array  = IO.readlines $0
  option_list = file_array.grep(/\[ "--/)
  option_list.each do |line|
    if !line.match(/file_array/)
      help_info    = line.split(/# /)[1]
      switches     = line.split(/,/)
      long_switch  = switches[0].gsub(/\[/,"").gsub(/\s+/,"")
      short_switch = switches[1].gsub(/\s+/,"")
      if long_switch.gsub(/\s+/,"").length < 7
        puts long_switch+",\t\t\t"+short_switch+"\t"+help_info
      else
        if long_switch.gsub(/\s+/,"").length < 15
          puts long_switch+",\t\t"+short_switch+"\t"+help_info
        else
          puts long_switch+",\t"+short_switch+"\t"+help_info
        end
      end
    end
  end
  puts
  return
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
  puts name+" v. "+version+" "+packager
  exit
end

# Generate a client MAC address if not given one

def create_client_mac(client_mac)
  if !client_mac.match(/[0-9]/)
    client_mac = (1..6).map{"%0.2X"%rand(256)}.join(":")
    if $verbose_mode == 1
      puts "Information:\tGenerated MAC address "+client_mac
    end
  end
  return client_mac
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
  if $do_ssh_keys == 1
    check_ssh_keys()
  end
  if $verbose_mode == 1
    puts "Information:\tHome directory "+$home_dir
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
    puts "Information:\tSetting work directory to "+$work_dir
  end
  if !$tmp_dir.match(/[a-z,A-Z,0-9]/)
    $tmp_dir = $work_dir+"/tmp"
  end
  if $verbose_mode == 1
    puts "Information:\tSetting temporary directory to "+$work_dir
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
      puts "Information:\tSetting apache allow range to "+$default_apache_allow
    end
    if $os_name.match(/SunOS/)
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
  if $os_name.match(/Darwn/)
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
      message = "Fetching:\tTool rpm2cpio"
      command = "wget \"#{$rpm2cpio_url}\" -O #{$rpm2cpio_bin} ; chown #{$id} #{$rpm2cpio_bin} ; chmod +x #{$rpm2cpio_bin}"
      execute_command(message,command)
      system("chmod +x #{$rpm2cpio_bin}")
    end
  end
  return
end

# Print valid list

def print_valid_list(message,valid_list)
  puts
  puts message
  puts
  puts "Available options:"
  puts
  valid_list.each do |item|
    puts item
  end
  puts
  exit
end

# Get command line arguments
# Print help if given none

if !ARGV[0]
  print_usage()
end

# Try to make sure we have valid long switches

ARGV[0..-1].each do |switch|
  if switch.match(/^-[a-z,A-Z][a-z,A-Z]/)
    puts "Invalid command line option: "+switch
    exit
  end
end

# Process options

begin
  option = Getopt::Long.getopts(
    [ "--action",         "-a", Getopt::REQUIRED ], # Action (e.g. boot, stop, create, delete, list, etc)
    [ "--arch",           "-A", Getopt::REQUIRED ], # Architecture of client or VM (e.g. x86_64)
    [ "--domainname",     "-b", Getopt::REQUIRED ], # Set domain (Used with deploy for VCSA)
    [ "--memory",         "-B", Getopt::REQUIRED ], # VM memory size
    [ "--client",         "-c", Getopt::REQUIRED ], # Client name
    [ "--mode",           "-C", Getopt::REQUIRED ], # Set mode to client or server
    [ "--datastore",      "-d", Getopt::REQUIRED ], # Datastore to deploy to on remote server
    [ "--nameserver",     "-d", Getopt::REQUIRED ], # Delete client or VM
    [ "--server",         "-D", Getopt::REQUIRED ], # Server name/IP (allow execution of commands on a remote host, or deploy to)
    [ "--mac",            "-e", Getopt::REQUIRED ], # MAC Address
    [ "--vm",             "-E", Getopt::REQUIRED ], # VM type
    [ "--file",           "-f", Getopt::REQUIRED ], # File, eg ISO
    [ "--clone",          "-f", Getopt::REQUIRED ], # Clone name
    [ "--diskmode",       "-G", Getopt::REQUIRED ], # Disk mode (e.g. thin)
    [ "--help",           "-h", Getopt::BOOLEAN ],  # Display usage information
    [ "--ip",             "-i", Getopt::REQUIRED ], # IP Address of client
    [ "--ipfamily",       "-I", Getopt::REQUIRED ], # IP family (e.g. IPv4 or IPv6)
    [ "--size",           "-j", Getopt::REQUIRED ], # VM disk size (if used with deploy action, this sets the size of the VM, e.g. tiny)
    [ "--network",        "-k", Getopt::REQUIRED ], # Set network type (e.g. hostonly, bridget, nat)
    [ "--servernetwork",  "-K", Getopt::REQUIRED ], # Server network (used when deploying to a remote server)
    [ "--publisher",      "-l", Getopt::REQUIRED ], # Publisher host
    [ "--license",        "-L", Getopt::REQUIRED ], # License key (e.g. ESX)
    [ "--method",         "-m", Getopt::REQUIRED ], # Install method (e.g. Kickstart)
    [ "--mount",          "-M", Getopt::REQUIRED ], # Mount point
    [ "--service",        "-n", Getopt::REQUIRED ], # Service name
    [ "--timeserver",     "-N", Getopt::REQUIRED ], # Set NTP server IP / Address
    [ "--os",             "-o", Getopt::REQUIRED ], # OS type
    [ "--post",           "-p", Getopt::REQUIRED ], # Post install configuration
    [ "--publisher",      "-P", Getopt::REQUIRED ], # Set publisher information (Solaris AI)
    [ "--adminpassword",  "-q", Getopt::REQUIRED ], # Client admin password
    [ "--ssopassword",    "-q", Getopt::REQUIRED ], # SSO password
    [ "--serverpassword", "-Q", Getopt::REQUIRED ], # Admin password of server to deploy to
    [ "--release",        "-r", Getopt::REQUIRED ], # OS Release
    [ "--mirror",         "-R", Getopt::REQUIRED ], # Mirror / Repo
    [ "--repo",           "-R", Getopt::REQUIRED ], # Set repository
    [ "--copykeys",       "-s", Getopt::BOOLEAN ],  # Copy SSH Keys
    [ "--share",          "-S", Getopt::REQUIRED ], # Shared folder
    [ "--type",           "-t", Getopt::REQUIRED ], # Install type (e.g. ISO, client, OVA, Network)
    [ "--model",          "-T", Getopt::REQUIRED ], # Model
    [ "--admin",          "-u", Getopt::REQUIRED ], # Admin username for client VM to be created
    [ "--serveradmin",    "-U", Getopt::REQUIRED ], # Admin username for server to deploy to
    [ "--verbose",        "-v", Getopt::BOOLEAN ],  # Verbose mode
    [ "--version",        "-V", Getopt::BOOLEAN ],  # Display version information
    [ "--test",           "-w", Getopt::BOOLEAN ],  # Test mode
    [ "--rootpassword",   "-W", Getopt::REQUIRED ], # Client root password
    [ "--locale",         "-x", Getopt::REQUIRED ], # Select language/language (e.g. en_US)
    [ "--console",        "-X", Getopt::REQUIRED ], # Select console type (e.g. text, serial, x11) (default is text)
    [ "--yes",            "-y", Getopt::BOOLEAN ],  # Answer yes to all questions (accept defaults)
    [ "--enable",         "-Z", Getopt::REQUIRED ], # Mount point
    [ "--changelog",      "-1", Getopt::BOOLEAN ]   # Print changelog
  )
rescue
  print_usage()
  exit
end

def print_changelog()
  if File.exist?("changelog")
    changelog = File.readlines("changelog")
    changelog = changelog.reverse
    changelog.each_with_index do |line, index|
      line = line.gsub(/^# /,"")
      if line.match(/^[0-9]/)
        puts line
        puts changelog[index-1].gsub(/^# /,"")
        puts
      end
    end
  end
  return
end

# Print version

if option["version"]
  print_version()
  exit
end

# Print usage

if option["help"]
  print_usage()
  exit
end

# Print changelog

if option["changelog"]
  print_changelog
  exit
end

# Get install action

if option["action"]
  install_action = option["action"]
else
  install_action = ""
end

# Get Locale / Language

if option["locale"]
  install_local = option["locale"]
else
  install_local = $default_locale
end

# Handle vm switch

if option["vm"]
  option["vm"] = option["vm"].downcase
  option["vm"] = option["vm"].gsub(/virtualbox/,"vbox")
end

# Check action when set to build

if install_action.match(/build/)
  if !option["type"]
    puts "Information:\tSetting Install Service to Packer"
    option["type"] = "packer"
    install_type   = "packer"
  else
    if !option["type"].match(/packer/)
      puts "Warning:\tInstall type not set to Packer"
      exit
    end
  end
  if !option["vm"]
    puts "Warning:\tVM type not specified"
    exit
  else
    if !option["vm"].match(/vbox|fusion/)
      puts "Warning:\tInvalid VM type specified"
      exit
    end
  end
end

# Enable options, e.g. Puppet, needs work!

if option["enable"]
  $default_options = option["enable"]
end

# handle option type

if option["type"]
  install_type = option["type"]
else
  install_type   = ""
end

# Handle file

if option["file"]
  install_file = option["file"]
  if !File.exist?(install_file)
    puts "Warning:\tFile "+install_file+" does not exist"
    exit
  end
  if install_action.match(/deploy/)
    if !install_type.match(/[a-z]/)
      install_type   = get_install_type_from_file(install_file)
      option["type"] = install_type
    end
  end
else
  install_file = ""
end

# Get password

if option["rootpassword"]
  install_root_password = option["rootpassword"]
  if $verbose_mode == 1
    puts "Information:\tSetting password to: "+install_root_password
  end
else
  install_root_password = $default_root_password
end

if option["ssopassword"]
  option["adminpassword"] = option["ssopassword"]
end

if option["adminpassword"]
  install_admin_password = option["adminpassword"]
  if $verbose_mode == 1
    puts "Information:\tSetting password to: "+install_admin_password
  end
else
  install_admin_password = $default_admin_password
end

# Handle IP family switch

if option["ipfamily"]
  install_ipfamily = option["ipfamily"]
else
  install_ipfamily = $default_ipfamily
end

# Handle IP

if option["ip"]
  install_ip = option["ip"]
else
  install_ip = ""
end

# Get Netmask

if option["netmask"]
  install_netmask = option["netmask"]
else
  if install_type.match(/vcsa/)
    install_netmask = $default_cidr
  else
    install_netmask = $default_netmask
  end
end

# Get gateway

if option["gateway"]
  install_gateway = option["gateway"]
else
  install_gateway = $default_gateway_ip
end

# Handle server admin and password

if option["serveradmin"]
  install_server_admin = option["serveradmin"]
else
  install_server_admin = $default_server_admin
end

if option["serverpassword"]
  install_server_password = option["serverpassword"]
else
  install_server_password = $default_root_password
end

# Handle server

if option["server"]
  install_server = option["server"]
else
  install_server = ""
end

# Handle datastore

if option["datastore"]
  install_datastore = option["datastore"]
else
  install_datastore = $default_datastore
end

# Handle diskmode

if option["diskmode"]
  install_diskmode = option["diskmode"]
else
  install_diskmode = $default_diskmode
end

# Handle deploy

if install_action.match(/deploy/)
  if !install_type.match(/[a-z]/)
    install_type = "esx"
  end
  if install_type.match(/esx|vcsa/)
    if !install_server_password.match(/[a-z,A-Z,0-9]/)
      install_server_password = install_root_password
    end
    check_ovftool_exists()
    if install_type.match(/vcsa/)
      if !install_file.match(/[a-z,A-Z,0-9]/)
        puts "Warning:\tNo deployment image file specified"
        exit
      end
      check_password(install_root_password)
      check_password(install_admin_password)
    end
  end
end

# Handle network

if option["servernetwork"]
  install_server_network = option["servernetwork"]
else
  install_server_network = $default_server_network
end

# Handle DNS

if option["nameserver"]
  install_nameserver = option["nameserver"]
  check_install_ip(install_nameserver)
else
  install_nameserver = $default_nameserver
end

# Handle NTP

if option["timeserver"]
  install_timeserver = option["timeserver"]
else
  install_timeserver = $default_timeserver
end

# Handle domain

if option["domainname"]
  install_domainname = option["domainname"]
else
  install_domainname = $default_domainname
end

# Handle sitename

if option["sitename"]
  install_sitename = option["sitename"]
else
  if install_domainname.match(/\./)
    install_sitename = install_domainname.split(".")[0]
  else
    install_sitename = install_domainname
  end
end

# Handle list switch

if option["action"].match(/list/)
  if !option["vm"] and !option["service"] and !option["method"] and !option["type"] and !option["mode"]
    puts "Warning:\tNo type or service given"
    exit
  end
end

# Handle action switch

if option["action"]
  install_action = option["action"]
  if install_action.match(/migrate|deploy/)
    if install_action.match(/deploy/)
      if option["type"]
        install_type = option["type"]
        if install_type.match(/vcsa/)
          install_vm = "fusion"
        end
      else
        install_type   = get_install_type_from_file(install_file)
        option["type"] = install_type
        if install_type.match(/vcsa/)
          install_vm = "fusion"
        end
      end
    end
    if !option["vm"]
      puts "Information:\tVirtualisation method not specified, setting virtualisation method to VMware"
      option["vm"] = "fusion"
      install_vm   = option["vm"]
    end
    if !option["server"] or !option["ip"]
      puts "Warning:\tRemote server hostname or IP not specified"
      exit
    end
  end
else
  install_action = ""
end

# Try to determine install method when give just an ISO

if option["file"]
  install_file = option["file"]
  if install_file.match(/[a-z,A-Z,0-9]/) and install_action.match(/create|add/)
    if !option["method"]
      option["method"] = get_install_method_from_iso(install_file)
      install_method   = option["method"]
    end
  end
else
  install_file = ""
end

# Handle OS switch

if option["os"]
  install_os = option["os"].downcase
  install_os = install_os.gsub(/scientificlinux|scientific/,"sl")
  install_os = install_os.gsub(/oel/,"oraclelinux")
  install_os = install_os.gsub(/esx|esxi|vsphere/,"vmware")
  install_os = install_os.gsub(/^suse$/,"opensuse")
  install_os = install_os.gsub(/solaris/,"sol")
  install_os = install_os.gsub(/redhat/,"rhel")
  if !$valid_os_list.to_s.downcase.match(/#{install_os}/)
    print_valid_list("Warning:\tInvalid OS specified",$valid_os_list)
  end
else
  if install_type.match(/vcsa|packer/)
    (install_service,install_os,install_method,install_release,install_arch,install_label) = get_install_service_from_file(install_file)
    option["service"] = install_service
    option["os"]      = install_os
    option["method"]  = install_method
    option["release"] = install_release
    optiont["arch"]   = install_arch
    option["label"]   = install_label
  else
    install_os = ""
  end
end

# Get Timezone

if option["timezone"]
  install_timezone = option["timezone"]
else
  if option["os"]
    if option["os"].match(/win/)
      install_timezone = $default_windows_timezone
    else
      install_timezone = $default_timezone
    end
  end
end

# Handle install service switch

if option["service"]
  install_service = option["service"].downcase
  if $verbose_mode == 1
    puts "Information:\tSetting install service to: "+install_service
  end
  if install_type.match(/^packer$/)
    check_packer_is_installed()
    option["mode"]  = "client"
    install_mode    = "client"
    if !option["method"] and !option["os"] and !option["action"].match(/build|list|import|delete/)
      puts "Warning:\tNo OS, or Install Method specified for build type "+install_service
      exit
    end
    if !option["vm"] and !option["action"].match(/list/)
      puts "Warning:\tNo VM type specified for build type "+install_service
      exit
    end
    if !option["client"] and !option["action"].match(/list/)
      puts "Warning:\tNo Client name specified for build type "+install_service
      exit
    end
    if !option["file"] and !option["action"].match(/build|list|import|delete/)
      puts "Warning:\tNo ISO file specified for build type "+install_service
      exit
    end
    if !option["ip"] and !option["action"].match(/build|list|import|delete/)
      puts "Warning:\tNo IP Address given "
      exit
    end
    if !option["mac"] and !option["action"].match(/build|list|import|delete/)
      puts "Warning:\tNo MAC Address given"
      puts "Information:\tGenerating MAC Address"
      option["mac"] = generate_mac_address()
      install_mac   = option["mac"]
    end
  end
else
  if install_type.match(/vcsa|packer/)
    (install_service,install_os,install_method,install_release,install_arch,install_label) = get_install_service_from_file(install_file)
  else
    install_service = ""
  end
end

# Make sure a service (e.g. packer) or an install file (e.g. OVA) is specified for an import

if install_action.match(/import/)
  if !install_file.match(/[a-z,A-Z,0-9]/) and !install_service.match(/[a-z,A-Z,0-9]/)
    puts "Warning:\tNo install file or service specified"
    exit
  end
end

# Handle mirror switch

if option["mirror"]
  install_mirror = option["mirror"]
else
  install_mirror = ""
end

# Handle verbose switch

if option["verbose"]
  $verbose_mode = 1
  puts "Information:\tRuning in verbose mode"
else
  $verbose_mode = 0
end

# Handle test switch

if option["test"]
  $test_mode     = 1
  $download_mode = 0
  puts "Information:\tRuning in test mode"
else
  $download_mode = 1
  $test_mode     = 0
end

# Handle mount switch

if option["mount"]
  install_mount = option["mount"]
else
  install_mount = ""
end

# Handle license

if option["license"]
  install_license = option["license"]
else
  install_license = ""
end

# Handle share switch

if option["share"]
  install_share = option["share"]
  if !File.directory?(install_share)
    puts "Warning:\tShare point "+install_share+" doesn't exist"
    exit
  end
  if !install_mount.match(/[a-z,A-Z,0-9]/)
    install_mount = File.basename(install_share)
  end
  if $verbose_mode == 1
    puts "Information:\tSharing "+install_share
    puts "Information:\tSetting mount point to "+install_mount
  end
else
  install_share = ""
end


# Handle network switch

if option["network"]
  install_network = option["network"]
  if $verbose_mode == 1
    puts "Information:\tSetting network type to: "+install_network
  end
else
  install_network = $default_vm_network
end

# If given -y assume yes to all questions

if option["yes"]
  $yes_to_all   = 1
  $use_defaults = 1
  $destroy_fs   = "y"
  if $verbose_mode == 1
    puts "Information:\tAnswering yes to all questions (accepting defaults)"
    if $os_name =~ /SunOS/
      puts "Information:\tZFS filesystem for a service will be destroyed when a service is removed"
    end
  end
end

# Handle client name switch

if option["client"]
  install_client = option["client"]
  check_hostname(install_client)
  if $verbose_mode == 1
    puts "Setting:\tClient name to: "+install_client
  end
else
  install_client = ""
end

# Get IP address if given

if option["ip"]
  install_ip = option["ip"]
  check_install_ip(install_ip)
  if $verbose_mode == 1
     puts "Information:\tSetting client IP address is "+install_ip
  end
else
  install_ip = ""
end

# Handle install type switch

if option["type"]
  install_type = option["type"].downcase
  if !$valid_type_list.to_s.downcase.match(/#{install_type}/)
    print_valid_list("Warning:\tInvalid install type",$valid_type_list)
  end
else
  install_type = ""
end

# Handle release switch

if option["release"]
  install_release = option["release"]
  if option["vm"].match(/zone/) and $os_rel.match(/10/) and !install_release.match(/10/)
    puts "Warning:\tInvalid release number"
    exit
  end
  if !install_release.match(/[0-9]/) or install_release.match(/[a-z,A-Z,0-9]/)
    puts "Warning:\tInvalid release number"
    exit
  end
else
  if option["vm"]
    if option["vm"].match(/zone/)
      install_release = $os_rel
    end
  else
    install_release = ""
  end
end
if $verbose_mode == 1 and option["release"]
  puts "Information:\tSetting Operating System version to: "+install_release
end

# Get MAC address if given

if option["mac"]
  install_mac = option["mac"]
  install_mac = check_install_mac(install_mac)
  if $verbose_mode == 1
     puts "Information:\tSetting client MAC address to: "+install_mac
  end
else
  install_mac = ""
end

# Handle size switch

if option["size"]
  install_size = option["size"]
  if install_type.match(/vcsa/)
    if install_size.match(/[0-9]/)
      install_size = $default_vcsa_size
    end
  end
  if $verbose_mode == 1
    puts "Information:\tSetting disk size to: "+install_size
  end
else
  if install_type.match(/vcsa/)
    install_size = $default_vcsa_size
  else
    install_size = $default_vm_size
  end
end

# Handle empty OS option

if !option["os"]
  if option["vm"]
    if option["action"]
      if option["action"].match(/add|create/)
        if !option["method"]
          puts "Warning:\tNo OS or install method specified when creating VM"
          exit
        else
          option["os"] = ""
        end
      else
        option["os"] = ""
      end
    end
  else
    option["os"] = ""
  end
end

# Handle empty method option

if !option["method"]
  option["method"] = ""
end

# Handle memory switch

if option["memory"]
  install_memory = option["memory"]
else
  if option["vm"]
    if option["os"].match(/vs|esx|vmware|vsphere/) or option["method"].match(/vs|esx|vmware|vsphere/)
      install_memory = "4096"
    end
    if option["os"]
      if option["os"].match(/sol/) and option["release"] == "11"
        install_memory = "2048"
      end
    else
      if option["method"]
        if option["method"] == "ai"
          install_memory = "2048"
        end
      end
    end
    if !install_memory
      install_memory = $default_vm_mem
    end
  else
    install_memory = ""
  end
end

# Handle memory switch

if option["cpu"]
  install_cpu = option["cpu"]
else
  if option["vm"]
    install_cpu = $default_vm_vcpu
  else
    install_cpu = ""
  end
end

# Get/set publisher port (Used for configuring AI server)

if option["publisher"] and option["mode"].match(/server/) and $os_name.match(/SunOS/)
  publisher_host = option["publisher"]
  if publisher_host.match(/:/)
    (publisher_host,publisher_port) = publisher_host.split(/:/) 
  else
    publisher_port = $default_ai_port
  end
  puts "Information:\tSetting publisher host to: "+publisher_host
  puts "Information:\tSetting publisher port to: "+publisher_port
else
  if option["mode"] == "server" and $os_name == "SunOS"
    publisher_host = $default_host
    publisher_port = $default_ai_port
  else
    if !option["vm"]
      if option["action"].match(/create/)
        install_mode = "server"
        check_local_config(install_mode)
      end
    else
      install_mode = "client"
      check_local_config(install_mode)
    end
    publisher_host = $default_host
  end
end

# If service is set, but method and os isn't given, try to set method from service name

if option["service"] and !option["method"] and !option["os"]
  install_method = get_install_method_from_service(install_service)
  option["method"] = install_method
else
  if option["method"] and option["os"]
    if !option["method"].match(/[a-z,A-Z]/) and !option["os"].match(/[a-z,A-z]/)
      install_method = get_install_method_from_service(install_service)
      option["method"] = install_method
    end
  end
end

# Handle architecture switch

if option["arch"]
  install_arch = option["arch"].downcase
  if install_arch.match(/sun4u|sun4v/)
    install_arch = "sparc"
  end
  if install_os.match(/vmware/)
    install_arch = "x86_64"
  end
  if install_os.match(/bsd/)
    install_arch = "i386"
  end
  if !$valid_arch_list.to_s.downcase.match(/#{install_arch}/)
    print_valid_list("Warning:\tInvalid architecture specified",$valid_arch_list)
  end
  if $verbose_mode == 1
    puts "Information:\tSetting architecture to: "+install_arch
  end
else
  install_arch = ""
end

# Handle VM switch

if option["vm"]
  install_mode = "client"
  install_vm   = option["vm"].downcase
  if option["network"]
    $default_vm_network = option["network"]
  end
  if $verbose_mode == 1
    puts "Information:\tSetting VM network to: "+$default_vm_network
  end
  case install_vm
  when /parallels/
    check_local_config("client")
    install_status = check_parallels_is_installed()
    handle_vm_install_status(install_vm,install_status)
    install_vm   = "parallels"
    $use_sudo    = 0
    install_size = install_size.gsub(/G/,"000")
    $default_hostonly_ip = "192.168.2.254"
  when /virtualbox|vbox/
    check_local_config("client")
    install_status = check_vbox_is_installed()
    handle_vm_install_status(install_vm,install_status)
    install_vm   = "vbox"
    $use_sudo    = 0
    install_size = install_size.gsub(/G/,"000")
    $default_hostonly_ip = "192.168.3.254"
    $default_gateway_ip  = "192.168.3.254"
  when /vmware|fusion/
    check_local_config("client")
    install_status = check_fusion_is_installed()
    handle_vm_install_status(install_vm,install_status)
    check_promisc_mode()
    $use_sudo  = 0
    install_vm = "fusion"
    $default_hostonly_ip = "192.168.2.254"
    $default_gateway_ip  = "192.168.2.254"
    # Set vmrun bin
    set_vmrun_bin()
  when /zone|container|lxc/
    if $os_name.match(/SunOS/)
      install_vm = "zone"
    else
      install_vm = "lxc"
    end
  when /ldom|cdom|gdom/
    if $os_arch.downcase.match(/sparc/) and $os_name.match(/SunOS/)
      if $os_rel.match(/10|11/)
        if install_mode.match(/client/)
          install_vm = "gdom"
        end
        if install_mode.match(/server/)
          install_vm = "cdom"
        end
      else
        puts "Warning:\tLDoms require Solaris 10 or 11"
      end
    else
      puts "Warning:\tLDoms require Solaris on SPARC"
      exit
    end
  end
  if !$valid_vm_list.to_s.downcase.match(/#{install_vm}/)
    print_valid_list("Warning:\tInvalid VM type",$valid_vm_list)
  end
  if $verbose_mode == 1
    puts "Information:\tSetting VM type to "+install_vm
  end
else
  install_vm = ""
end

# Handle console switch

if option["console"]
  install_console = option["console"].downcase
  if !$valid_console_list.to_s.match(/#{install_console}/)
    print_valid_list("Warning:\tInvalid console type",$valid_console_list)
  end
  case install_console
  when /x11/
    $text_mode = 0
  when /serial/
    $serial_mode = 1
    $text_mode   = 1
  else
    $text_mode = 1
  end
else
  install_console = "text"
  $text_mode      = 0
end
if $verbose_mode == 1
  puts "Information:\tSetting console mode to: "+install_console
end

# Get/set system model

if option["vm"] or option["method"]
  if option["model"]
    install_model = option["model"].downcase
  else
    if install_arch.match(/i386|x86|x86_64|x64|amd64/)
      install_model = "vmware"
    else
      install_model = ""
    end
  end
  if $verbose_mode == 1 and option["method"]
    puts "Information:\tSetting model to: "+install_model
  end
end

# Get ISO file if given

if option["file"]
  install_file = option["file"]
  if install_vm == "vbox" and install_file == "tools"
    install_file = $vbox_additions_iso
  end
  if !File.exist?(install_file)
    puts "Warning:\tFile doesn't exist: "+install_file
    exit
  end
  if !install_type.match(/[a-z]/)
    install_type = get_install_type_from_file(install_file)
    if $verbose_mode == 1
      puts "Information:\tSetting install type to: "+install_type
    end
  end
else
  install_file = ""
end

# Handle repository switch

if option["repo"]
  install_repo = option["repo"]
  if install_repo == "alt"
    $use_alt_repo = 1
  end
else
  $use_alt_repo  = 0
end

# Check OS option

if option["os"]
  if option["os"].match(/^Linux|^linux/)
    if !install_file.match(/[a-z]/)
      print_valid_list("Warning:\tInvalid OS specified",$valid_linux_os_list)
    else
      (install_service,install_os) = get_packer_install_service(install_file)
    end
    exit
  else
    if install_file.match(/[a-z,A-Z,0-9]/)
      if install_file.match(/purity/)
        install_os = "purity"
      else
        (install_service,test_os) = get_packer_install_service(install_file)
        if !test_os.match(/#{install_os}/)
          puts "Warning:\tSpecified OS does not match installation media OS"
          puts "Information:\tSetting OS name to "+test_os
          install_os = test_os
        end
      end
    end
    case install_os
    when /vsphere|esx|vmware/
      option["method"] = "vs"
    when /kickstart|redhat|rhel|fedora|sl|scientific|ks|centos/
      option["method"] = "ks"
    when /ubuntu|debian/
      option["method"] = "ps"
    when /purity/
      option["method"] = "ps"
      if install_memory == $default_vm_mem
        install_memory = "8192"
      end
    when /suse|sles/
      option["method"] = "ay"
    when /sol/
      if option["release"].to_i < 11 
        option["method"] = "js"
      else
        option["method"] = "ai"
      end
    end
  end
end

# Handle install method switch

if option["method"]
  install_method = option["method"].downcase
  case install_method
    when /autoinstall|ai/
    info_examples  = "ai"
    install_method = "ai"
  when /kickstart|redhat|rhel|fedora|sl|scientific|ks|centos/
    info_examples  = "ks"
    install_method = "ks"
  when /jumpstart|js/
    info_examples  = "js"
    install_method = "js"
  when /preseed|debian|ubuntu|purity/
    info_examples  = "ps"
    install_method = "ps"
  when /vsphere|esx|vmware|vs/
    info_examples  = "vs"
    install_method = "vs"
    if install_memory == $default_vm_mem
      install_memory = "4096"
    end
    if install_cpu == $default_vm_vcpu
      install_cpu = "2"
    end
    $vbox_disk_type = "ide"
  when /bsd|xb/
    info_examples  = "xb"
    install_method = "xb"
  when /suse|sles|yast|ay/
    info_examples  = "ay"
    install_method = "ay"
  end
else
  install_method = ""
end

# Handle clone swith

if option["clone"]
  install_clone = option["clone"]
  if $verbose_mode == 1 and option["clone"]
    puts "Information:\tSetting clone name to: "+install_clone
  end
else
  if option["action"] == "snapshot"
    clone_date    = %x[date].chomp.downcase.gsub(/ |:/,"_")
    install_clone = install_client+"-"+clone_date
  else
    install_clone = ""
  end
  if $verbose_mode == 1 and option["clone"]
    puts "Information:\tSetting clone name to: "+install_clone
  end
end

# Handle install mode switch

if option["mode"]
  install_mode = option["mode"]
  if !$valid_mode_list.to_s.downcase.match(/#{install_mode}/)
    print_valid_list("Warning:\tInvalid mode specified",$valid_mode_list)
  end
  if $verbose_mode == 1
    puts "Information:\tSetting install mode to "+install_mode
  end
else
  install_mode = ""
end

# Try to determine install method if only given OS

if !option["method"] and !option["action"].match(/delete|running|reboot|restart|halt|boot|stop|deploy|migrate/)
  case install_os
  when /sol|sunos/
    if install_release.match(/[0-9]/)
      if install_release == "11"
        example_type   = "ai"
        install_method = "ai"
      else
        example_type   = "js"
        install_method = "js"
      end
    end
  when /ubuntu|debian/
    example_type   = "ps"
    install_method = "ps"
  when /suse|sles/
    example_type   = "ay"
    install_method = "ay"
  when /redhat|rhel|scientific|sl|centos|fedora|vsphere|esx/
    example_type   = "ks"
    install_method = "ks"
  when /bsd/
    example_type   = "xb"
    install_method = "xb"
  when /vmware|esx|vsphere/
    example_type   = "vs"
    install_method = "vs"
    configure_vmware_esxi_defaults()
  when "windows"
    example_type   = "pe"
    install_method = "pe"
  else
    if !option["action"].match(/list|info|check/)
      if !option["action"].match(/add|create/) and !option["vm"]
        print_valid_list("Warning:\tInvalid OS specified",$valid_os_list)
      end
    end
  end
end

# If given admin set admin user

if option["admin"]
  $default_admin_user = options["admin"]
  if $verbose_mode == 1
    puts "Information:\tSetting admin user to: "+$default_admin_user
  end
end

# Change VM disk size

if option["size"]
  $default_vm_size = option["size"]
  if !$default_vm_size.match(/G$/)
    $default_vm_size = $default_vm_size+"G"
  end
end

# If given -s copy SSH keys

if option["copykeys"]
  $do_ssh_keys = 1
else
  $do_ssh_keys = 0
end

# Handle action switch

if option["action"]
  install_action = option["action"].downcase
  case install_action
  when /display|view|show|prop/
    if install_client.match(/[a-z,A-Z]/)
      if install_vm.match(/[a-z]/)
        eval"[show_#{install_vm}_vm_config(install_client)]"
      else
        get_client_config(install_client,install_service,install_method,install_type)
      end
    else
      puts "Warning:\tClient name not specified"
    end
  when /help/
    print_usage()
  when /version/
    print_version()
  when /info|usage|help/
    print_examples(install_method,install_type,install_vm)
  when /list/
    if install_type.match(/packer/)
      list_packer_clients(install_vm)
      exit
    end
    if install_type.match(/service/)
      if install_method.match(/[a-z]/)
        eval"[list_#{install_method}_services]"
        puts
        exit
      else
        list_all_services()
      end
    end
    if install_type.match(/iso/)
      if install_method.match(/[a-z]/)
        eval"[list_#{install_method}_isos]"
      else
        list_os_isos(install_os)
      end
      exit
    end
    if install_mode.match(/client/)
      check_local_config(install_mode)
      list_clients(install_service)
      list_vms(install_vm,install_type)
      exit
    end
    if install_method.match(/[a-z]/) and !install_vm.match(/[a-z]/)
      eval"[list_#{install_method}_clients()]"
      exit
    end
    if install_type.match(/ova/)
      list_ovas()
      exit
    end
    if install_vm.match(/[a-z]/)
      if install_type.match(/snapshot/)
        list_vm_snapshots(install_vm,install_os,install_method,install_client)
      else
        list_vm(install_vm,install_os,install_method)
      end
      exit
    end
  when /delete|remove/
    if install_client.match(/[a-z]/) 
      if !install_service.match(/[a-z]/) and !install_vm.match(/[a-z]/)
        if !install_vm.match(/[a-z]/)
          install_vm = get_client_vm_type(install_client)
          if install_vm.match(/vbox|fusion|parallels/)
            $use_sudo = 0
            delete_vm(install_vm,install_client)
          else
            puts "Warning:\tNo VM, client or service specified"
            puts
            puts "Available services"
            list_all_services()
            exit
          end
        end
      else
        if install_vm.match(/fusion|vbox|parallels/)
          if install_type.match(/packer/)
            eval"[unconfigure_#{install_type}_client(install_client,install_vm)]"
          else
            if install_type.match(/snapshot/)
              if install_client.match(/[a-z]/) and install_clone.match(/[a-z,A-Z,0-9]|\*/)
                delete_vm_snapshot(install_vm,install_client,install_clone)
              else
                puts "Warning:\tClient name or clone not specified"
                exit
              end
            else
              delete_vm(install_vm,install_client)
            end
          end
        else
          set_local_config()
          remove_hosts_entry(install_client,install_ip)
          remove_dhcp_client(install_client)
          if option["yes"]
            delete_client_dir(install_client)
          end
        end
      end
    else
      if install_type.match(/packer/)
        eval"[unconfigure_#{install_type}_client(install_client)]"
      else
        if install_service.match(/[a-z,A-Z,0-9]/)
          if !install_method.match(/[a-z]/)
            unconfigure_server(install_service)
          else
            eval"[unconfigure_#{install_method}_server(install_service)]"
          end
        end
      end
    end
  when /build/
    if install_type.match(/packer/)
      build_packer_config(install_client,install_vm)
    end
  when /add|create/
    if install_mode.match(/server/) or install_file.match(/[a-z,A-Z,0-9]/) or install_type.match(/service/) and !install_vm.match(/[a-z]/) and !install_type.match(/packer/)
      check_local_config("server")
      eval"[configure_server(install_method,install_arch,publisher_host,publisher_port,install_service,install_file)]"
    else
      if install_vm.match(/fusion|vbox/)
        check_vm_network(install_vm,install_mode,install_network)
      end
      if install_client.match(/[a-z,0-9]/)
        if install_service.match(/[a-z,A-Z,0-9]/) or install_type.match(/packer/)
          if !install_type.match(/packer/)
            check_dhcpd_config(publisher_host)
          end
          if !install_method.match(/[a-z]/)
            install_method = get_install_method(install_client,install_service)
          end
          check_install_ip(install_ip)
          check_install_mac(install_mac)
          if install_type.match(/packer/)
            eval"[configure_#{install_type}_client(install_method,install_vm,install_os,install_client,install_arch,install_mac,
                              install_ip,install_model,publisher_host,install_service,install_file,install_memory,install_cpu,
                              install_network,install_license,install_mirror,install_size,install_type,install_locale,install_label,install_timezone)]"
          else
            check_local_config("server")
            eval"[configure_#{install_method}_client(install_client,install_arch,install_mac,install_ip,install_model,publisher_host,
                              install_service,install_file,install_memory,install_cpu,install_network,install_license,install_mirror,install_type)]"
          end
        else
          if install_vm.match(/fusion|vbox|parallels/)
            create_vm(install_method,install_vm,install_client,install_mac,install_os,install_arch,install_release,install_size,install_file,install_memory,install_cpu,install_network,install_share,install_mount,install_ip)
          end
          if install_vm.match(/zone|lxc|gdom/)
            eval"[configure_#{install_vm}(install_client,install_ip,install_mac,install_arch,install_os,install_rel,publisher_host,
                                          install_file,install_service)]"
          end
          if install_vm.match(/cdom/)
            configure_cdom(publisher_host)
          end
          if !install_vm.match(/[a-z]/)
            if install_ip.match(/[0-9]/)
              check_local_config("client")
              add_hosts_entry(install_client,install_ip)
            end
            if install_mac.match(/[0-9]|[a-f]|[A-F]/)
              install_service = ""
              add_dhcp_client(install_client,client_mac,install_ip,install_arch,install_service)
            end
          end
        end
      else
        puts "Warning:\tClient or service name not specified"
      end
    end
  when /^boot$|^stop$|^halt$|^suspend$|^resume$|^start$/
    install_mode   = "client"
    install_action = install_action.gsub(/start/,"boot")
    if install_vm.match(/parallels|vbox/)
      install_action = install_action.gsub(/start/,"boot")
      install_action = install_action.gsub(/halt/,"stop")
    end
    if install_client.match(/[a-z,0-9]/) and install_vm.match(/[a-z]/)
      if install_action.match(/boot/)
        eval"[#{install_action}_#{install_vm}_vm(install_client,install_type)]"
      else
        eval"[#{install_action}_#{install_vm}_vm(install_client)]"
      end
    else
      if install_client.match(/[a-z,0-9]/) and !install_vm.match(/[a-z]/)
        install_vm = get_client_vm_type(install_client)
        check_local_config(install_mode)
        if install_vm.match(/vbox|fusion|parallels/)
          $use_sudo = 0
        end
        if install_vm.match(/[a-z]/)
          if install_action.match(/boot/)
            eval"[#{install_action}_#{install_vm}_vm(install_client,install_type)]"
          else
            eval"[#{install_action}_#{install_vm}_vm(install_client)]"
          end
        else
          print_valid_list("Warning:\tInvalid VM type",$valid_vm_list)
        end
      else
        if !install_client.match(/[a-z]/)
          puts "Warning:\tClient name not specified"
        end
      end
    end
  when /restart|reboot/
    if install_service.match(/[a-z,A-Z,0-9]/)
      eval"[restart_#{install_service}()]"
    else
      if !install_vm.match(/[a-z]/) and install_client.match(/[a-z]/)
        install_vm = get_client_vm_type(install_client)
      end
      if install_vm.match(/[a-z]/)
        if install_client.match(/[a-z,0-9]/)
          eval"[stop_#{install_vm}_vm(install_client)]"
          eval"[boot_#{install_vm}_vm(install_client,install_type)]"
        else
          puts "Warning:\tClient name not specified"
        end
      else
        puts "Warning:\tInstall service or VM type not specified"
        exit
      end
    end
  when /import/
    if !install_file.match(/[a-z,A-Z,0-9]/)
      if install_type.match(/packer/)
        eval"[import_packer_#{install_vm}_vm(install_client,install_vm)]"
      end
    else
      if install_vm.match(/fusion|vbox/)
        set_ovftool_bin()
        eval"[import_#{install_vm}_ova(install_client,install_mac,install_ip,install_file)]"
      end
    end
  when /export/
    if install_vm(/fusion|vbox/)
      eval"[export_#{install_vm}_ova(install_client,install_file)]"
    end
  when /clone|copy/
    if install_clone.match(/[a-z,A-Z,0-9]/) and install_client.match(/[a-z,0-9]/)
      eval"[clone_#{install_vm}_vm(install_client,install_clone,install_mac,install_ip)]"
    else
      puts "Warning:\tClient name or clone name not specified"
    end
  when /running|stopped|suspended|paused/
    if install_vm.match(/[a-z]/)
      eval"[list_#{install_action}_#{install_vm}_vms]"
    end
  when /crypt/
    install_crypt = get_password_crypt(install_root_password)
    puts install_crypt
  when /serial|console/
    if !install_client.match(/[a-z,0-9]/)
      puts "Warning:\tClient name not specified"
    end
    connect_to_virtual_serial(install_client)
  when /post/
    eval"[execute_#{install_vm}_post(install_client)]"
  when /change|modify/
    if install_client.match(/[a-z,0-9]/)
      if install_memory.match(/[0-9]/)
        eval"[change_#{install_vm}_vm_mem(install_client,install_memory)]"
      end
      if install_mac.match(/[0-9]|[a-f]|[A-F]/)
        eval"[change_#{install_vm}_vm_mac(install_client,client_mac)]"
      end
    else
      puts "Warning:\tClient name not specified"
    end
  when /attach/
    if install_vm.match(/[a-z]/)
      eval"[attach_file_to_#{install_vm}_vm(install_client,install_file,install_type)]"
    end
  when /detach/
    if install_vm.match(/[a-z]/) and install_client.match(/[a-z,0-9]/)
      eval"[detach_file_from_#{install_vm}_vm(install_client,install_file,install_type)]"
    else
      puts "Warning:\tClient name or virtualisation platform not specified"
    end
  when /share/
    if install_vm.match(/[a-z]/)
      eval"[add_shared_folder_to_#{install_vm}_vm(install_client,install_share,install_mount)]"
    end
  when /^snapshot|clone/
    if install_vm.match(/[a-z]/)
      if install_client.match(/[a-z,0-9]/)
        eval"[snapshot_#{install_vm}_vm(install_client,install_clone)]"
      else
        puts "Warning:\tClient name not specified"
        exit
      end
    end
  when /migrate/
    eval"[migrate_#{install_vm}_vm(install_client,install_server,install_server_admin,install_server_password,install_server_network,install_datastore)]"
  when /deploy/
    if install_type.match(/vcsa/)
      set_ovftool_bin()
      install_file = handle_vcsa_ova(install_file,install_service)
      deploy_vcsa_vm(install_server,install_datastore,install_server_admin,install_server_password,install_server_network,install_client,
                     install_size,install_root_password,install_timeserver,install_admin_password,install_domainname,install_sitename,
                     install_ipfamily,install_mode,install_ip,install_netmask,install_gateway,install_nameserver,install_service,install_file)      
    else
      eval"[deploy_#{install_vm}_vm(install_server,install_datastore,install_server_admin,install_server_password,install_server_network,install_client,
                                    install_size,install_root_password,install_timeserver,install_admin_password,install_domainname,install_sitename,
                                    install_ipfamily,install_mode,install_ip,install_netmask,install_gateway,install_nameserver,install_service,install_file)]"
    end
  when /restore|revert/
    if install_vm.match(/[a-z]/)
      if install_client.match(/[a-z,0-9]/)
        eval"[restore_#{install_vm}_vm_snapshot(install_client,install_clone)]"
      else
        puts "Warning:\tClient name not specified"
        exit
      end
    end
  when /console|serial/
    if install_vm.match(/[a-z]/)
      if install_client.match(/[a-z,0-9]/)
        connect_to_virtual_serial(install_client,install_vm)
      else
        puts "Warning:\tClient name not specified"
        exit
      end
    end
  when /check/
    if install_mode.match(/server/)
      check_local_config(install_mode)
    end
    if install_mode.match(/osx/)
      check_osx_dnsmasq()
      check_osx_tftpd()
      check_osx_dhcpd()
      if $default_options.match(/puppet/)
        check_osx_puppet()
      end
    end
    if install_vm.match(/fusion|vbox/)
      check_vm_network(install_vm,install_mode,install_network)
    end
  end
  exit
end
