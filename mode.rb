#!/usr/bin/env ruby

# Name:         mode (Multi OS Deployment Engine)
# Version:      4.5.9
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
require 'fileutils'
require 'ipaddr'
require 'uri'
require 'socket'
require 'net/http'
require 'pp'
require 'open-uri'

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
  require 'aws-sdk'
rescue LoadError
  install_gem("aws-sdk","aws-sdk")
end
begin
  require 'ssh-config'
rescue LoadError
  install_gem("ssh-config","ssh-config")
end
begin
  require 'yaml'
rescue LoadError
  install_gem("yaml","yaml")
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
$debug_mode  = false

# Load methods

if File.directory?("./methods")
  file_list = Dir.entries("./methods")
  for file in file_list
    if file =~ /rb$/
      if $debug_mode == true
        puts "Information:\tImporting #{file}"
      end
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
# Print help if specified none

if !ARGV[0]
  print_help()
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
    [ "--action",         REQUIRED ], # Action (e.g. boot, stop, create, delete, list, etc)
    [ "--arch",           REQUIRED ], # Architecture of client or VM (e.g. x86_64)
    [ "--domainname",     REQUIRED ], # Set domain (Used with deploy for VCSA)
    [ "--timezone",       REQUIRED ], # Set timezone
    [ "--mem",            REQUIRED ], # VM memory size
    [ "--vcpu",           REQUIRED ], # Number of CPUs
    [ "--mode",           REQUIRED ], # Set mode to client or server
    [ "--datastore",      REQUIRED ], # Datastore to deploy to on remote server
    [ "--server",         REQUIRED ], # Server name/IP (allow execution of commands on a remote host, or deploy to)
    [ "--mac",            REQUIRED ], # MAC Address
    [ "--vm",             REQUIRED ], # VM type
    [ "--crypt",          REQUIRED ], # Password crypt
    [ "--file",           REQUIRED ], # File, eg ISO
    [ "--clone",          REQUIRED ], # Clone name
    [ "--locale",         REQUIRED ], # Locale (e.g. en_US)
    [ "--diskmode",       REQUIRED ], # Disk mode (e.g. thin)
    [ "--help",           BOOLEAN ],  # Display usage information
    [ "--checksum",       BOOLEAN ],  # Do checksums
    [ "--masked",         BOOLEAN ],  # Mask passwords in output (WIP)
    [ "--unmasked",       BOOLEAN ],  # Unmask passwords in output (WIP)
    [ "--vmtools",        BOOLEAN ],  # Unmask passwords in output (WIP)
    [ "--vnc",            BOOLEAN ],  # Enable VNC mode
    [ "--param",          REQUIRED ], # Set a parameter of a VM
    [ "--ip",             REQUIRED ], # IP Address of client
    [ "--ipfamily",       REQUIRED ], # IP family (e.g. IPv4 or IPv6)
    [ "--size",           REQUIRED ], # VM disk size (if used with deploy action, this sets the size of the VM, e.g. tiny)
    [ "--value",          REQUIRED ], # Set the value of a parameter
    [ "--network",        REQUIRED ], # Set network type (e.g. hostonly, bridged, nat)
    [ "--netmask",        REQUIRED ], # Set netmask
    [ "--hosts",          REQUIRED ], # Set default hosts resolution entry, eg "files"
    [ "--files",          REQUIRED ], # Set default files resolution entry, eg "dns, files"
    [ "--servernetwork",  REQUIRED ], # Server network (used when deploying to a remote server)
    [ "--publisherhost",  REQUIRED ], # Publisher host
    [ "--publisherport",  REQUIRED ], # Publisher port
    [ "--license",        REQUIRED ], # License key (e.g. ESX)
    [ "--method",         REQUIRED ], # Install method (e.g. Kickstart)
    [ "--mount",          REQUIRED ], # Mount point
    [ "--service",        REQUIRED ], # Service name
    [ "--timeserver",     REQUIRED ], # Set NTP server IP / Address
    [ "--gateway",        REQUIRED ], # Gateway IP
    [ "--hostonly",       REQUIRED ], # Hostonly IP
    [ "--os",             REQUIRED ], # OS type
    [ "--format",         REQUIRED ], # Output format
    [ "--post",           REQUIRED ], # Post install configuration
    [ "--publisher",      REQUIRED ], # Set publisher information (Solaris AI)
    [ "--adminpassword",  REQUIRED ], # Client admin password
    [ "--ssopassword",    REQUIRED ], # SSO password
    [ "--serverpassword", REQUIRED ], # Admin password of server to deploy to
    [ "--release",        REQUIRED ], # OS Release
    [ "--mirror",         REQUIRED ], # Mirror / Repo
    [ "--copykeys",       BOOLEAN ],  # Copy SSH Keys
    [ "--share",          REQUIRED ], # Shared folder
    [ "--type",           REQUIRED ], # Install type (e.g. ISO, client, OVA, Network)
    [ "--model",          REQUIRED ], # Model
    [ "--admin",          REQUIRED ], # Admin username for client VM to be created
    [ "--serveradmin",    REQUIRED ], # Admin username for server to deploy to
    [ "--verbose",        BOOLEAN ],  # Verbose mode
    [ "--version",        BOOLEAN ],  # Display version information
    [ "--test",           BOOLEAN ],  # Test mode
    [ "--rootpassword",   REQUIRED ], # Client root password
    [ "--locale",         REQUIRED ], # Select language/language (e.g. en_US)
    [ "--console",        REQUIRED ], # Select console type (e.g. text, serial, x11) (default is text)
    [ "--headless",       BOOLEAN ],  # Headless mode for builds
    [ "--defaults",       BOOLEAN ],  # Answer yes to all questions (accept defaults)
    [ "--vncpassword",    REQUIRED ], # VNC password
    [ "--shell",          REQUIRED ], # Install shell (used for packer, e.g. winrm, ssh)
    [ "--enable",         REQUIRED ], # Mount point
    [ "--command",        REQUIRED ], # Set repository
    [ "--repo",           REQUIRED ], # Set repository
    [ "--nameserver",     REQUIRED ], # Delete client or VM
    [ "--changelog",      BOOLEAN ],  # Print changelog
    [ "--nosuffix",       BOOLEAN ],  # Don't add suffix to AWS AMI names
    [ "--nosuffix",       BOOLEAN ],  # Don't add suffix to AWS AMI names
    [ "--strict",         BOOLEAN ],  # Ignore SSH keys
    [ "--dryrun",         BOOLEAN ],  # Dryrun flag
    [ "--search",         REQUIRED ], # Search string
    [ "--creds",          REQUIRED ], # Credentials file
    [ "--desc",           REQUIRED ], # Description
    [ "--name",           REQUIRED ], # Client / AWS Name
    [ "--client",           REQUIRED ], # Client / AWS Name
    [ "--format",         REQUIRED ], # AWS disk format (e.g. VMDK, RAW, VHD)
    [ "--target",         REQUIRED ], # AWS target format (e.g. citrix, vmware, windows)
    [ "--access",         REQUIRED ], # AWS Access Key
    [ "--secret",         REQUIRED ], # AWS Secret Key
    [ "--region",         REQUIRED ], # AWS Secret Key
    [ "--key",            REQUIRED ], # AWS Key Name
    [ "--keyfile",        REQUIRED ], # AWS Keyfile
    [ "--group",          REQUIRED ], # AWS Group Name
    [ "--suffix",         REQUIRED ], # AWS AMI Name suffix
    [ "--prefix",         REQUIRED ], # AWS S3 prefix
    [ "--bucket",         REQUIRED ], # AWS S3 bucket
    [ "--id",             REQUIRED ], # AWS Instance ID
    [ "--number",         REQUIRED ], # Number of AWS instances
    [ "--container",      REQUIRED ], # AWS AMI export container
    [ "--comment",        REQUIRED ], # Comment
    [ "--acl",            REQUIRED ], # AWS ACL
    [ "--grant",          REQUIRED ], # AWS ACL grant
    [ "--perms",          REQUIRED ], # AWS ACL perms
    [ "--email",          REQUIRED ], # AWS ACL email
    [ "--snapshot",       REQUIRED ], # AWS snapshot
    [ "--stack",          REQUIRED ], # AWS CF Stack
    [ "--object",         REQUIRED ], # AWS S3 object
    [ "--proto",          REQUIRED ], # Protocol
    [ "--from",           REQUIRED ], # From
    [ "--to",             REQUIRED ], # To
    [ "--ports",          REQUIRED ], # Port (makes to and from the same in the case of and IP rule)
    [ "--dir",            REQUIRED ], # Directory / Direction 
    [ "--ami",            REQUIRED ]  # AWS AMI ID
  )
rescue
  print_help()
  exit
end

# load global variables

set_global_vars()

# Backward compatibility for old --client switch

if option["client"]
  option["name"] = option["client"]
end

# Check based on switches - try guess if we are not given full information

if option["ami"]
  if !option["vm"]
    option["vm"] = "aws"
  end
end

# Get flags (BOOLEANs)

