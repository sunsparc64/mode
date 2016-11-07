#!/usr/bin/env ruby

# Name:         mode (Multi OS Deployment Engine)
# Version:      4.0.0
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
require 'pathname'
require 'ipaddr'
require 'uri'
require 'socket'
require 'net/http'

def install_gem(load_name,install_name)
  puts "Information:\tInstalling #{install_name}"
  %x[gem install #{install_name}]
  Gem.clear_paths
  require "#{load_name}"
end

begin
  require 'getopt/long'
rescue LoadError
  install_gem("getopt","getopt")
end
begin
  require 'builder'
rescue LoadError
  install_gem("builder","builder")
end
begin
  require 'parseconfig'
rescue LoadError
  install_gem("parseconfig","parseconfig")
end
begin
  require 'unix_crypt'
rescue LoadError
  install_gem("unix_crypt","unix-crypt")
end
begin
  require 'netaddr'
rescue LoadError
  install_gem("netaddr","netaddr")
end
begin
  require 'json'
rescue LoadError
  install_gem("json","json")
end
begin
  require 'fileutils'
rescue LoadError
  install_gem("fileutils","fileutils")
end

begin
  require 'net/ssh'
  require 'nokogiri'
  require 'mechanize'
  require 'net/scp'
  require 'terminfo'
rescue LoadError
end

# Set output mode

$output_format = "text"

# Declare array for text output (used for webserver)

$output_text = []

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

# Get command line arguments
# Print help if given none

if !ARGV[0]
  print_usage()
end

# Try to make sure we have valid long switches

ARGV[0..-1].each do |switch|
  if switch.match(/^-[a-z,A-Z][a-z,A-Z]/)
    handle_output("Invalid command line option: #{switch}")
    exit
  end
end

# Process options

include Getopt

begin
  option = Long.getopts(
    [ "--action",         "-a", REQUIRED ], # Action (e.g. boot, stop, create, delete, list, etc)
    [ "--arch",           "-A", REQUIRED ], # Architecture of client or VM (e.g. x86_64)
    [ "--domainname",     "-b", REQUIRED ], # Set domain (Used with deploy for VCSA)
    [ "--memory",         "-B", REQUIRED ], # VM memory size
    [ "--client",         "-c", REQUIRED ], # Client name
    [ "--mode",           "-C", REQUIRED ], # Set mode to client or server
    [ "--datastore",      "-d", REQUIRED ], # Datastore to deploy to on remote server
    [ "--server",         "-D", REQUIRED ], # Server name/IP (allow execution of commands on a remote host, or deploy to)
    [ "--mac",            "-e", REQUIRED ], # MAC Address
    [ "--vm",             "-E", REQUIRED ], # VM type
    [ "--file",           "-f", REQUIRED ], # File, eg ISO
    [ "--clone",          "-F", REQUIRED ], # Clone name
    [ "--locale",         "-g", REQUIRED ], # Locale (e.g. en_US)
    [ "--diskmode",       "-G", REQUIRED ], # Disk mode (e.g. thin)
    [ "--help",           "-h", BOOLEAN ],  # Display usage information
    [ "--param",          "-H", REQUIRED ], # Set a parameter of a VM
    [ "--ip",             "-i", REQUIRED ], # IP Address of client
    [ "--ipfamily",       "-I", REQUIRED ], # IP family (e.g. IPv4 or IPv6)
    [ "--size",           "-j", REQUIRED ], # VM disk size (if used with deploy action, this sets the size of the VM, e.g. tiny)
    [ "--value",          "-J", REQUIRED ], # Set the value of a parameter
    [ "--network",        "-k", REQUIRED ], # Set network type (e.g. hostonly, bridged, nat)
    [ "--servernetwork",  "-K", REQUIRED ], # Server network (used when deploying to a remote server)
    [ "--publisher",      "-l", REQUIRED ], # Publisher host
    [ "--license",        "-L", REQUIRED ], # License key (e.g. ESX)
    [ "--method",         "-m", REQUIRED ], # Install method (e.g. Kickstart)
    [ "--mount",          "-M", REQUIRED ], # Mount point
    [ "--service",        "-n", REQUIRED ], # Service name
    [ "--timeserver",     "-N", REQUIRED ], # Set NTP server IP / Address
    [ "--os",             "-o", REQUIRED ], # OS type
    [ "--format",         "-O", REQUIRED ], # Output format
    [ "--post",           "-p", REQUIRED ], # Post install configuration
    [ "--publisher",      "-P", REQUIRED ], # Set publisher information (Solaris AI)
    [ "--adminpassword",  "-q", REQUIRED ], # Client admin password
    [ "--ssopassword",    "-q", REQUIRED ], # SSO password
    [ "--serverpassword", "-Q", REQUIRED ], # Admin password of server to deploy to
    [ "--release",        "-r", REQUIRED ], # OS Release
    [ "--mirror",         "-R", REQUIRED ], # Mirror / Repo
    [ "--copykeys",       "-s", BOOLEAN ],  # Copy SSH Keys
    [ "--share",          "-S", REQUIRED ], # Shared folder
    [ "--type",           "-t", REQUIRED ], # Install type (e.g. ISO, client, OVA, Network)
    [ "--model",          "-T", REQUIRED ], # Model
    [ "--admin",          "-u", REQUIRED ], # Admin username for client VM to be created
    [ "--serveradmin",    "-U", REQUIRED ], # Admin username for server to deploy to
    [ "--verbose",        "-v", BOOLEAN ],  # Verbose mode
    [ "--version",        "-V", BOOLEAN ],  # Display version information
    [ "--test",           "-w", BOOLEAN ],  # Test mode
    [ "--rootpassword",   "-W", REQUIRED ], # Client root password
    [ "--locale",         "-x", REQUIRED ], # Select language/language (e.g. en_US)
    [ "--console",        "-X", REQUIRED ], # Select console type (e.g. text, serial, x11) (default is text)
    [ "--yes",            "-y", BOOLEAN ],  # Answer yes to all questions (accept defaults)
    [ "--vncpassword",    "-Y", REQUIRED ], # VNC password
    [ "--shell",          "-z", REQUIRED ], # Install shell (used for packer, e.g. winrm, ssh)
    [ "--enable",         "-Z", REQUIRED ], # Mount point
    [ "--command",        "-1", REQUIRED ], # Set repository
    [ "--repo",           "-2", REQUIRED ], # Set repository
    [ "--nameserver",     "-3", REQUIRED ], # Delete client or VM
    [ "--changelog",      "-4", BOOLEAN ]   # Print changelog
  )
rescue
  print_usage()
  exit
end

# Set output format

if option["format"]
  $output_format = option["format"].downcase
else
  $output_format = $default_output_format
end

# Prime HTML

if $output_format.match(/html/)
  $output_text.push("<html>")
  $output_text.push("<head>")
  $output_text.push("<title>#{$script_name}</title>")
  $output_text.push("</head>")
  $output_text.push("<body>")
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

# load global variables

set_global_vars()

#  Set verbose mode

if option["verbose"]
  $verbose_mode = 1
else
  $verbose_mode = 0
end

# Handle command switch

if option["command"]
  install_command = option["command"]
else
  install_command = ""
end

# Handle client name switch

if option["client"]
  install_client = option["client"]
  check_hostname(install_client)
  if $verbose_mode == 1
    handle_output("Setting:\tClient name to #{install_client}")
  end
else
  install_client = ""
end

# If given admin set admin user

if option["admin"]
  $default_admin_user = options["admin"]
  if $verbose_mode == 1
    handle_output("Information:\tSetting admin user to #{$default_admin_user}")
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

# Handle action

if option["action"]
  install_action = option["action"]
else
  install_action   = ""
end

# Handle arch switch

if option["arch"]
  install_arch = option["arch"]
else
  install_arch   = ""
end

# Handle domainname switch

if option["domainname"]
  install_domainname = option["domainname"]
else
  install_domainname   = ""
end

# Handle service switch

if option["service"]
  install_service = option["service"]
else
  install_service = ""
end

# Handle release switch

if option["release"]
  install_release = option["release"]
else
  install_release = ""
end

# Get MAC address if given

if option["mac"]
  install_mac = option["mac"]
  if !option["vm"]
    install_vm = "none"
  end
  install_mac = check_install_mac(install_mac,install_vm)
  if $verbose_mode == 1
     handle_output("Information:\tSetting client MAC address to #{install_mac}")
  end
else
  install_mac = ""
end

# Handle OS switch

if option["os"]
  install_os = option["os"]
else
  install_os = ""
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
    handle_output("Information:\tSetting architecture to #{install_arch}")
  end
else
  install_arch = ""
end

# Handle install shell

if option["shell"]
  install_shell = option["shell"]
else
  if install_os.match(/win/)
    $default_install_shell = "winrm"
    install_shell          = $default_install_shell
  else
    $default_install_shell = "ssh"
    install_shell          = $default_install_shell
  end
end

# Handle network switch

if option["network"]
  install_network = option["network"]
  if $verbose_mode == 1
    handle_output("Information:\tSetting network type to #{install_network}")
  end
else
  install_network   = $default_vm_network
end

# Get Locale / Language

if option["locale"]
  install_locale = option["locale"]
else
  install_locale = $default_locale
end

# Handle vm switch

if option["vm"]
  install_vm = option["vm"].downcase
  install_vm = install_vm.gsub(/virtualbox/,"vbox")
else
  install_vm = ""
end

# Handle CPU switch

if option["cpu"]
  install_cpu = option["cpu"]
else
  if !install_vm.empty?
    install_cpu = $default_vm_vcpu
  else
    install_cpu = ""
  end
end

# Handle share switch

if option["share"]
  install_share = option["share"]
  if !File.directory?(install_share)
    handle_output("Warning:\tShare point #{install_share} doesn't exist")
    exit
  end
  if install_mount.empty?
    install_mount = File.basename(install_share)
  end
  if $verbose_mode == 1
    handle_output("Information:\tSharing #{install_share}")
    handle_output("Information:\tSetting mount point to #{install_mount}")
  end
else
  install_share = ""
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

# Handle mirror switch

if option["mirror"]
  install_mirror = option["mirror"]
else
  install_mirror = ""
end

# Handle verbose switch

if option["verbose"]
  $verbose_mode = 1
  handle_output("Information:\tRuning in verbose mode")
else
  $verbose_mode = 0
end

# Handle test switch

if option["test"]
  $test_mode     = 1
  $download_mode = 0
  handle_output("Information:\tRuning in test mode")
else
  $download_mode = 1
  $test_mode     = 0
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

# Handle clone swith

if option["clone"]
  install_clone = option["clone"]
  if $verbose_mode == 1
    handle_output("Information:\tSetting clone name to #{install_clone}")
  end
else
  if install_action == "snapshot"
    clone_date    = %x[date].chomp.downcase.gsub(/ |:/,"_")
    install_clone = install_client+"-"+clone_date
  else
    install_clone = ""
  end
  if $verbose_mode == 1 and install_clone
    handle_output("Information:\tSetting clone name to #{install_clone}")
  end
end

# Handle install mode switch

if option["mode"]
  install_mode = option["mode"]
  if !$valid_mode_list.to_s.downcase.match(/#{install_mode}/)
    print_valid_list("Warning:\tInvalid mode specified",$valid_mode_list)
  end
  if $verbose_mode == 1
    handle_output("Information:\tSetting install mode to #{install_mode}")
  end
else
  install_mode = ""
end

# Handle method switch

if option["method"]
  install_method = option["method"]
else
  install_method = ""
end

# Handle client switch

if option["client"]
  install_client = option["client"]
else
  install_client = ""
end

# Handle install type switch

if option["type"]
  install_type = option["type"].downcase
  if !$valid_type_list.to_s.downcase.match(/#{install_type}/)
    print_valid_list("Warning:\tInvalid install type",$valid_type_list)
  end
else
  install_type   = ""
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
    handle_output("Information:\tSetting disk size to #{install_size}")
  end
else
  if install_type.match(/vcsa/)
    install_size = $default_vcsa_size
  else
    install_size = $default_vm_size
  end
end

# Try to determine install method when give just an ISO

if option["file"]
  install_file = option["file"]
  if install_vm == "vbox" and install_file == "tools"
    install_file = $vbox_additions_iso
  end
  if !File.exist?(install_file)
    handle_output("Warning:\tFile doesn't exist: #{install_file}")
    exit
  end
  if !install_file.empty? and install_action.match(/create|add/)
    if install_method.empty?
      install_method = get_install_method_from_iso(install_file)
    end
    if install_type.empty?
      install_type = get_install_type_from_file(install_file)
      if $verbose_mode == 1
        handle_output("Information:\tSetting install type to #{install_type}")
      end
    end
  end
else
  install_file = ""
end

# Handle values and parameters

if option["param"]
  if !install_action.match(/get/)
    if !option["value"]
      handle_output("Warning:\tSetting a parameter requires a value")
      exit
    else
      if !option["value"]
        handle_output("Warning:\tSetting a parameter requires a value")
        exit
      else
        install_param = option["param"]
      end
    end
  else
    install_param = option["param"]
  end
else
  install_param   = ""
end

if option["value"]
  if install_param.empty?
    handle_output("Warning:\tSetting a value requires a parameter")
    exit
  else
    install_value = option["value"]
  end
else
  install_value   = option["value"]
end

# Make sure we haven't got a nil methog

if install_method.nil?
  install_method = ""
end

# Handle LDoms

if !install_method.empty?
  if install_method.match(/dom/)
    if install_method.match(/cdom/)
      install_mode = "server"
      install_vm   = "cdom"
      if $verbose_mode == 1
        handle_output("Information:\tSetting mode to server")
        handle_output("Information:\tSetting vm to cdrom")
      end
    else
      if install_method.match(/gdom/)
        install_mode = "client"
        install_vm   = "gdom"
        if $verbose_mode == 1
          handle_output("Information:\tSetting mode to client")
          handle_output("Information:\tSetting vm to gdom")
        end
      else
        if install_method.match(/ldom/)
          if !install_client.empty?
            install_method = "gdom"
            install_vm     = "gdom"
            install_mode   = "client"
            if $verbose_mode == 1
              handle_output("Information:\tSetting mode to client")
              handle_output("Information:\tSetting method to gdom")
              handle_output("Information:\tSetting vm to gdom")
            end
          else
            handle_output("Warning:\tCould not determine whether to run in server of client mode")
            exit
          end
        end
      end
    end
  else
    if install_mode.match(/client/)
      if !install_vm.empty?
        if install_method.match(/ldom|gdom/)
          install_vm = "gdom"
        end
      end
    else
      if install_mode.match(/server/)
        if !install_vm.empty?
          if install_method.match(/ldom|cdom/)
            install_vm = "cdom"
          end
        end
      end
    end
  end
else
  install_method   = ""
  if !install_mode.empty?
    if install_vm.match(/ldom/)
      if install_mode.match(/client/)
        install_vm     = "gdom"
        install_method = "gdom"
        if $verbose_mode == 1
          handle_output("Information:\tSetting method to gdom")
          handle_output("Information:\tSetting vm to gdom")
        end
      end
      if install_mode.match(/server/)
        install_vm     = "cdom"
        install_method = "cdom"
        if $verbose_mode == 1
          handle_output("Information:\tSetting method to cdom")
          handle_output("Information:\tSetting vm to cdom")
        end
      end
    end
  end
end

# Handle Packer and VirtualBox not supporting hostonly or bridged network

if !install_network.match(/nat/)
  if install_vm.match(/virtualbox|vbox/)
    if install_type.match(/packer/) or install_method.match(/packer/)
      handle_output("Warning:\tVirtualBox does not support Hostonly or Bridged network with Packer")
    end
  end
end

# handle option type

if option["type"]
  install_type = option["type"]
else
  install_type   = ""
end

# Check action when set to build

if install_action.match(/build/)
  if install_type.empty? or install_type.nil?
    handle_output("Information:\tSetting Install Service to Packer")
    install_type = "packer"
  end
  if install_vm.empty?
    if install_client.empty?
      handle_output("Warning:\tNo client name given")
      exit
    end
    install_vm = get_client_vm_type_from_packer(install_client)
  end
  if install_vm.empty?
    handle_output("Warning:\tVM type not specified")
    exit
  else
    if !install_vm.match(/vbox|fusion/)
      handle_output("Warning:\tInvalid VM type specified")
      exit
    end
  end
end

# Enable options, e.g. Puppet, needs work!

if option["enable"]
  $default_options = option["enable"]
end

# Handle file

if option["file"]
  install_file = option["file"]
  if !File.exist?(install_file)
    handle_output("Warning:\tFile "+install_file+" does not exist")
    exit
  end
  if install_action.match(/deploy/)
    if install_type.empty?
      install_type = get_install_type_from_file(install_file)
    end
  end
else
  install_file = ""
end

# Get password

if option["rootpassword"]
  install_root_password = option["rootpassword"]
  if $verbose_mode == 1
    handle_output("Information:\tSetting password to #{install_root_password}")
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
    handle_output("Information:\tSetting password to #{install_admin_password}")
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

# If given -y assume yes to all questions

if option["yes"]
  $yes_to_all   = 1
  $use_defaults = 1
  $destroy_fs   = "y"
  if $verbose_mode == 1
    handle_output("Information:\tAnswering yes to all questions (accepting defaults)")
    if $os_name =~ /SunOS/
      handle_output("Information:\tZFS filesystem for a service will be destroyed when a service is removed")
    end
  end
end

# Get IP address if given

if option["ip"]
  install_ip = option["ip"]
  check_install_ip(install_ip)
  if $verbose_mode == 1
     handle_output("Information:\tSetting client IP address is #{install_ip}")
  end
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
  if install_type.empty?
    install_type = "esx"
  end
  if install_type.match(/esx|vcsa/)
    if install_server_password.empty?
      install_server_password = install_root_password
    end
    check_ovftool_exists()
    if install_type.match(/vcsa/)
      if install_file.empty?
        handle_output("Warning:\tNo deployment image file specified")
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
  handle_output("Information:\tSetting console mode to #{install_console}")
end

# Handle list switch

if install_action.match(/list/)
  if install_vm.empty? and install_service.empty? and install_method.empty? and install_type.empty? and install_mode.empty?
    handle_output("Warning:\tNo type or service given")
    exit
  end
end

# Handle action switch

if !install_action.empty?
  if install_action.match(/delete/) and install_service.empty?
    if install_vm.empty? and !install_type.empty?
      install_vm = get_client_vm_type_from_packer(install_client)
    else
      if !install_type.empty? and install_vm.empty?
        if install_type.match(/packer/)
          if !install_client.empty?
            install_vm = get_client_vm_type_from_packer(install_client)
          end
        end
      end
    end
  end
  if install_action.match(/migrate|deploy/)
    if install_action.match(/deploy/)
      if install_type.match(/vcsa/)
        install_vm = "fusion"
      else
        install_type   = get_install_type_from_file(install_file)
        if install_type.match(/vcsa/)
          install_vm = "fusion"
        end
      end
    end
    if install_vm.empty?
      handle_output("Information:\tVirtualisation method not specified, setting virtualisation method to VMware")
      install_vm = "vm"
    end
    if install_server.empty? or install_ip.empty?
      handle_output("Warning:\tRemote server hostname or IP not specified")
      exit
    end
  end
else
  install_action = ""
end

# Handle OS switch

if !install_os.empty?
  install_os = install_os.downcase
  install_os = install_os.gsub(/windows/,"win")
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
    if install_service.empty? or install_os.empty? or install_method.empty? or install_release.empty? or install_arch.empty? or install_label.empty?
      (install_service,install_os,install_method,install_release,install_arch,install_label) = get_install_service_from_file(install_file)
    end
  else
    install_os = ""
  end
end

# Handle install service switch

if !install_service.empty?
  if $verbose_mode == 1
    handle_output("Information:\tSetting install service to #{install_service}")
  end
  if install_type.match(/^packer$/)
    check_packer_is_installed()
    install_mode    = "client"
    if install_method.empty? and install_os.empty? and !install_action.match(/build|list|import|delete/)
      handle_output("Warning:\tNo OS, or Install Method specified for build type #{install_service}")
      exit
    end
    if install_vm.empty? and !install_action.match(/list/)
      handle_output("Warning:\tNo VM type specified for build type #{install_service}")
      exit
    end
    if install_client.empty? and !install_action.match(/list/)
      handle_output("Warning:\tNo Client name specified for build type #{install_service}")
      exit
    end
    if install_file.empty? and !install_action.match(/build|list|import|delete/)
      handle_output("Warning:\tNo ISO file specified for build type #{install_service}")
      exit
    end
    if !install_ip.match(/[0-9]/) and !install_action.match(/build|list|import|delete/)
      handle_output("Warning:\tNo IP Address given ")
      exit
    end
    if !install_mac.match(/[0-9]|[A-F]|[a-f]/) and !install_action.match(/build|list|import|delete/)
      handle_output("Warning:\tNo MAC Address given")
      handle_output("Information:\tGenerating MAC Address")
      if !install_vm.empty?
        if !install_vm.empty?
          install_mac = generate_mac_address(install_vm)
        else
          install_mac = generate_mac_address(install_client)
        end
      else
        install_mac = generate_mac_address(install_method)
      end
    end
  end
else
  if install_type.match(/vcsa|packer/)
    if install_service.empty? or install_os.empty? or install_method.empty? or install_release.empty? or install_arch.empty? or install_file.empty?
      (install_service,install_os,install_method,install_release,install_arch,install_label) = get_install_service_from_file(install_file)
    end
    if install_type.match(/^packer$/)
      check_packer_is_installed()
      install_mode    = "client"
      if install_method.empty? and install_os.empty? and !install_action.match(/build|list|import|delete/)
        handle_output("Warning:\tNo OS, or Install Method specified for build type #{install_service}")
        exit
      end
      if install_vm.empty? and !install_action.match(/list/)
        handle_output("Warning:\tNo VM type specified for build type #{install_service}")
        exit
      end
      if install_client.empty? and !install_action.match(/list/)
        handle_output("Warning:\tNo Client name specified for build type #{install_service}")
        exit
      end
      if install_file.empty? and !install_action.match(/build|list|import|delete/)
        handle_output("Warning:\tNo ISO file specified for build type #{install_service}")
        exit
      end
      if !install_ip.match(/[0-9]/) and !install_action.match(/build|list|import|delete/)
        handle_output("Warning:\tNo IP Address given")
        exit
      end
      if !install_mac.match(/[0-9]|[A-F]|[a-f]/) and !install_action.match(/build|list|import|delete/)
        handle_output("Warning:\tNo MAC Address given")
        handle_output("Information:\tGenerating MAC Address")
        if install_vm.empty?
          install_vm = "none"
        end
        install_mac = generate_mac_address(install_vm)
      end
    end
  else
    install_service = ""
  end
end

# Make sure a service (e.g. packer) or an install file (e.g. OVA) is specified for an import

if install_action.match(/import/)
  if install_file.empty? and install_service.empty? and !install_type.match(/packer/)
    install_client = option["client"]
    vm_types       = [ "fusion", "vbox" ]
    exists         = []
    vm_exists      = ""
    vm_type        = ""
    vm_types.each do |vm_type|
      exists = check_packer_vm_image_exists(install_client,vm_type)
      if exists[0].match(/yes/)
        install_type   = "packer"
        install_vm     = vm_type
        vm_exists      = "yes"
      end
    end
    if !vm_exists.match(/yes/)
      handle_output("Warning:\tNo install file, type or service specified")
      exit
    end
  end
end

# Handle release switch

if install_release.match(/[0-9]/)
  if install_type.match(/packer/) and install_action.match(/build|delete|import/)
    install_release = ""
  else
    if install_vm.empty?
      install_vm = "none"
    end
    if install_vm.match(/zone/) and $os_rel.match(/10|11/) and !install_release.match(/10|11/)
      handle_output("Warning:\tInvalid release number: #{install_release}")
      exit
    end
#    if !install_release.match(/[0-9]/) or install_release.match(/[a-z,A-Z]/)
#      puts "Warning:\tInvalid release number: "+install_release
#      exit
#    end
  end
else
  if install_vm.match(/zone/)
    install_release = $os_rel
  else
    install_release = ""
  end
end
if $verbose_mode == 1 and option["release"]
  handle_output("Information:\tSetting Operating System version to #{install_release}")
end

# Handle empty OS option

if install_os.empty?
  if !install_vm.empty?
    if install_action.match(/add|create/)
      if install_method.empty?
        if !install_vm.match(/ldom|cdom|gdom/)
          handle_output("Warning:\tNo OS or install method specified when creating VM")
          exit
        end
      end
    end
  end
end

# Handle memory switch

if option["memory"]
  install_memory = option["memory"]
else
  install_memory = ""
  if !install_vm.empty?
    if install_os.match(/vs|esx|vmware|vsphere/) or install_method.match(/vs|esx|vmware|vsphere/)
      install_memory = "4096"
    end
    if !install_os.empty?
      if install_os.match(/sol/)
        if install_release.to_i > 9
          install_memory = "2048"
        end
      end
    else
      if install_method == "ai"
        install_memory = "2048"
      end
    end
    if install_memory.empty?
      install_memory = $default_vm_mem
    end
  else
    install_memory = $default_vm_mem
  end
end

# Get/set publisher port (Used for configuring AI server)

if option["publisher"] and install_mode.match(/server/) and $os_name.match(/SunOS/)
  publisher_host = option["publisher"]
  if publisher_host.match(/:/)
    (publisher_host,publisher_port) = publisher_host.split(/:/)
  else
    publisher_port = $default_ai_port
  end
  handle_output("Information:\tSetting publisher host to #{publisher_host}")
  handle_output("Information:\tSetting publisher port to #{publisher_port}")
else
  if install_mode == "server" or install_file.match(/repo/)
    if $os_name == "SunOS"
      check_local_config("server")
      publisher_host = $default_host
      publisher_port = $default_ai_port
      if $verbose_mode == 1
        handle_output("Information:\tSetting publisher host to #{publisher_host}")
        handle_output("Information:\tSetting publisher port to #{publisher_port}")
      end
    end
  else
    if install_vm.empty?
      if install_action.match(/create/)
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

if !install_service.empty? and install_method.empty? and install_os.empty?
  install_method = get_install_method_from_service(install_service)
else
  if install_method.empty? and install_os.empty?
    install_method = get_install_method_from_service(install_service)
  end
end

# Handle VM switch

if !install_vm.empty?
  install_mode = "client"
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
      if install.release.empty?
        install_release   = $os_rel
      end
      if $os_rel.match(/10|11/)
        if install_mode.match(/client/)
          install_vm = "gdom"
        end
        if install_mode.match(/server/)
          install_vm = "cdom"
        end
      else
        handle_output("Warning:\tLDoms require Solaris 10 or 11")
      end
    else
      handle_output("Warning:\tLDoms require Solaris on SPARC")
      exit
    end
  end
  if !$valid_vm_list.to_s.downcase.match(/#{install_vm}/) and !install_action.match(/list/)
    print_valid_list("Warning:\tInvalid VM type",$valid_vm_list)
  end
  if $verbose_mode == 1
    handle_output("Information:\tSetting VM type to #{install_vm}")
  end
else
  install_vm = "none"
end

# Get/set system model

if option["model"]
  install_model = option["model"]
else
  install_model = ""
end

if !install_vm.empty? or !install_method.empty?
  if !install_model.empty?
    install_model = option["model"].downcase
  else
    if install_arch.match(/i386|x86|x86_64|x64|amd64/)
      install_model = "vmware"
    else
      install_model = ""
    end
  end
  if $verbose_mode == 1 and install_model
    handle_output("Information:\tSetting model to #{install_model}")
  end
end

# Check OS option

if !install_os.empty?
  if install_os.match(/^Linux|^linux/)
    if install_file.empty?
      print_valid_list("Warning:\tInvalid OS specified",$valid_linux_os_list)
    else
      (install_service,install_os) = get_packer_install_service(install_file)
    end
    exit
  else
    if !install_file.empty?
      if install_file.match(/purity/)
        install_os = "purity"
      else
        (install_service,test_os) = get_packer_install_service(install_file)
        if !test_os.match(/#{install_os}/)
          handle_output("Warning:\tSpecified OS does not match installation media OS")
          handle_output("Information:\tSetting OS name to #{test_os}")
          install_os = test_os
        end
      end
    end
    case install_os
    when /vsphere|esx|vmware/
      install_method = "vs"
    when /kickstart|redhat|rhel|fedora|sl|scientific|ks|centos/
      install_method = "ks"
    when /ubuntu|debian/
      install_method = "ps"
    when /purity/
      install_method = "ps"
      if install_memory.match(/#{$default_vm_mem}/)
        $default_vm_mem  = "8192"
        install_memory   = $default_vm_mem
        $default_vm_vcpu = "2"
        install_cpu      = $default_vm_vcpu
      end
    when /suse|sles/
      install_method = "ay"
    when /sol/
      if install_release.to_i < 11
        install_method = "js"
      else
        install_method = "ai"
      end
    end
  end
end

# Handle install method switch

if install_method.nil?
  install_method = ""
end

if !install_method.empty?
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

# Try to determine install method if only given OS

if install_method.empty? and !install_action.match(/delete|running|reboot|restart|halt|boot|stop|deploy|migrate|show/)
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
    if !install_action.match(/list|info|check/)
      if !install_action.match(/add|create/) and install_vm.empty?
        print_valid_list("Warning:\tInvalid OS specified",$valid_os_list)
      end
    end
  end
end

# Handle action switch

if !install_action.empty?
  case install_action
  when /execute/
    if install_type.match(/docker/)
      execute_docker_command(install_client,install_command)
    end
  when /screen/
    if !install_vm.empty?
      eval"[get_#{install_vm}_vm_screen(install_client)]"
    end
  when /vnc/
    if !install_vm.empty?
      eval"[vnc_#{install_vm}_vm(install_client,install_ip)]"
    end
  when /status/
    if !install_vm.empty?
      eval"[get_#{install_vm}_vm_status(install_client)]"
    end
  when /display|view|show|prop/
    if !install_client.empty?
      if !install_vm.empty? and !install_vm.match(/none/)
        eval"[show_#{install_vm}_vm_config(install_client)]"
      else
        get_client_config(install_client,install_service,install_method,install_type,install_vm)
      end
    else
      handle_output("Warning:\tClient name not specified")
    end
  when /help/
    print_usage()
  when /version/
    print_version()
  when /info|usage|help/
    print_examples(install_method,install_type,install_vm)
  when /show/
    if !install_vm.empty? and !install_vm.match(/none/)
      eval"[show_#{install_vm}_vm(install_client)]"
    end
  when /list/
    if install_type.match(/packer|docker/)
      eval"[list_#{install_type}_clients]"
      quit()
    end
    if install_type.match(/service/) or install_mode.match(/server/)
      if !install_method.empty?
        eval"[list_#{install_method}_services]"
        handle_output("")
      else
        list_all_services()
      end
      quit()
    end
    if install_type.match(/iso/)
      if !install_method.empty?
        eval"[list_#{install_method}_isos]"
      else
        list_os_isos(install_os)
      end
      quit()
    end
    if install_mode.match(/client/) or install_type.match(/client/)
      install_mode = "client"
      check_local_config(install_mode)
      list_clients(install_service)
      list_vms(install_vm,install_type)
      quit()
    end
    if !install_method.empty? and install_vm.match(/none/)
      eval"[list_#{install_method}_clients()]"
      qui()
    end
    if install_type.match(/ova/)
      list_ovas()
      quit()
    end
    if !install_vm.empty? and !install_vm.match(/none/)
      if install_type.match(/snapshot/)
        list_vm_snapshots(install_vm,install_os,install_method,install_client)
      else
        list_vm(install_vm,install_os,install_method)
      end
      quit()
    end
  when /delete|remove/
    if !install_client.empty?
      if install_type.match(/docker/)
        unconfigure_docker_client(install_client)
        quit()
      end
      if install_service.empty? and install_vm.match(/none/)
        if install_vm.match(/none/)
          install_vm = get_client_vm_type(install_client)
          if install_vm.match(/vbox|fusion|parallels/)
            $use_sudo = 0
            delete_vm(install_vm,install_client)
          else
            handle_output("Warning:\tNo VM, client or service specified")
            handle_output("")
            handle_output("Available services")
            list_all_services()
          end
        end
      else
        if install_vm.match(/fusion|vbox|parallels/)
          if install_type.match(/packer/)
            eval"[unconfigure_#{install_type}_client(install_client,install_vm)]"
          else
            if install_type.match(/snapshot/)
              if !install_client.empty? and install_clone.match(/[a-z,A-Z,0-9]|\*/)
                delete_vm_snapshot(install_vm,install_client,install_clone)
              else
                handle_output("Warning:\tClient name or clone not specified")
              end
            else
              delete_vm(install_vm,install_client)
            end
          end
        else
          if install_vm.match(/ldom|gdom/)
            unconfigure_gdom(install_client)
          else
            set_local_config()
            remove_hosts_entry(install_client,install_ip)
            remove_dhcp_client(install_client)
            if option["yes"]
              delete_client_dir(install_client)
            end
          end
        end
      end
    else
      if install_type.match(/packer|docker/)
        eval"[unconfigure_#{install_type}_client(install_client)]"
      else
        if !install_service.empty?
          if install_method.empty?
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
    if install_type.match(/docker/)
      configure_docker_client(install_vm,install_client,install_ip,install_network)
      quit()
    end
    if install_vm.match(/none/) and install_method.empty? and install_type.empty? and !install_mode.match(/server/)
      handle_output("Warning:\tNo VM, Method or given")
    end
    if install_mode.match(/server/) or !install_file.empty? or install_type.match(/service/) and install_vm.match(/none/) and !install_type.match(/packer/) and !install_service.match(/packer/)
      check_local_config("server")
      eval"[configure_server(install_method,install_arch,publisher_host,publisher_port,install_service,install_file)]"
    else
      if install_vm.match(/fusion|vbox/)
        check_vm_network(install_vm,install_mode,install_network)
      end
      if !install_client.empty?
        if !install_service.empty? or install_type.match(/packer/)
          if install_method.empty?
            install_method = get_install_method(install_client,install_service)
          end
          if !install_type.match(/packer/) and install_vm.match(/none/)
            check_dhcpd_config(publisher_host)
          end
          if !install_network.match(/nat/)
            check_install_ip(install_ip)
            check_install_mac(install_mac,install_vm)
          end
          if install_type.match(/packer/)
            if $yes_to_all == 1
              if install_vm.match(/none/)
                install_vm = get_client_vm_type(install_client)
                if install_vm.match(/vbox|fusion|parallels/)
                  $use_sudo = 0
                  delete_vm(install_vm,install_client)
                  eval"[unconfigure_#{install_type}_client(install_client,install_vm)]"
                end
              else
                $use_sudo = 0
                delete_vm(install_vm,install_client)
                eval"[unconfigure_#{install_type}_client(install_client,install_vm)]"
              end
            end
            eval"[configure_#{install_type}_client(install_method,install_vm,install_os,install_client,install_arch,install_mac,install_ip,install_model,
                              publisher_host,install_service,install_file,install_memory,install_cpu,install_network,install_license,install_mirror,
                              install_size,install_type,install_locale,install_label,install_timezone,install_shell)]"
          else
            if install_vm.match(/none/)
              if install_method.empty?
                if install_ip.match(/[0-9]/)
                  check_local_config("client")
                  add_hosts_entry(install_client,install_ip)
                end
                if install_mac.match(/[0-9]|[a-f]|[A-F]/)
                  install_service = ""
                  add_dhcp_client(install_client,install_mac,install_ip,install_arch,install_service)
                end
              else
                if install_model.empty?
                  install_model       = "vmware"
                  $default_slice_size = "4192"
                end
                check_local_config("server")
                if !install_mac.match(/[0-9]/)
                  install_mac = generate_mac_address(install_vm)
                end
                eval"[configure_#{install_method}_client(install_client,install_arch,install_mac,install_ip,install_model,publisher_host,
                                  install_service,install_file,install_memory,install_cpu,install_network,install_license,install_mirror,install_type,install_vm)]"
              end
            else
              if install_vm.match(/fusion|vbox|parallels/)
                create_vm(install_method,install_vm,install_client,install_mac,install_os,install_arch,install_release,install_size,install_file,install_memory,install_cpu,install_network,install_share,install_mount,install_ip)
              end
              if install_vm.match(/zone|lxc|gdom/)
                eval"[configure_#{install_vm}(install_client,install_ip,install_mac,install_arch,install_os,install_release,publisher_host,
                                              install_file,install_service)]"
              end
              if install_vm.match(/cdom/)
                configure_cdom(publisher_host)
              end
            end
          end
        else
          if install_vm.match(/fusion|vbox|parallels/)
            create_vm(install_method,install_vm,install_client,install_mac,install_os,install_arch,install_release,install_size,install_file,install_memory,install_cpu,install_network,install_share,install_mount,install_ip)
          end
          if install_vm.match(/zone|lxc|gdom/)
            eval"[configure_#{install_vm}(install_client,install_ip,install_mac,install_arch,install_os,install_release,publisher_host,
                                          install_file,install_service)]"
          end
          if install_vm.match(/cdom/)
            configure_cdom(publisher_host)
          end
          if install_vm.match(/none/)
            if install_ip.match(/[0-9]/)
              check_local_config("client")
              add_hosts_entry(install_client,install_ip)
            end
            if install_mac.match(/[0-9]|[a-f]|[A-F]/)
              install_service = ""
              add_dhcp_client(install_client,install_mac,install_ip,install_arch,install_service)
            end
          end
        end
      else
        if install_mode.match(/server/)
          if install_method.match(/ai/)
            configure_ai_server(client_arch,publisher_host,publisher_port,service_name,install_file)
          else
            handle_output("Warning:\tNo install method specified")
          end
        else
          handle_output("Warning:\tClient or service name not specified")
        end
      end
    end
  when /^boot$|^stop$|^halt$|^suspend$|^resume$|^start$/
    install_mode   = "client"
    install_action = install_action.gsub(/start/,"boot")
    if install_vm.match(/parallels|vbox/)
      install_action = install_action.gsub(/start/,"boot")
      install_action = install_action.gsub(/halt/,"stop")
    end
    if !install_client.empty? and !install_vm.empty? and !install_vm.match(/none/)
      if install_action.match(/boot/)
        eval"[#{install_action}_#{install_vm}_vm(install_client,install_type)]"
      else
        eval"[#{install_action}_#{install_vm}_vm(install_client)]"
      end
    else
      if !install_client.empty? and install_vm.match(/none/)
        install_vm = get_client_vm_type(install_client)
        check_local_config(install_mode)
        if install_vm.match(/vbox|fusion|parallels/)
          $use_sudo = 0
        end
        if !install_vm.empty? and !install_vm.match(/none/)
          if install_action.match(/boot/)
            eval"[#{install_action}_#{install_vm}_vm(install_client,install_type)]"
          else
            eval"[#{install_action}_#{install_vm}_vm(install_client)]"
          end
        else
          print_valid_list("Warning:\tInvalid VM type",$valid_vm_list)
        end
      else
        if install_client.empty?
          handle_output("Warning:\tClient name not specified")
        end
      end
    end
  when /restart|reboot/
    if !install_service.empty?
      eval"[restart_#{install_service}()]"
    else
      if install_vm.match(/none/) and !install_client.empty?
        install_vm = get_client_vm_type(install_client)
      end
      if !install_vm.empty? and !install_vm.match(/none/)
        if !install_client.empty?
          eval"[stop_#{install_vm}_vm(install_client)]"
          eval"[boot_#{install_vm}_vm(install_client,install_type)]"
        else
          handle_output("Warning:\tClient name not specified")
        end
      else
        handle_output("Warning:\tInstall service or VM type not specified")
      end
    end
  when /import/
    if install_file.empty?
      if install_type.match(/packer/)
        eval"[import_packer_#{install_vm}_vm(install_client,install_vm)]"
      end
    else
      if install_vm.match(/fusion|vbox/)
        if install_file.match(/ova/)
          set_ovftool_bin()
          eval"[import_#{install_vm}_ova(install_client,install_mac,install_ip,install_file)]"
        else
          if install_file.match(/vmdk/)
            eval"[import_#{install_vm}_vmdk(install_method,install_vm,install_client,install_mac,install_os,install_arch,install_release,install_size,install_file,install_memory,install_cpu,install_network,install_share,install_mount,install_ip)]"
          end
        end
      end
    end
  when /export/
    if install_vm(/fusion|vbox/)
      eval"[export_#{install_vm}_ova(install_client,install_file)]"
    end
  when /clone|copy/
    if install_clone and !install_client.empty?
      eval"[clone_#{install_vm}_vm(install_client,install_clone,install_mac,install_ip)]"
    else
      handle_output("Warning:\tClient name or clone name not specified")
    end
  when /running|stopped|suspended|paused/
    if !install_vm.empty? and !install_vm.match(/none/)
      eval"[list_#{install_action}_#{install_vm}_vms]"
    end
  when /crypt/
    install_crypt = get_password_crypt(install_root_password)
    handle_output(install_crypt)
  when /post/
    eval"[execute_#{install_vm}_post(install_client)]"
  when /change|modify/
    if !install_client.empty?
      if install_memory.match(/[0-9]/)
        eval"[change_#{install_vm}_vm_mem(install_client,install_memory)]"
      end
      if install_mac.match(/[0-9]|[a-f]|[A-F]/)
        eval"[change_#{install_vm}_vm_mac(install_client,client_mac)]"
      end
    else
      handle_output("Warning:\tClient name not specified")
    end
  when /attach/
    if !install_vm.empty? and !install_vm.match(/none/)
      eval"[attach_file_to_#{install_vm}_vm(install_client,install_file,install_type)]"
    end
  when /detach/
    if !install_vm.empty? and !install_client.empty? and !install_vm.match(/none/)
      eval"[detach_file_from_#{install_vm}_vm(install_client,install_file,install_type)]"
    else
      handle_output("Warning:\tClient name or virtualisation platform not specified")
    end
  when /share/
    if !install_vm.empty? and !install_vm.match(/none/)
      eval"[add_shared_folder_to_#{install_vm}_vm(install_client,install_share,install_mount)]"
    end
  when /^snapshot|clone/
    if !install_vm.empty? and !install_vm.match(/none/)
      if !install_client.empty?
        eval"[snapshot_#{install_vm}_vm(install_client,install_clone)]"
      else
        handle_output("Warning:\tClient name not specified")
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
    if !install_vm.empty? and !install_vm.match(/none/)
      if !install_client.empty?
        eval"[restore_#{install_vm}_vm_snapshot(install_client,install_clone)]"
      else
        handle_output("Warning:\tClient name not specified")
      end
    end
  when /set/
    if !install_vm.empty?
      eval"[set_#{install_vm}_value(install_client,install_param,install_value)]"
    end
  when /get/
    if !install_vm.empty?
      eval"[get_#{install_vm}_value(install_client,install_param)]"
    end
  when /console|serial|connect/
    if install_type.match(/docker/)
      connect_to_docker_client(install_client)
    end
    if !install_vm.empty? and !install_vm.match(/none/)
      if !install_client.empty?
        connect_to_virtual_serial(install_client,install_vm)
      else
        handle_output("Warning:\tClient name not specified")
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
end

quit()