flags     = []
raw_flags = IO.readlines($script_file).grep(/BOOLEAN/).join.split(/\n/)
raw_flags.each do |raw_flag|
  if raw_flag.match(/\[/)
    raw_flag = raw_flag.split(/--/)[1].split(/"/)[0]
    flags.push(raw_flag)
  end
end

# Handle command line flags

flags.each do |flag|
  if option[flag]
    value = option[flag]
    if flag.match(/help|version|changelog/)
      eval("print_#{flag}")
      quit()
    else
      value = eval("$#{flag}_mode = #{value}")
      if option['verbose'] == true
        handle_output("Information:\tSetting flag '#{flag}' to '#{value}'")
      end
    end
  end
  if !option[flag]
    if eval("$default_#{flag}")
      value        = eval("$default_#{flag}")
      option[flag] = value
      eval("$#{flag}_mode = #{value}")
    else
      value = false
    end
    if option['verbose'] == true
      handle_output("Information:\tSetting flag '#{flag}' to '#{value}'")
    end
  end
end

# Convert some flags to stings to keep processing happy

$default_dryrun = $default_dryrun.to_s

# Get params (REQUIREDs)

params     = []
raw_params = IO.readlines($script_file).grep(/REQUIRED/).join.split(/\n/)
raw_params.each do |raw_param|
  if raw_param.match(/\[/)
    raw_param = raw_param.split(/--/)[1].split(/"/)[0]
    params.push(raw_param)
  end
end

# Handle types and set VM if not set

if option['type'] or option['action']
  if option['type']
    if option['type'].match(/bucket|ami|instance|object|snapshot|stack|cf|cloud|image|key|securitygroup|id|iprule/)
      if !option['vm']
        option['vm'] = "aws"
      end
      if option['action']
        if option['action'].match(/list/)
          $default_aws_securitygroup = "all"
          $default_aws_group         = "all"
          $default_aws_key           = "all"
          $default_aws_keypair       = "all"
          $default_aws_stack         = "all"
          $default_aws_bucket        = "all"
        end
      end
    end
  else
    if option['action'].match(/connect/)
      if option['id']
        if !option['vm']
          option['vm'] = "aws"
        end
      end
    end
  end
else
  type = "none"
end

# Handle some AWS defaults

if option['vm']
  if option['vm'].match(/aws/)
    if option['os'] 
      case option['os'].downcase
      when /centos/
        $default_aws_ami    = "ami-fedafc9d"
        $default_admin_user = "centos"
      when /amznl/
        $default_aws_ami    = "ami-28cff44b"
        $default_admin_user = "ec2-user"
      else
        $default_aws_ami    = "ami-28cff44b"
        $default_admin_user = "ec2-user"
      end
    end
  end
end

# Handle OS option

if option['os']
  option['os'] = option['os'].downcase
  option['os'] = option['os'].gsub(/^win$/,"windows")
  option['os'] = option['os'].gsub(/^sol$/,"solaris")
  if !$valid_os_list.to_s.downcase.match(/#{option['os'].downcase}/)
    print_valid_list("Warning:\tInvalid OS",$valid_os_list)
  end
end

# Handle command line parameters

params.each do |param|
  value = $empty_value
  if !option[param]
    if option['vm']
      vm = option['vm']
      if eval("$default_#{vm}_#{param}")
        value = eval("$default_#{vm}_#{param}")
        if option['verbose']
          handle_output("Information:\tSetting parameter '#{param}' to '#{value}'")
        end
        option[param] = value
      else
        if eval("$default_vm_#{param}")
          value = eval("$default_vm_#{param}")
          if option['verbose']
            handle_output("Information:\tSetting parameter '#{param}' to '#{value}'")
          end
          option[param] = value
        else
          if option['os']
            if eval("$default_#{option['os']}_#{param}")
              value = eval("$default_#{option['os']}_#{param}")
              if option['verbose']
                handle_output("Information:\tSetting parameter '#{param}' to '#{value}'")
              end
              option[param] = value
            else
              if eval("$default_#{param}")
                value = eval("$default_#{param}")
                if option['verbose']
                  handle_output("Information:\tSetting parameter '#{param}' to '#{value}'")
                end
                option[param] = value
              else
                if option['verbose']
                  handle_output("Information:\tSetting parameter '#{param}' to '#{value}'")
                end
                option[param] = value
              end
            end
          else
            if eval("$default_#{param}")
              value = eval("$default_#{param}")
              if option['verbose']
                handle_output("Information:\tSetting parameter '#{param}' to '#{value}'")
              end
              option[param] = value
            else
              if option['verbose']
                handle_output("Information:\tSetting parameter '#{param}' to '#{value}'")
              end
              option[param] = value
            end
          end
        end
      end
    else
      if eval("$default_#{param}")
        value = eval("$default_#{param}")
        if option['verbose']
          handle_output("Information:\tSetting parameter '#{param}' to '#{value}'")
        end
        option[param] = value
      else
        if option['verbose']
          handle_output("Information:\tSetting parameter '#{param}' to '#{value}'")
        end
        option[param] = value
      end
    end
  else
    if eval("$valid_#{param}_list")
      list  = eval("$valid_#{param}_list")
      value = option[param]
      valid = false
      list.each do |item|
        if item.downcase.match(/#{value.downcase}/)
          valid = true
        end
      end
      if valid == false
        handle_output("Warning:\tInvalid value '#{value}' for parameter '#{param}'")
        handle_output("Information:\tValid values include #{list.join(", ")}")
        quit()
      end
    end
  end
end

# Make sure a VM type is set for ansible and packer

if option['type'].match(/ansible|packer/)
  if option['vm'].match(/^#{$empty_value}$/)
    handle_output("Warning:\tNo VM type specified")
    quit()
  end
end

# If boot, halt, or delete are given and VM type is unknown try to determine it

if option['action'].match(/boot|start|halt|stop|delete/)
  if !option['name'].match(/^#{$empty_value}$/)
    if option['vm'].match(/^#{$empty_value}$/)
      if $verbose_mode == true
        handle_output("Warning:\tNo VM type specified")
      end
      option['vm'] = get_client_vm_type(option['name'])
    end
  end
end

# Check packer is installed and is latest version

if option["type"].match(/packer/)
  check_packer_is_installed
end

# Prime HTML

if $output_format.match(/html/)
  $output_text.push("<html>")
  $output_text.push("<head>")
  $output_text.push("<title>#{$script_name}</title>")
  $output_text.push("</head>")
  $output_text.push("<body>")
end

# Handle port switch

if !option['ports'].match(/^#{$empty_value}$/)
  option['from'] = option['ports']
  option['to']   = option['ports']
end

# Handle keyfile switch

if !option['keyfile'].match(/^#{$empty_value}$/)
  if !File.exist?(option['keyfile'])
    handle_output("Warning:\tKey file #{option['keyfile']} does not exist")
    exit
  end
end

# Handle AWS credentials

if !option['vm'].match(/^#{$empty_value}$/)
  if option['vm'].match(/aws/)
    if option['suffix']
      $default_aws_suffix = option['suffix']
    end
    if option['creds']
      option['creds'] = option['creds']
      option['access'],option['secret'] = get_aws_creds(option['creds'])
    else
      option['creds'] = $default_aws_creds
      if ENV["AWS_ACCESS_KEY"]
        option['access'] = ENV["AWS_ACCESS_KEY"]
      end
      if ENV["AWS_SECRET_KEY"]
        option['secret'] = ENV["AWS_SECRET_KEY"]
      end
      if !option['secret'] or !option['access']
        option['access'],option['secret'] = get_aws_creds(option['creds'])
      else 
        if option['secret']
          option['secret'] = option['secret']
        else
          option['secret'] = ""
        end
        if option['access']
          option['access'] = option['access']
        else
          option['access'] = ""
        end
      end
    end
    if option['access'].match(/^#{$empty_value}$/) or option['secret'].match(/^#{$empty_value}$/)
      handle_output("Warning:\tAWS Access and Secret Keys not found")
      exit
    else
      if !File.exist?(option['creds'])
        create_aws_creds_file(option['creds'],option['access'],option['secret'])
      end
    end
  end
end

# Handle client name switch

if !option['name'].match(/^#{$empty_value}$/)
  check_hostname(option['name'])
  if $verbose_mode == true
    handle_output("Setting:\tClient name to #{option['name']}")
  end
end

# If specified admin set admin user

if !option['admin'].match(/^#{$empty_value}$/)
  if option['action']
    if !option['action'].match(/connect|ssh/)
      $default_admin_user = option['admin']
      if $verbose_mode == true
        handle_output("Information:\tSetting admin user to #{$default_admin_user}")
      end
    end
  end
else
  if option['action']
    if option['action'].match(/connect|ssh/)
      if option['vm']
        if option['vm'].match(/aws/)
          option['admin'] = $default_aws_user
        else
          option['admin'] = %x[whoami].chomp
        end
      else
        if option['id']
          option['admin'] = $default_aws_user
        else
          option['admin'] = %x[whoami].chomp
        end
      end
    end
  else
    option['admin'] = %x[whoami].chomp
  end
end

# Change VM disk size

if !option['size'].match(/^#{$empty_value}$/)
  $default_vm_size = option['size']
  if !$default_vm_size.match(/G$/)
    $default_vm_size = $default_vm_size+"G"
  end
end

# Get MAC address if specified

if !option['mac'].match(/^#{$empty_value}$/)
  if !option['vm']
    option['vm'] = "none"
  end
  option['mac'] = check_install_mac(option['mac'],option['vm'])
  if $verbose_mode == true
     handle_output("Information:\tSetting client MAC address to #{option['mac']}")
  end
else
  option['mac'] = ""
end

# Handle architecture switch

 if !option['arch'].match(/^#{$empty_value}$/)
   option['arch'] = option['arch'].downcase
   if option['arch'].match(/sun4u|sun4v/)
     option['arch'] = "sparc"
   end
   if option['os'].match(/vmware/)
     option['arch'] = "x86_64"
   end
   if option['os'].match(/bsd/)
     option['arch'] = "i386"
   end
 end

# Handle install shell

if option['shell'].match(/^#{$empty_value}$/)
  if option['os'].match(/win/)
    $default_shell  = "winrm"
    option['shell'] = $default_shell
  else
    $default_shell  = "ssh"
    option['shell'] = $default_shell
  end
end

# Handle vm switch

if !option['vm'].match(/^#{$empty_value}$/)
  option['vm'] = option['vm'].gsub(/virtualbox/,"vbox")
  if option['vm'].match(/aws/)
    if option['service'].match(/^#{$empty_value}$/)
      option['service'] = $default_aws_type
    end
  end
end

# Handle share switch

if !option['share'].match(/^#{$empty_value}$/)
  if !File.directory?(option['share'])
    handle_output("Warning:\tShare point #{option['share']} doesn't exist")
    exit
  end
  if option['mount'].match(/^#{$empty_value}$/)
    option['mount'] = File.basename(option['share'])
  end
  if $verbose_mode == true
    handle_output("Information:\tSharing #{option['share']}")
    handle_output("Information:\tSetting mount point to #{option['mount']}")
  end
end

# Get Timezone

if option['timezone'].match(/^#{$empty_value}$/)
  if !option['os'].match(/^#{$empty_value}$/)
    if option['os'].match(/win/)
     option['timezone'] = $default_windows_timezone
    else
      option['timezone'] = $default_timezone
    end
  end
end

# Handle test switch

if option['test'] == true
  $test_mode     = true
  $download_mode = false
else
  $download_mode = true
  $test_mode     = false
end

# Handle clone swith

if option['clone'].match(/^#{$empty_value}$/)
  if option['action'] == "snapshot"
    clone_date      = %x[date].chomp.downcase.gsub(/ |:/,"_")
    option['clone'] = option['name']+"-"+clone_date
  end
  if $verbose_mode == true and option['clone']
    handle_output("Information:\tSetting clone name to #{option['clone']}")
  end
end

# Handle size switch

if option['os'].match(/vmware/)
  $default_vm_size = "40G"
end

# Handle option size

if !option['size'].match(/^#{$empty_value}$/)
  if option['type'].match(/vcsa/)
    if !option['size'].match(/[0-9]/)
      option['size'] = $default_vcsa_size
    end
  end
else
  if !option['vm'].match(/aws/) and !option['type'].match(/cloud|cf|stack/)
    if option['type'].match(/vcsa/)
      option['size'] = $default_vcsa_size
    else
      option['size'] = $default_vm_size
    end
  end
end

# Try to determine install method when give just an ISO

if !option['file'].match(/^#{$empty_value}$/)
  if option['vm'] == "vbox" and option['file'] == "tools"
    option['file'] = $vbox_additions_iso
  end
  if !option['action'].match(/download/)
    if !File.exist?(option['file']) and !option['file'].match(/^http/)
      handle_output("Warning:\tFile #{option['file']} does not exist")
      exit
    end
  end
  if option['action'].match(/deploy/)
    if option['type'].match(/^#{$empty_value}$/)
      option['type'] = get_install_type_from_file(option['file'])
    end
  end
  if !option['file'].match(/^#{$empty_value}$/) and option['action'].match(/create|add/)
    if option['method'].match(/^#{$empty_value}$/)
      option['method'] = get_install_method_from_iso(option['file'])
    end
    if option['type'].match(/^#{$empty_value}$/)
      option['type'] = get_install_type_from_file(option['file'])
      if $verbose_mode == true
        handle_output("Information:\tSetting install type to #{option['type']}")
      end
    end
  end
end

# Handle values and parameters

if !option['param'].match(/^#{$empty_value}$/)
  if !option['action'].match(/get/)
    if !option['value']
      handle_output("Warning:\tSetting a parameter requires a value")
      exit
    else
      if !option['value']
        handle_output("Warning:\tSetting a parameter requires a value")
        exit
      end
    end
  end
end

if !option['value'].match(/^#{$empty_value}$/)
  if option['param'].match(/^#{$empty_value}$/)
    handle_output("Warning:\tSetting a value requires a parameter")
    exit
  end
end

# Handle LDoms

if !option['method'].match(/^#{$empty_value}$/)
  if option['method'].match(/dom/)
    if option['method'].match(/cdom/)
      option['mode'] = "server"
      option['vm']   = "cdom"
      if $verbose_mode == true
        handle_output("Information:\tSetting mode to server")
        handle_output("Information:\tSetting vm to cdrom")
      end
    else
      if option['method'].match(/gdom/)
        option['mode'] = "client"
        option['vm']   = "gdom"
        if $verbose_mode == true
          handle_output("Information:\tSetting mode to client")
          handle_output("Information:\tSetting vm to gdom")
        end
      else
        if option['method'].match(/ldom/)
          if !option['name'].match(/^#{$empty_value}$/)
            option['method'] = "gdom"
            option['vm']     = "gdom"
            option['mode']   = "client"
            if $verbose_mode == true
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
    if option['mode'].match(/client/)
      if !option['vm'].match(/^#{$empty_value}$/)
        if option['method'].match(/ldom|gdom/)
          option['vm'] = "gdom"
        end
      end
    else
      if option['mode'].match(/server/)
        if !option['vm'].match(/^#{$empty_value}$/)
          if option['method'].match(/ldom|cdom/)
            option['vm'] = "cdom"
          end
        end
      end
    end
  end
else
  if !option['mode'].match(/^#{$empty_value}$/)
    if option['vm'].match(/ldom/)
      if option['mode'].match(/client/)
        option['vm']     = "gdom"
        option['method'] = "gdom"
        if $verbose_mode == true
          handle_output("Information:\tSetting method to gdom")
          handle_output("Information:\tSetting vm to gdom")
        end
      end
      if option['mode'].match(/server/)
        option['vm']     = "cdom"
        option['method'] = "cdom"
        if $verbose_mode == true
          handle_output("Information:\tSetting method to cdom")
          handle_output("Information:\tSetting vm to cdom")
        end
      end
    end
  end
end

# Handle Packer and VirtualBox not supporting hostonly or bridged network

if !option['network'].match(/nat/)
  if option['vm'].match(/virtualbox|vbox/)
    if option['type'].match(/packer/) or option['method'].match(/packer/)
      handle_output("Warning:\tVirtualBox does not support Hostonly or Bridged network with Packer")
    end
  end
end

# Check action when set to build

if option['action'].match(/build/)
  if option['type'].match(/^#{$empty_value}$/)
    handle_output("Information:\tSetting Install Service to Packer")
    option['type'] = "packer"
  end
  if option['vm'].match(/^#{$empty_value}$/)
    if option['name'].match(/^#{$empty_value}$/)
      handle_output("Warning:\tNo client name specified")
      exit
    end
    option['vm'] = get_client_vm_type_from_packer(option['name'])
  end
  if option['vm'].match(/^#{$empty_value}$/)
    handle_output("Warning:\tVM type not specified")
    exit
  else
    if !option['vm'].match(/vbox|fusion|aws/)
      handle_output("Warning:\tInvalid VM type specified")
      exit
    end
  end
end

if !option['ssopassword'].match(/^#{$empty_value}$/)
  option['adminpassword'] = option['ssopassword']
end

# Get Netmask

if option['netmask'].match(/^#{$empty_value}$/)
  if option['type'].match(/vcsa/)
    option['netmask'] = $default_cidr
  end
end

# # Handle deploy

if option['action'].match(/deploy/)
  if option['type'].match(/^#{$empty_value}$/)
    option['type'] = "esx"
  end
  if option['type'].match(/esx|vcsa/)
    if option['serverpassword'].match(/^#{$empty_value}$/)
      option['serverpassword'] = option['rootpassword']
    end
    check_ovftool_exists()
    if option['type'].match(/vcsa/)
      if option['file'].match(/^#{$empty_value}$/)
        handle_output("Warning:\tNo deployment image file specified")
        exit
      end
      check_password(option['rootpassword'])
      check_password(option['adminpassword'])
    end
  end
end

# Handle console switch

if !option['console'].match(/^#{$empty_value}$/)
  case option['console']
  when /x11/
    $text_mode = false
  when /serial/
    $serial_mode = true
    $text_mode   = true
  else
    $text_mode = true
  end
else
  option['console'] = "text"
  $text_mode        = false
end

# Handle list switch

if option['action'].match(/list/)
  if option['vm'].match(/^#{$empty_value}$/) and option['service'].match(/^#{$empty_value}$/) and option['method'].match(/^#{$empty_value}$/) and option['type'].match(/^#{$empty_value}$/) and option['mode'].match(/^#{$empty_value}$/)
    handle_output("Warning:\tNo type or service specified")
    exit
  end
end

# Handle action switch

if !option['action'].match(/^#{$empty_value}$/)
  if option['action'].match(/delete/) and option['service'].match(/^#{$empty_value}$/)
    if option['vm'].match(/^#{$empty_value}$/) and !option['type'].match(/^#{$empty_value}$/)
      option['vm'] = get_client_vm_type_from_packer(option['name'])
    else
      if !option['type'].match(/^#{$empty_value}$/) and option['vm'].match(/^#{$empty_value}$/)
        if option['type'].match(/packer/)
          if !option['name'].match(/^#{$empty_value}$/)
            option['vm'] = get_client_vm_type_from_packer(option['name'])
          end
        end
      end
    end
  end
  if option['action'].match(/migrate|deploy/)
    if option['action'].match(/deploy/)
      if option['type'].match(/vcsa/)
        option['vm'] = "fusion"
      else
        option['type']   = get_install_type_from_file(option['file'])
        if option['type'].match(/vcsa/)
          option['vm']= "fusion"
        end
      end
    end
    if option['vm'].match(/^#{$empty_value}$/)
      handle_output("Information:\tVirtualisation method not specified, setting virtualisation method to VMware")
      option['vm'] = "vm"
    end
    if option['server'].match(/^#{$empty_value}$/) or option['ip'].match(/^#{$empty_value}$/)
      handle_output("Warning:\tRemote server hostname or IP not specified")
      exit
    end
  end
end

# Handle OS switch

if !option['os'].match(/^#{$empty_value}$/)
  option['os'] = option['os'].downcase
  option['os'] = option['os'].gsub(/windows/,"win")
  option['os'] = option['os'].gsub(/scientificlinux|scientific/,"sl")
  option['os'] = option['os'].gsub(/oel/,"oraclelinux")
  option['os'] = option['os'].gsub(/esx|esxi|vsphere/,"vmware")
  option['os'] = option['os'].gsub(/^suse$/,"opensuse")
  option['os'] = option['os'].gsub(/solaris/,"sol")
  option['os'] = option['os'].gsub(/redhat/,"rhel")
else
  if option['type'].match(/vcsa|packer/)
    if option['service'].match(/^#{$empty_value}$/) or option['os'].match(/^#{$empty_value}$/) or option['method'].match(/^#{$empty_value}$/) or option['release'].match(/^#{$empty_value}$/) or option['arch'].match(/^#{$empty_value}$/) or option['label'].match(/^#{$empty_value}$/)
      (option['service'],option['os'],option['method'],option['release'],option['arch'],option['label']) = get_install_service_from_file(option['file'])
    end
  else
    option['os'] = ""
  end
end

# Handle install service switch

if !option['service'].match(/^#{$empty_value}$/)
  if $verbose_mode == true
    handle_output("Information:\tSetting install service to #{option['service']}")
  end
  if option['type'].match(/^packer$/)
    check_packer_is_installed()
    option['mode']    = "client"
    if option['method'].match(/^#{$empty_value}$/) and option['os'].match(/^#{$empty_value}$/) and !option['action'].match(/build|list|import|delete/) and !option['vm'].match(/aws/)
      handle_output("Warning:\tNo OS, or Install Method specified for build type #{option['service']}")
      exit
    end
    if option['vm'].match(/^#{$empty_value}$/) and !option['action'].match(/list/)
      handle_output("Warning:\tNo VM type specified for build type #{option['service']}")
      exit
    end
    if option['name'].match(/^#{$empty_value}$/) and !option['action'].match(/list/) and !option['vm'].match(/aws/)
      handle_output("Warning:\tNo Client name specified for build type #{option['service']}")
      exit
    end
    if option['file'].match(/^#{$empty_value}$/) and !option['action'].match(/build|list|import|delete/) and !option['vm'].match(/aws/)
      handle_output("Warning:\tNo ISO file specified for build type #{option['service']}")
      exit
    end
    if !option['ip'].match(/[0-9]/) and !option['action'].match(/build|list|import|delete/) and !option['vm'].match(/aws/)
      handle_output("Warning:\tNo IP Address specified ")
      exit
    end
    if !option['mac'].match(/[0-9]|[A-F]|[a-f]/) and !option['action'].match(/build|list|import|delete/)
      handle_output("Warning:\tNo MAC Address specified")
      handle_output("Information:\tGenerating MAC Address")
      if !option['vm'].match(/^#{$empty_value}$/)
        if !option['vm'].match(/^#{$empty_value}$/)
          option['mac'] = generate_mac_address(option['vm'])
        else
          option['mac'] = generate_mac_address(option['name'])
        end
      else
        option['mac'] = generate_mac_address(option['method'])
      end
    end
  end
else
  if option['type'].match(/vcsa|packer/)
    if option['service'].match(/^#{$empty_value}$/) or option['os'].match(/^#{$empty_value}$/) or option['method'].match(/^#{$empty_value}$/) or option['release'].match(/^#{$empty_value}$/) or option['arch'].match(/^#{$empty_value}$/) or option['file'].match(/^#{$empty_value}$/)
      (option['service'],option['os'],option['method'],option['release'],option['arch'],option['label']) = get_install_service_from_file(option['file'])
    end
    if option['type'].match(/^packer$/)
      check_packer_is_installed()
      option['mode'] = "client"
      if option['method'].match(/^#{$empty_value}$/) and option['os'].match(/^#{$empty_value}$/) and !option['action'].match(/build|list|import|delete/)
        handle_output("Warning:\tNo OS, or Install Method specified for build type #{option['service']}")
        exit
      end
      if option['vm'].match(/^#{$empty_value}$/) and !option['action'].match(/list/)
        handle_output("Warning:\tNo VM type specified for build type #{option['service']}")
        exit
      end
      if option['name'].match(/^#{$empty_value}$/) and !option['action'].match(/list/)
        handle_output("Warning:\tNo Client name specified for build type #{option['service']}")
        exit
      end
      if option['file'].match(/^#{$empty_value}$/) and !option['action'].match(/build|list|import|delete/)
        handle_output("Warning:\tNo ISO file specified for build type #{option['service']}")
        exit
      end
      if !option['ip'].match(/[0-9]/) and !option['action'].match(/build|list|import|delete/)
        handle_output("Warning:\tNo IP Address specified")
        exit
      end
      if !option['mac'].match(/[0-9]|[A-F]|[a-f]/) and !option['action'].match(/build|list|import|delete/)
        handle_output("Warning:\tNo MAC Address specified")
        handle_output("Information:\tGenerating MAC Address")
        if option['vm'].match(/^#{$empty_value}$/)
          option['vm'] = "none"
        end
        option['mac'] = generate_mac_address(option['vm'])
      end
    end
  else
    option['service'] = ""
  end
end

# Make sure a service (e.g. packer) or an install file (e.g. OVA) is specified for an import

if option['action'].match(/import/)
  if option['file'].match(/^#{$empty_value}$/) and option['service'].match(/^#{$empty_value}$/) and !option['type'].match(/packer/)
    vm_types       = [ "fusion", "vbox" ]
    exists         = []
    vm_exists      = ""
    vm_type        = ""
    vm_types.each do |vm_type|
      exists = check_packer_vm_image_exists(option['name'],vm_type)
      if exists[0].match(/yes/)
        option['type'] = "packer"
        option['vm']   = vm_type
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

if option['release'].match(/[0-9]/)
  if option['type'].match(/packer/) and option['action'].match(/build|delete|import/)
    option['release'] = ""
  else
    if option['vm'].match(/^#{$empty_value}$/)
      option['vm'] = "none"
    end
    if option['vm'].match(/zone/) and $os_rel.match(/10|11/) and !option['release'].match(/10|11/)
      handle_output("Warning:\tInvalid release number: #{option['release']}")
      exit
    end
#    if !option['release'].match(/[0-9]/) or option['release'].match(/[a-z,A-Z]/)
#      puts "Warning:\tInvalid release number: "+option['release']
#      exit
#    end
  end
else
  if option['vm'].match(/zone/)
    option['release'] = $os_rel
  else
    option['release'] = ""
  end
end
if $verbose_mode == true and option['release']
  handle_output("Information:\tSetting Operating System version to #{option['release']}")
end

# Handle empty OS option

if option['os'].match(/^#{$empty_value}$/)
  if !option['vm'].match(/^#{$empty_value}$/)
    if option['action'].match(/add|create/)
      if option['method'].match(/^#{$empty_value}$/)
        if !option['vm'].match(/ldom|cdom|gdom|aws/)
          handle_output("Warning:\tNo OS or install method specified when creating VM")
          exit
        end
      end
    end
  end
end

# Handle memory switch

if option['mem'].match(/^#{$empty_value}$/)
  if !option['vm'].match(/^#{$empty_value}$/)
    if option['os'].match(/vs|esx|vmware|vsphere/) or option['method'].match(/vs|esx|vmware|vsphere/)
      option['mem'] = "4096"
    end
    if !option['os'].match(/^#{$empty_value}$/)
      if option['os'].match(/sol/)
        if option['release'].to_i > 9
          option['mem'] = "2048"
        end
      end
    else
      if option['method'] == "ai"
        option['mem'] = "2048"
      end
    end
  end
end

# Get/set publisher port (Used for configuring AI server)

if option['publisher'] and option['mode'].match(/server/) and $os_name.match(/SunOS/)
  option['publisherhost'] = option['publisher']
  if option['publisherhost'].match(/:/)
    (option['publisherhost'],option['publisherport']) = option['publisherhost'].split(/:/)
  else
    option['publisherport'] = $default_ai_port
  end
  handle_output("Information:\tSetting publisher host to #{option['publisherhost']}")
  handle_output("Information:\tSetting publisher port to #{option['publisherport']}")
else
  if option['mode'] == "server" or option['file'].match(/repo/)
    if $os_name == "SunOS"
      check_local_config("server")
      option['publisherhost'] = $default_host
      option['publisherport'] = $default_ai_port
      if $verbose_mode == true
        handle_output("Information:\tSetting publisher host to #{option['publisherhost']}")
        handle_output("Information:\tSetting publisher port to #{option['publisherport']}")
      end
    end
  else
    if option['vm'].match(/^#{$empty_value}$/)
      if option['action'].match(/create/)
        option['mode'] = "server"
        check_local_config(option['mode'])
      end
    else
      option['mode'] = "client"
      check_local_config(option['mode'])
    end
    option['publisherhost'] = $default_host
  end
end

# If service is set, but method and os isn't specified, try to set method from service name

if !option['service'].match(/^#{$empty_value}$/) and option['method'].match(/^#{$empty_value}$/) and option['os'].match(/^#{$empty_value}$/)
  option['method'] = get_install_method_from_service(option['service'])
else
  if option['method'].match(/^#{$empty_value}$/) and option['os'].match(/^#{$empty_value}$/)
    option['method'] = get_install_method_from_service(option['service'])
  end
end

# Handle VM switch

if !option['vm'].match(/^#{$empty_value}$/)
  option['mode'] = "client"
  case option['vm']
  when /parallels/
    check_local_config("client")
    install_status = check_parallels_is_installed()
    handle_vm_install_status(option['vm'],install_status)
    option['vm']   = "parallels"
    $use_sudo    = false
    option['size'] = option['size'].gsub(/G/,"000")
    $default_hostonly_ip = "192.168.2.254"
  when /virtualbox|vbox/
    check_local_config("client")
    install_status = check_vbox_is_installed()
    handle_vm_install_status(option['vm'],install_status)
    option['vm']   = "vbox"
    $use_sudo    = false
    option['size'] = option['size'].gsub(/G/,"000")
    $default_hostonly = "192.168.3.254"
    $default_gateway  = "192.168.3.254"
  when /vmware|fusion/
    check_local_config("client")
    install_status = check_fusion_is_installed()
    handle_vm_install_status(option['vm'],install_status)
    check_promisc_mode()
    $use_sudo  = false
    option['vm'] = "fusion"
    $default_hostonly = "192.168.2.254"
    $default_gateway  = "192.168.2.254"
    # Set vmrun bin
    set_vmrun_bin()
  when /zone|container|lxc/
    if $os_name.match(/SunOS/)
      option['vm'] = "zone"
    else
      option['vm'] = "lxc"
    end
  when /ldom|cdom|gdom/
    if $os_arch.downcase.match(/sparc/) and $os_name.match(/SunOS/)
      if install.release.match(/^#{$empty_value}$/)
        option['release']   = $os_rel
      end
      if $os_rel.match(/10|11/)
        if option['mode'].match(/client/)
          option['vm'] = "gdom"
        end
        if option['mode'].match(/server/)
          option['vm'] = "cdom"
        end
      else
        handle_output("Warning:\tLDoms require Solaris 10 or 11")
      end
    else
      handle_output("Warning:\tLDoms require Solaris on SPARC")
      exit
    end
  end
  if !$valid_vm_list.to_s.downcase.match(/#{option['vm']}/) and !option['action'].match(/list/)
    print_valid_list("Warning:\tInvalid VM type",$valid_vm_list)
  end
  if $verbose_mode == true
    handle_output("Information:\tSetting VM type to #{option['vm']}")
  end
else
  option['vm'] = "none"
end

if !option['vm'].match(/^#{$empty_value}$/) or !option['method'].match(/^#{$empty_value}$/)
  if !option['model'].match(/^#{$empty_value}$/)
    option['model'] = option['model'].downcase
  else
    if option['arch'].match(/i386|x86|x86_64|x64|amd64/)
      option['model'] = "vmware"
    else
      option['model'] = ""
    end
  end
  if $verbose_mode == true and option['model']
    handle_output("Information:\tSetting model to #{option['model']}")
  end
end

# Check OS switch

if !option['os'].match(/^#{$empty_value}$/)
  if option['os'].match(/^Linux|^linux/)
    if option['file'].match(/^#{$empty_value}$/)
      print_valid_list("Warning:\tInvalid OS specified",$valid_linux_os_list)
    else
      (option['service'],option['os']) = get_packer_install_service(option['file'])
    end
    exit
  else
    if !option['file'].match(/^#{$empty_value}$/)
      if option['file'].match(/purity/)
        option['os'] = "purity"
      else
        (option['service'],test_os) = get_packer_install_service(option['file'])
        if !test_os.match(/#{option['os']}/)
          handle_output("Warning:\tSpecified OS does not match installation media OS")
          handle_output("Information:\tSetting OS name to #{test_os}")
          option['os'] = test_os
        end
      end
    end
    case option['os']
    when /vsphere|esx|vmware/
      option['method'] = "vs"
    when /kickstart|redhat|rhel|fedora|sl|scientific|ks|centos/
      option['method'] = "ks"
    when /ubuntu|debian/
      option['method'] = "ps"
    when /purity/
      option['method'] = "ps"
      if option['mem'].match(/#{$default_vm_mem}/)
        $default_vm_mem  = "8192"
        option['mem']   = $default_vm_mem
        $default_vm_vcpu = "2"
        option['vcpu']      = $default_vm_vcpu
      end
    when /suse|sles/
      option['method'] = "ay"
    when /sol/
      if option['release'].to_i < 11
        option['method'] = "js"
      else
        option['method'] = "ai"
      end
    end
  end
end

# Handle install method switch

if !option['method'].match(/^#{$empty_value}$/)
  case option['method']
    when /autoinstall|ai/
    info_examples    = "ai"
    option['method'] = "ai"
  when /kickstart|redhat|rhel|fedora|sl|scientific|ks|centos/
    info_examples    = "ks"
    option['method'] = "ks"
  when /jumpstart|js/
    info_examples    = "js"
    option['method'] = "js"
  when /preseed|debian|ubuntu|purity/
    info_examples    = "ps"
    option['method'] = "ps"
  when /vsphere|esx|vmware|vs/
    info_examples    = "vs"
    option['method'] = "vs"
    if option['mem'] == $default_vm_mem
      option['mem'] = "4096"
    end
    if option['vcpu'] == $default_vm_vcpu
      option['vcpu'] = "2"
    end
    $vbox_disk_type = "ide"
  when /bsd|xb/
    info_examples    = "xb"
    option['method'] = "xb"
  when /suse|sles|yast|ay/
    info_examples    = "ay"
    option['method'] = "ay"
  end
end

# Try to determine install method if only specified OS

if option['method'].match(/^#{$empty_value}$/) and !option['action'].match(/delete|running|reboot|restart|halt|boot|stop|deploy|migrate|show|connect/)
  case option['os']
  when /sol|sunos/
    if option['release'].match(/[0-9]/)
      if option['release'] == "11"
        example_type     = "ai"
        option['method'] = "ai"
      else
        example_type     = "js"
        option['method'] = "js"
      end
    end
  when /ubuntu|debian/
    example_type     = "ps"
    option['method'] = "ps"
  when /suse|sles/
    example_type     = "ay"
    option['method'] = "ay"
  when /redhat|rhel|scientific|sl|centos|fedora|vsphere|esx/
    example_type     = "ks"
    option['method'] = "ks"
  when /bsd/
    example_type     = "xb"
    option['method'] = "xb"
  when /vmware|esx|vsphere/
    example_type     = "vs"
    option['method'] = "vs"
    configure_vmware_esxi_defaults()
  when "windows"
    example_type     = "pe"
    option['method'] = "pe"
  else
    if !option['action'].match(/list|info|check/)
      if !option['action'].match(/add|create/) and option['vm'].match(/^#{$empty_value}$/)
        print_valid_list("Warning:\tInvalid OS specified",$valid_os_list)
      end
    end
  end
end

# Handle action switch

if !option['action'].match(/^#{$empty_value}$/)
  case option['action']
  when /execute/
    if option['type'].match(/docker/)
      execute_docker_command(option['name'],option['command'])
    end
  when /screen/
    if option['vm']
      eval"[get_#{option['vm']}_vm_screen(option['name'])]"
    end
  when /vnc/
    if option['vm']
      eval"[vnc_#{option['vm']}_vm(option['name'],option['ip'])]"
    end
  when /status/
    if !option['vm'].match(/^#{$empty_value}$/)
      eval"[get_#{option['vm']}_vm_status(option['name'])]"
    end
  when /set|put/
    if option['type'].match(/acl/)
      if !option['bucket'].match(/^#{$empty_value}$/)
        set_aws_s3_bucket_acl(option['access'],option['secret'],option['region'],option['bucket'],install_email,install_grant,install_perms)
      end
    end
  when /upload|download/
    if !option['bucket'].match(/^#{$empty_value}$/)
      if option['action'].match(/upload/)
        upload_file_to_aws_bucket(option['access'],option['secret'],option['region'],option['file'],option['object'],option['bucket'])
      else
        download_file_from_aws_bucket(option['access'],option['secret'],option['region'],option['file'],option['object'],option['bucket'])
      end
    end
  when /display|view|show|prop|get|billing/
    if option['type'].match(/acl|url/) or option['action'].match(/acl|url/)
      if !option['bucket'].match(/^#{$empty_value}$/)
        show_aws_s3_bucket_acl(option['access'],option['secret'],option['region'],option['bucket'])
      else
        if option['type'].match(/url/) or option['action'].match(/url/)
          show_s3_bucket_url(option['access'],option['secret'],option['region'],option['bucket'],option['object'],option['type'])
        else
          get_aws_billing(option['access'],option['secret'],option['region'])
        end
      end
    else
      if !option['name'].match(/^#{$empty_value}$/)
        if !option['vm'].match(/^#{$empty_value}$/) and !option['vm'].match(/none/)
          eval"[show_#{option['vm']}_vm_config(option['name'])]"
        else
          get_client_config(option['name'],option['service'],option['method'],option['type'],option['vm'])
        end
      end
    end
  when /help/
    print_help()
  when /version/
    print_version()
  when /info|usage|help/
    print_examples(option['method'],option['type'],option['vm'])
  when /show/
    if !option['vm'].match(/^#{$empty_value}$/) and !option['vm'].match(/none/)
      eval"[show_#{option['vm']}_vm(option['name'])]"
    end
  when /list/
    case option['type']
    when /ssh/
      list_user_ssh_config(option['ip'],option['id'],option['name'])
    when /image|ami/
      if option['vm'].match(/docker/)
        list_docker_images(option['name'],option['id'])
      else
        list_aws_images(option['access'],option['secret'],option['region'])
      end 
    when /packer|ansible/
      eval"[list_#{option['type']}_clients(option['vm'])]"
      quit()
    when /inst/
      if option['vm'].match(/docker/)
        list_docker_instances(option['name'],option['id'])
      else
        list_aws_instances(option['access'],option['secret'],option['region'],option['id'])
      end
    when /bucket/
      list_aws_buckets(option['bucket'],option['access'],option['secret'],option['region'])
    when /object/
      list_aws_bucket_objects(option['bucket'],option['access'],option['secret'],option['region'])
    when /snapshot/
      list_aws_snapshots(option['access'],option['secret'],option['region'],option['snapshot'])
    when /key/
      list_aws_key_pairs(option['access'],option['secret'],option['region'],option['key'])
    when /stack|cloud|cf/
      list_aws_cf_stacks(option['name'],option['access'],option['secret'],option['region'])
    when /securitygroup/
      list_aws_security_groups(option['access'],option['secret'],option['region'],option['group'])
    else
      if option['vm'].match(/docker/)
        if option['type'].match(/instance/)
          list_docker_instances(option['name'],option['id'])
        else
          list_docker_images(option['name'],option['id'])
        end
        quit()
      end
      if option['type'].match(/service/) or option['mode'].match(/server/)
        if !option['method'].match(/^#{$empty_value}$/)
          eval"[list_#{option['method']}_services]"
          handle_output("")
        else
          list_all_services()
        end
        quit()
      end
      if option['type'].match(/iso/)
        if !option['method'].match(/^#{$empty_value}$/)
          eval"[list_#{option['method']}_isos]"
        else
          list_os_isos(option['os'])
        end
        quit()
      end
      if option['mode'].match(/client/) or option['type'].match(/client/)
        option['mode'] = "client"
        check_local_config(option['mode'])
        list_clients(option['service'])
        list_vms(option['vm'],option['type'])
        quit()
      end
      if !option['method'].match(/^#{$empty_value}$/) and option['vm'].match(/none/)
        eval"[list_#{option['method']}_clients()]"
        qui()
      end
      if option['type'].match(/ova/)
        list_ovas()
        quit()
      end
      if !option['vm'].match(/^#{$empty_value}$/) and !option['vm'].match(/none/)
        if option['type'].match(/snapshot/)
          list_vm_snapshots(option['vm'],option['os'],option['method'],option['name'])
        else
          list_vm(option['vm'],option['os'],option['method'])
        end
        quit()
      end
    end
  when /delete|remove|terminate/
    if option['type'].match(/ssh/)
      delete_user_ssh_config(option['ip'],option['id'],option['name'])
      quit()
    end
    if !option['name'].match(/^#{$empty_value}$/)
      if option['vm'].match(/docker/)
        delete_docker_image(option['name'],option['id'])
        quit()
      end
      if option['service'].match(/^#{$empty_value}$/) and option['vm'].match(/none/)
        if option['vm'].match(/none/)
          option['vm'] = get_client_vm_type(option['name'])
          if option['vm'].match(/vbox|fusion|parallels/)
            $use_sudo = false
            delete_vm(option['vm'],option['name'])
          else
            handle_output("Warning:\tNo VM, client or service specified")
            handle_output("")
            handle_output("Available services")
            list_all_services()
          end
        end
      else
        if option['vm'].match(/fusion|vbox|parallels|aws/)
          if option['type'].match(/packer|ansible/)
            eval"[unconfigure_#{option['type']}_client(option['name'],option['vm'])]"
          else
            if option['type'].match(/snapshot/)
              if !option['name'].match(/^#{$empty_value}$/) and !option['clone'].match(/^#{$empty_value}$/)
                delete_vm_snapshot(option['vm'],option['name'],option['clone'])
              else
                handle_output("Warning:\tClient name or clone not specified")
              end
            else
              delete_vm(option['vm'],option['name'])
            end
          end
        else
          if option['vm'].match(/ldom|gdom/)
            unconfigure_gdom(option['name'])
          else
            set_local_config()
            remove_hosts_entry(option['name'],option['ip'])
            remove_dhcp_client(option['name'])
            if option['yes'] == true
              delete_client_dir(option['name'])
            end
          end
        end
      end
    else
      if option['type'].match(/instance|snapshot|key|stack|cf|cloud|securitygroup|iprule|sg|ami|image/) or option['id'].match(/[0-9]|all/)
        case option['type']
        when /instance/
          delete_aws_vm(option['access'],option['secret'],option['region'],option['ami'],option['id'])
        when /ami|image/
          if option['vm'].match(/docker/)
            delete_docker_image(option['name'],option['id'])
          else
            delete_aws_image(option['access'],option['secret'],option['region'],option['ami'])
          end
        when /snapshot/
          delete_aws_snapshot(option['access'],option['secret'],option['region'],option['snapshot'])
        when /key/
          delete_aws_key_pair(option['access'],option['secret'],option['region'],option['key'])
        when /stack|cf|cloud/
          delete_aws_cf_stack(option['access'],option['secret'],option['region'],option['stack'])
        when /securitygroup/
          delete_aws_security_group(option['access'],option['secret'],option['region'],option['group'])
        when /iprule/
          if option['ports'].match(/[0-9]/)
            if option['ports'].match(/\./)
              ports = []
              option['ports'].split(/\./).each do |port|
                ports.push(port)
              end
              ports = ports.uniq
            else
              port  = option['ports']
              ports = [ port ]
            end
            ports.each do |port|
              option['from'] = port
              option['to']   = port
              remove_rule_from_aws_security_group(option['access'],option['secret'],option['region'],option['group'],option['proto'],option['to'],option['from'],option['cidr'],option['dir'],option['service'])
            end
          else
            remove_rule_from_aws_security_group(option['access'],option['secret'],option['region'],option['group'],option['proto'],option['to'],option['from'],option['cidr'],option['dir'],option['service'])
          end
        else
          if !option['ami'].match(/^#{$empty_value}$/)
            delete_aws_image(option['ami'],option['access'],option['secret'],option['region'])
          else
            handle_output("Warning:\tNo #{option['vm']} type, instance or image specified")
          end
        end
        quit()
      end
      if option['type'].match(/packer|docker/)
        eval"[unconfigure_#{option['type']}_client(option['name'])]"
      else
        if !option['service'].match(/^#{$empty_value}$/)
          if option['method'].match(/^#{$empty_value}$/)
            unconfigure_server(option['service'])
          else
            eval"[unconfigure_#{option['method']}_server(option['service'])]"
          end
        end
      end
    end
  when /build/
    if option['type'].match(/packer/)
      if option['vm'].match(/aws/)
        build_packer_aws_config(option['name'],option['access'],option['secret'],option['region'])
      else
        build_packer_config(option['name'],option['vm'])
      end
    end
    if option['type'].match(/ansible/)
      if option['vm'].match(/aws/)
        build_ansible_aws_config(option['name'],option['access'],option['secret'],option['region'])
      else
        build_ansible_config(option['name'],option['vm'])
      end
    end
  when /add|create/
    if option['type'].match(/ami|image|key|cloud|cf|stack|securitygroup|iprule|sg/)
      case option['type']
      when /ami|image/
        create_aws_image(option['name'],option['access'],option['secret'],option['region'],option['id'])
      when /key/
        create_aws_key_pair(option['access'],option['secret'],option['region'],option['key'])
      when /cf|cloud|stack/
        configure_aws_cf_stack(option['name'],option['ami'],option['region'],option['size'],option['access'],option['secret'],option['type'],option['number'],option['key'],option['keyfile'],option['file'],option['group'],option['bucket'],option['object'])
      when /securitygroup/
        create_aws_security_group(option['access'],option['secret'],option['region'],option['group'],option['desc'],option['dir'])
      when /iprule/
        if option['ports'].match(/[0-9]/)
          if option['ports'].match(/\./)
            ports = []
            option['ports'].split(/\./).each do |port|
              ports.push(port)
            end
            ports = ports.uniq
          else
            port  = option['ports']
            ports = [ port ]
          end
          ports.each do |port|
            option['from'] = port
            option['to']   = port
            add_rule_to_aws_security_group(option['access'],option['secret'],option['region'],option['group'],option['proto'],option['to'],option['from'],option['cidr'],option['dir'],option['service'])
          end
        else
          add_rule_to_aws_security_group(option['access'],option['secret'],option['region'],option['group'],option['proto'],option['to'],option['from'],option['cidr'],option['dir'],option['service'])
        end
      end
      quit()
    end
    if option['vm'].match(/aws/)
      case option['type']
      when /packer/
        configure_packer_aws_client(option['name'],option['type'],option['ami'],option['region'],option['size'],option['access'],option['secret'],option['number'],option['key'],option['keyfile'],option['group'],option['desc'],option['ports'])
      when /ansible/
        configure_ansible_aws_client(option['name'],option['type'],option['ami'],option['region'],option['size'],option['access'],option['secret'],option['number'],option['key'],option['keyfile'],option['group'],option['desc'],option['ports'])
      else
        if option['key'].match(/^#{$empty_value}$/) and option['group'].match(/^#{$empty_value}$/)
          handle_output("Warning:\tNo Key Pair or Security Group specified")
          quit()
        else
          configure_aws_client(option['name'],option['type'],option['ami'],option['region'],option['size'],option['access'],option['secret'],option['number'],option['key'],option['keyfile'],option['group'],option['desc'],option['ports'])
        end
      end
      quit()
    end
    if option['type'].match(/docker/)
      configure_docker_client(option['vm'],option['name'],option['ip'],option['network'])
      quit()
    end
    if option['vm'].match(/none/) and option['method'].match(/^#{$empty_value}$/) and option['type'].match(/^#{$empty_value}$/) and !option['mode'].match(/server/)
      handle_output("Warning:\tNo VM, Method or specified")
    end
    if option['mode'].match(/server/) or !option['file'].match(/^#{$empty_value}$/) or option['type'].match(/service/) and option['vm'].match(/none/) and !option['type'].match(/packer/) and !option['service'].match(/packer/)
      check_local_config("server")
      eval"[configure_server(option['method'],option['arch'],option['publisherhost'],option['publisherport'],option['service'],option['file'])]"
    else
      if option['vm'].match(/fusion|vbox/)
        check_vm_network(option['vm'],option['mode'],option['network'])
      end
      if !option['name'].match(/^#{$empty_value}$/)
        if !option['service'].match(/^#{$empty_value}$/) or option['type'].match(/packer/)
          if option['method'].match(/^#{$empty_value}$/)
            option['method'] = get_install_method(option['name'],option['service'])
          end
          if !option['type'].match(/packer/) and option['vm'].match(/none/)
            check_dhcpd_config(option['publisherhost'])
          end
          if !option['network'].match(/nat/)
            check_install_ip(option['ip'])
            check_install_mac(option['mac'],option['vm'])
          end
          if option['type'].match(/packer/)
            if $yes_to_all == true
              if option['vm'].match(/none/)
                option['vm'] = get_client_vm_type(option['name'])
                if option['vm'].match(/vbox|fusion|parallels/)
                  $use_sudo = false
                  delete_vm(option['vm'],option['name'])
                  eval"[unconfigure_#{option['type']}_client(option['name'],option['vm'])]"
                end
              else
                $use_sudo = false
                delete_vm(option['vm'],option['name'])
                eval"[unconfigure_#{option['type']}_client(option['name'],option['vm'])]"
              end
            end
            eval"[configure_#{option['type']}_client(option['method'],option['vm'],option['os'],option['name'],option['arch'],option['mac'],option['ip'],option['model'],
                              option['publisherhost'],option['service'],option['file'],option['mem'],option['vcpu'],option['network'],option['license'],option['mirror'],
                              option['size'],option['type'],option['locale'],option['label'],option['timezone'],option['shell'])]"
          else
            if option['vm'].match(/none/)
              if option['method'].match(/^#{$empty_value}$/)
                if option['ip'].match(/[0-9]/)
                  check_local_config("client")
                  add_hosts_entry(option['name'],option['ip'])
                end
                if option['mac'].match(/[0-9]|[a-f]|[A-F]/)
                  option['service'] = ""
                  add_dhcp_client(option['name'],option['mac'],option['ip'],option['arch'],option['service'])
                end
              else
                if option['model'].match(/^#{$empty_value}$/)
                  option['model']       = "vmware"
                  $default_slice_size = "4192"
                end
                check_local_config("server")
                if !option['mac'].match(/[0-9]/)
                  option['mac'] = generate_mac_address(option['vm'])
                end
                eval"[configure_#{option['method']}_client(option['name'],option['arch'],option['mac'],option['ip'],option['model'],option['publisherhost'],
                                  option['service'],option['file'],option['mem'],option['vcpu'],option['network'],option['license'],option['mirror'],option['type'],option['vm'])]"
              end
            else
              if option['vm'].match(/fusion|vbox|parallels/)
                create_vm(option['method'],option['vm'],option['name'],option['mac'],option['os'],option['arch'],option['release'],option['size'],option['file'],option['mem'],option['vcpu'],option['network'],option['share'],option['mount'],option['ip'])
              end
              if option['vm'].match(/zone|lxc|gdom/)
                eval"[configure_#{option['vm']}(option['name'],option['ip'],option['mac'],option['arch'],option['os'],option['release'],option['publisherhost'],
                                              option['file'],option['service'])]"
              end
              if option['vm'].match(/cdom/)
                configure_cdom(option['publisherhost'])
              end
            end
          end
        else
          if option['vm'].match(/fusion|vbox|parallels/)
            create_vm(option['method'],option['vm'],option['name'],option['mac'],option['os'],option['arch'],option['release'],option['size'],option['file'],option['mem'],option['vcpu'],option['network'],option['share'],option['mount'],option['ip'])
          end
          if option['vm'].match(/zone|lxc|gdom/)
            eval"[configure_#{option['vm']}(option['name'],option['ip'],option['mac'],option['arch'],option['os'],option['release'],option['publisherhost'],
                                          option['file'],option['service'])]"
          end
          if option['vm'].match(/cdom/)
            configure_cdom(option['publisherhost'])
          end
          if option['vm'].match(/none/)
            if option['ip'].match(/[0-9]/)
              check_local_config("client")
              add_hosts_entry(option['name'],option['ip'])
            end
            if option['mac'].match(/[0-9]|[a-f]|[A-F]/)
              option['service'] = ""
              add_dhcp_client(option['name'],option['mac'],option['ip'],option['arch'],option['service'])
            end
          end
        end
      else
        if option['mode'].match(/server/)
          if option['method'].match(/ai/)
            configure_ai_server(client_arch,option['publisherhost'],option['publisherport'],service_name,option['file'])
          else
            handle_output("Warning:\tNo install method specified")
          end
        else
          handle_output("Warning:\tClient or service name not specified")
        end
      end
    end
  when /^boot$|^stop$|^halt$|^suspend$|^resume$|^start$/
    option['mode']   = "client"
    option['action'] = option['action'].gsub(/start/,"boot")
    option['action'] = option['action'].gsub(/halt/,"stop")
    if option['vm'].match(/aws/)
      eval"[#{option['action']}_#{option['vm']}_vm(option['access'],option['secret'],option['region'],option['ami'],option['id'])]"
      quit()
    end
    if !option['name'].match(/^#{$empty_value}$/) and !option['vm'].match(/^#{$empty_value}$/) and !option['vm'].match(/none/)
      if option['action'].match(/boot/)
        eval"[#{option['action']}_#{option['vm']}_vm(option['name'],option['type'])]"
      else
        eval"[#{option['action']}_#{option['vm']}_vm(option['name'])]"
      end
    else
      if !option['name'].match(/^#{$empty_value}$/) and option['vm'].match(/none/)
        option['vm'] = get_client_vm_type(option['name'])
        check_local_config(option['mode'])
        if option['vm'].match(/vbox|fusion|parallels/)
          $use_sudo = false
        end
        if !option['vm'].match(/^#{$empty_value}$/) and !option['vm'].match(/none/)
          if option['action'].match(/boot/)
            eval"[#{option['action']}_#{option['vm']}_vm(option['name'],option['type'])]"
          else
            eval"[#{option['action']}_#{option['vm']}_vm(option['name'])]"
          end
        else
          print_valid_list("Warning:\tInvalid VM type",$valid_vm_list)
        end
      else
        if option['name'].match(/^#{$empty_value}$/)
          handle_output("Warning:\tClient name not specified")
        end
      end
    end
  when /restart|reboot/
    if !option['service'].match(/^#{$empty_value}$/)
      eval"[restart_#{option['service']}()]"
    else
      if option['vm'].match(/none/) and !option['name'].match(/^#{$empty_value}$/)
        option['vm'] = get_client_vm_type(option['name'])
      end
      if option['vm'].match(/aws/)
        reboot_aws_vm(option['access'],option['secret'],option['region'],option['ami'],option['id'])
        quit()
      end
      if !option['vm'].match(/^#{$empty_value}$/) and !option['vm'].match(/none/)
        if !option['name'].match(/^#{$empty_value}$/)
          eval"[stop_#{option['vm']}_vm(option['name'])]"
          eval"[boot_#{option['vm']}_vm(option['name'],option['type'])]"
        else
          handle_output("Warning:\tClient name not specified")
        end
      else
        handle_output("Warning:\tInstall service or VM type not specified")
      end
    end
  when /import/
    if option['file'].match(/^#{$empty_value}$/)
      if option['type'].match(/packer/)
        eval"[import_packer_#{option['vm']}_vm(option['name'],option['vm'])]"
      end
    else
      if option['vm'].match(/fusion|vbox/)
        if option['file'].match(/ova/)
          set_ovftool_bin()
          eval"[import_#{option['vm']}_ova(option['name'],option['mac'],option['ip'],option['file'])]"
        else
          if option['file'].match(/vmdk/)
            eval"[import_#{option['vm']}_vmdk(option['method'],option['vm'],option['name'],option['mac'],option['os'],option['arch'],option['release'],option['size'],option['file'],option['mem'],option['vcpu'],option['network'],option['share'],option['mount'],option['ip'])]"
          end
        end
      end
    end
  when /export/
    if option['vm'].match(/fusion|vbox/)
      eval"[export_#{option['vm']}_ova(option['name'],option['file'])]"
    end
    if option['vm'].match(/aws/)
      export_aws_image(option['access'],option['secret'],option['region'],option['ami'],option['id'],option['prefix'],option['bucket'],option['container'],option['comment'],option['target'],install_format,install_acl)
    end
  when /clone|copy/
    if !option['clone'].match(/^#{$empty_value}$/) and !option['name'].match(/^#{$empty_value}$/)
      eval"[clone_#{option['vm']}_vm(option['name'],option['clone'],option['mac'],option['ip'])]"
    else
      handle_output("Warning:\tClient name or clone name not specified")
    end
  when /running|stopped|suspended|paused/
    if !option['vm'].match(/^#{$empty_value}$/) and !option['vm'].match(/none/)
      eval"[list_#{option['action']}_#{option['vm']}_vms]"
    end
  when /crypt/
    option['crypt'] = get_password_crypt(option['rootpassword'])
    handle_output(option['crypt'])
  when /post/
    eval"[execute_#{option['vm']}_post(option['name'])]"
  when /change|modify/
    if !option['name'].match(/^#{$empty_value}$/)
      if option['mem'].match(/[0-9]/)
        eval"[change_#{option['vm']}_vm_mem(option['name'],option['mem'])]"
      end
      if option['mac'].match(/[0-9]|[a-f]|[A-F]/)
        eval"[change_#{option['vm']}_vm_mac(option['name'],client_mac)]"
      end
    else
      handle_output("Warning:\tClient name not specified")
    end
  when /attach/
    if !option['vm'].match(/^#{$empty_value}$/) and !option['vm'].match(/none/)
      eval"[attach_file_to_#{option['vm']}_vm(option['name'],option['file'],option['type'])]"
    end
  when /detach/
    if !option['vm'].match(/^#{$empty_value}$/) and !option['name'].match(/^#{$empty_value}$/) and !option['vm'].match(/none/)
      eval"[detach_file_from_#{option['vm']}_vm(option['name'],option['file'],option['type'])]"
    else
      handle_output("Warning:\tClient name or virtualisation platform not specified")
    end
  when /share/
    if !option['vm'].match(/^#{$empty_value}$/) and !option['vm'].match(/none/)
      eval"[add_shared_folder_to_#{option['vm']}_vm(option['name'],option['share'],option['mount'])]"
    end
  when /^snapshot|clone/
    if !option['vm'].match(/^#{$empty_value}$/) and !option['vm'].match(/none/)
      if !option['name'].match(/^#{$empty_value}$/)
        eval"[snapshot_#{option['vm']}_vm(option['name'],option['clone'])]"
      else
        handle_output("Warning:\tClient name not specified")
      end
    end
  when /migrate/
    eval"[migrate_#{option['vm']}_vm(option['name'],option['server'],option['serveradmin'],option['serverpassword'],option['servernetwork'],option['datastore'])]"
  when /deploy/
    if option['type'].match(/vcsa/)
      set_ovftool_bin()
      option['file'] = handle_vcsa_ova(option['file'],option['service'])
      deploy_vcsa_vm(option['server'],option['datastore'],option['serveradmin'],option['serverpassword'],option['servernetwork'],option['name'],
                     option['size'],option['rootpassword'],option['timeserver'],option['adminpassword'],option['domainname'],option['sitename'],
                     option['ipfamily'],option['mode'],option['ip'],option['netmask'],option['gateway'],option['nameserver'],option['service'],option['file'])
    else
      eval"[deploy_#{option['vm']}_vm(option['server'],option['datastore'],option['serveradmin'],option['serverpassword'],option['servernetwork'],option['name'],
                                    option['size'],option['rootpassword'],option['timeserver'],option['adminpassword'],option['domainname'],option['sitename'],
                                    option['ipfamily'],option['mode'],option['ip'],option['netmask'],option['gateway'],option['nameserver'],option['service'],option['file'])]"
    end
  when /restore|revert/
    if !option['vm'].match(/^#{$empty_value}$/) and !option['vm'].match(/none/)
      if !option['name'].match(/^#{$empty_value}$/)
        eval"[restore_#{option['vm']}_vm_snapshot(option['name'],option['clone'])]"
      else
        handle_output("Warning:\tClient name not specified")
      end
    end
  when /set/
    if !option['vm'].match(/^#{$empty_value}$/)
      eval"[set_#{option['vm']}_value(option['name'],option['param'],option['value'])]"
    end
  when /get/
    if !option['vm'].match(/^#{$empty_value}$/)
      eval"[get_#{option['vm']}_value(option['name'],option['param'])]"
    end
  when /console|serial|connect|ssh/
    if option['vm'].match(/aws/) or option['id'].match(/[0-9]/)
      connect_to_aws_vm(option['access'],option['secret'],option['region'],option['name'],option['id'],option['ip'],option['key'],option['keyfile'],option['admin'])
      quit()
    end
    if option['type'].match(/docker/)
      connect_to_docker_client(option['name'])
    end
    if !option['vm'].match(/^#{$empty_value}$/) and !option['vm'].match(/none/)
      if !option['name'].match(/^#{$empty_value}$/)
        connect_to_virtual_serial(option['name'],option['vm'])
      else
        handle_output("Warning:\tClient name not specified")
      end
    end
  when /check/
    if option['mode'].match(/server/)
      check_local_config(option['mode'])
    end
    if option['mode'].match(/osx/)
      check_osx_dnsmasq()
      check_osx_tftpd()
      check_osx_dhcpd()
      if $default_options.match(/puppet/)
        check_osx_puppet()
      end
    end
    if option['vm'].match(/fusion|vbox/)
      check_vm_network(option['vm'],option['mode'],option['network'])
    end
  else
    handle_output("Warning:\tAction #{option['method']}")
  end
end

quit()
