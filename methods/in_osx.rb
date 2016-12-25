# Common OS X routines

# Get OSX default rotute interface

def get_osx_gw_if_name()
  message    = "Information:\tGetting interface name of default router"
  command    = "sudo sh -c \"netstat -rn |grep ^default |head -1 |awk '{print \\\$6}'\""
  gw_if_name = execute_command(message,command)
  gw_if_name = gw_if_name.chomp
  return gw_if_name
end

# Get OSX interface name for VM networks

def get_osx_vm_if_name(install_vm)
  case install_vm
  when /parallels/
    if_name = "prlsnet0"
  when /virtualbox|vbox/
    if_name = "vboxnet0"
  when /vmware|fusion/
    if_name = "vmnet1"
  end
  return if_name
end

# Check IP forwarding is enabled

def check_osx_ip_forwarding(gw_if_name)
  message = "Information:\tChecking IP forwarding is enabled"
  command = "sudo sh -c \"sysctl -a net.inet.ip.forwarding |awk '{print \\\$2}'\""
  output  = execute_command(message,command)
  output  = output.chomp.to_i
  if output == 0
    message = "Information:\tEnabling IP forwarding"
    command = "sudo sh -c \"sysctl net.inet.ip.forwarding=1\""
    execute_command(message,command)
  end
  message = "Information:\tChecking rule for IP forwarding has been created"
  if $os_rel.split(/\./)[0].to_i > 13
    command = "sudo sh -c \"pfctl -a '*' -sr 2>&1 |grep 'pass quick on #{gw_if_name}'\""
  else
    command = "sudo sh -c \"ipfw list |grep 'any to any via #{gw_if_name}'\""
  end
  output  = execute_command(message,command)
  return output
end

# Check PF is configure on OS X 10.10

def check_osx_pfctl(gw_if_name,if_name)
  output = check_osx_ip_forwarding(gw_if_name)
  if !output.match(/pass quick on #{gw_if_name}|any to any via #{gw_if_name}/)
    pf_file = $work_dir+"/pfctl_config"
    if File.exist?(pf_file)
      File.delete(pf_file)
    end
    output = File.open(pf_file,"w")
    if $verbose_mode == true
      handle_output("Information:\tEnabling forwarding between #{gw_if_name} and #{if_name}")
    end
    output.write("nat on #{gw_if_name} from #{if_name}:network to any -> (#{gw_if_name})\n")
    output.write("pass inet proto icmp all\n")
    output.write("pass in on #{if_name} proto udp from any to any port domain keep state\n")
    output.write("pass in on #{if_name} proto tcp from any to any port domain keep state\n")
    output.write("pass quick on #{gw_if_name} proto udp from any to any port domain keep state\n")
    output.write("pass quick on #{gw_if_name} proto tcp from any to any port domain keep state\n")
    output.close
    message = "Enabling:\tPacket filtering"
    command = "sudo sh -c \"pfctl -e\""
    execute_command(message,command)
    message = "Loading:\yFilters from "+pf_file
    command = "sudo sh -c \"pfctl -F all -f #{pf_file}\""
    execute_command(message,command)
  end
  return
end

# check NATd is running and configured on OS X 10.9 and earlier
# Useful info on pfctl here http://patrik-en.blogspot.com.au/2009/10/nat-in-virtualbox-with-freebsd-and-pf.html

def check_osx_nat(gw_if_name,if_name)
  output = check_osx_ip_forwarding(gw_if_name)
  if !output.match(/#{gw_if_name}/)
    message = "Information:\tEnabling NATd to forward traffic on "+gw_if_name
    if $os_rel.split(".")[0].to_i < 14
      command = "sudo sh -c \"ipfw add 100 divert natd ip from any to any via #{gw_if_name}\""
      execute_command(message,command)
    else
      check_osx_pfctl(gw_if_name,if_name)
    end
  end
  if $os_rel.split(/\./)[0].to_i < 13
    message = "Information:\tChecking NATd is running"
    command = "ps -ef |grep '#{gw_if_name}' |grep natd |grep 'same_ports'"
    output  = execute_command(message,command)
    if !output.match(/natd/)
      message = "Information:\tStarting NATd to foward packets between "+if_name+" and "+gw_if_name
      command = "sudo sh -c \"/usr/sbin/natd -interface #{gw_if_name} -use_sockets -same_ports -unregistered_only -dynamic -clamp_mss -enable_natportmap -natportmap_interface #{if_name}\""
      execute_command(message,command)
    end
  end
  return
end

# Tune OS X NFS

def tune_osx_nfs()
  nfs_file   = "/etc/nfs.conf"
  nfs_params = ["nfs.server.nfsd_threads = 64","nfs.server.reqcache_size = 1024","nfs.server.tcp = 1","nfs.server.udp = 0","nfs.server.fsevents = 0"]
  nfs_params.each do |nfs_tune|
    nfs_tune = "nfs.client.nfsiod_thread_max = 64"
    message  = "Information:\tChecking NFS tuning"
    command  = "cat #{nfs_file} |grep '#{nfs_tune}'"
    output   = execute_command(message,command)
    if !output.match(/#{nfs_tune}/)
      backup_file(nfs_file)
      message = "Information:\tTuning NFS"
      command = "echo '#{nfs_tune}' >> #{nfs_file}"
      execute_command(message,command)
    end
  end
  return
end

# Get Mac disk name

def get_osx_disk_name()
  message = "Information:\tGetting root disk device ID"
  command = "df |grep '/$' |awk '{print \\$1}'"
  output  = execute_command(message,command)
  disk_id = output.chomp
  message = "Information:\tGetting volume name for "+disk_id
  command = "diskutil info #{disk_id} | grep 'Volume Name' |cut -f2 -d':'"
  output  = execute_command(message,command)
  volume  = output.chomp.gsub(/^\s+/,"")
  return volume
end

# Check OSX Puppet install

def check_osx_puppet_install()
  pkg_list = {}
  use_rvm  = 0
  pkg_list["facter"] = $facter_version
  pkg_list["hiera"]  = $hiera_version
  pkg_list["puppet"] = $puppet_version
  base_url  = "http://downloads.puppetlabs.com/mac/"
  local_dir = $work_dir+"/dmg"
  check_dir_exists(local_dir)
  pkg_list.each do |key, value|
    test_file = "/usr/bin/"+key
    if !File.exist?(test_file)
      file_name   = key+"-"+value
      dmg_name    = file_name+".dmg"
      local_pkg   = key+"-"+value+".pkg"
      remote_file = base_url+"/"+dmg_name
      local_file  = local_dir+"/"+dmg_name
      if !File.exist?(local_file)
        wget_file(remote_file,local_file)
      end
      message = "Information:\tMounting disk image "+local_file
      command = "hdiutil mount #{local_file}"
      execute_command(message,command)
      local_pkg = "/Volumes/"+file_name+"/"+local_pkg
      volume    = get_osx_disk_name()
      volume    = "/Volumes/"+volume
      message   = "Information:\tInstalling package "+local_pkg
      command   = "installer -package #{local_pkg} -target '#{volume}'"
      execute_command(message,command)
      if key.match(/puppet/)
        message = "Information:\tChecking Ruby version"
        command = "which ruby"
        output  = execute_command(message,command)
        if output.match(/rvm/)
          use_rvm  = 1
          message  = "Information:\tStoring RVM Ruby version"
          command  = "rvm current"
          output   = execute_command(message,command)
          rvm_ruby = output.chomp
          message  = "Information:\tSetting RVM to use system ruby"
          command  = "rvm use system"
          execute_command(message,command)
        end
        message = "Information:\tCreating Puppet group"
        command = "puppet resource group puppet ensure=present"
        execute_command(message,command)
        message = "Information:\tCreating Puppet user"
        command = "puppet resource user puppet ensure=present gid=puppet shell='/sbin/nologin'"
        execute_command(message,command)
        etc_dir = "/etc/puppet"
        check_dir_exists(etc_dir)
        message = "Information:\tCreating Puppet directory"
        command = "mkdir -p /var/lib/puppet ; mkdir -p /etc/puppet/manifests ; mkdir -p /etc/puppet/ssl"
        execute_command(message,command)
        message = "Information:\tFixing Puppet permissions"
        command = "chown -R puppet:puppet  /var/lib/puppet ; chown -R puppet:puppet  /etc/puppet"
        execute_command(message,command)
        if use_rvm == 1
          message = "Information:\tReverting RVM to use "+rvm_ruby
          command = "rvm use rvm_ruby"
          execute_command(message,command)
        end
      end
      local_vol = "/Volumes/"+key+"-"+value
      message   = "Unmounting:\t"+local_vol
      command   = "umount "+local_vol
      execute_command(message,command)
    end
  end

  return
end

# Create OS X Puppet agent plist file

def create_osx_puppet_agent_plist()
  xml_output = []
  plist_file = "/Library/LaunchDaemons/com.puppetlabs.puppet.plist"
  tmp_file   = "/tmp/puppet.plist"
  plist_name = "com.puppetlabs.puppet"
  puppet_bin = "/usr/bin/puppet"
  message    = "Checking:\tPuppet configruation"
  command    = "cat #{plist_file} | grep 'agent'"
  output     = execute_command(message,command)
  if !output.match(/#{$default_net}/)
    xml = Builder::XmlMarkup.new(:target => xml_output, :indent => 2)
    xml.instruct! :xml, :version => "1.0", :encoding => "UTF-8"
    xml.declare! :DOCTYPE, :plist, :PUBLIC, :'"-//Apple Computer//DTD PLIST 1.0//EN"', :'"http://www.apple.com/DTDs/PropertyList-1.0.dtd"'
    xml.plist(:version => "1.0") {
      xml.dict {
        xml.key("EnvironmentVariables")
        xml.dict {
          xml.key("PATH")
          xml.string("/sbin:/usr/sbin:/bin:/usr/bin")
          xml.key("RUBYLIB")
          xml.string("/usr/lib/ruby/site_ruby/1.8/")
        }
        xml.key("label")
        xml.string(plist_name)
        xml.key("OnDemand") ; xml.false
        xml.key("ProgramArguments")
        xml.array {
          xml.string(puppet_bin)
          xml.string("agent")
          xml.string("--verbose")
          xml.string("--no-daemonize")
          xml.string("--log-dest")
          xml.string("console")
        }
      }
      xml.key("RunAtLoad") ; xml.true
      xml.key("ServiceIPC") ; xml.false
      xml.key("StandardErrorPath")
      xml.string("/var/log/puppet/puppet.err")
      xml.key("StandardOutPath")
      xml.string("/var/log/puppet/puppet.out")
    }
    file=File.open(tmp_file,"w")
    xml_output.each do |item|
      file.write(item)
    end
    file.close
    message = "Information:\tCreating service file "+plist_file
    command = "cp #{tmp_file} #{plist_file} ; rm #{tmp_file} ; chown root:wheel #{plist_file} ; chmod 644 #{plist_file}"
    execute_command(message,command)
  end
  return
end

# Create OS X Puppet master plist file

def create_osx_puppet_master_plist()
  xml_output = []
  plist_file = "/Library/LaunchDaemons/com.puppetlabs.puppetmaster.plist"
  tmp_file   = "/tmp/puppetmaster.plist"
  plist_name = "com.puppetlabs.puppetmaster"
  puppet_bin = "/usr/bin/puppet"
  message    = "Checking:\tPuppet configruation"
  command    = "cat #{plist_file} | grep 'master'"
  output     = execute_command(message,command)
  if !output.match(/#{$default_net}/)
    xml = Builder::XmlMarkup.new(:target => xml_output, :indent => 2)
    xml.instruct! :xml, :version => "1.0", :encoding => "UTF-8"
    xml.declare! :DOCTYPE, :plist, :PUBLIC, :'"-//Apple Computer//DTD PLIST 1.0//EN"', :'"http://www.apple.com/DTDs/PropertyList-1.0.dtd"'
    xml.plist(:version => "1.0") {
      xml.dict {
        xml.key("EnvironmentVariables")
        xml.dict {
          xml.key("PATH")
          xml.string("/sbin:/usr/sbin:/bin:/usr/bin")
          xml.key("RUBYLIB")
          xml.string("/usr/lib/ruby/site_ruby/1.8/")
        }
        xml.key("label")
        xml.string(plist_name)
        xml.key("ProgramArguments")
        xml.array {
          xml.string(puppet_bin)
          xml.string("master")
          xml.string("--verbose")
          xml.string("--no-daemonize")
        }
      }
      xml.key("RunAtLoad") ; xml.true
      xml.key("ServiceIPC") ; xml.false
      xml.key("StandardErrorPath")
      xml.string("/var/log/puppet/puppetmaster.err")
      xml.key("StandardOutPath")
      xml.string("/var/log/puppet/puppetmaster.out")
    }
    file=File.open(tmp_file,"w")
    xml_output.each do |item|
      file.write(item)
    end
    file.close
    message = "Information:\tCreating service file "+plist_file
    command = "cp #{tmp_file} #{plist_file} ; rm #{tmp_file} ; chown root:wheel #{plist_file} ; chmod 644 #{plist_file}"
    execute_command(message,command)
  end
  return
end

# Create OS X Puppet Agent plist

def create_osx_puppet_plist()
  return
end

# Create OS X Puppet Master plist

def create_osx_puppet_master_plist()
  return
end

# Check OX X Puppet plist

def check_osx_puppet_plist()
  plist_file = "/Library/LaunchDaemons/com.puppetlabs.puppet.plist"
  plist_name = "com.puppetlabs.puppet"
  if !File.exist?(plist_file)
    create_osx_puppet_plist()
    message = "Information:\tLoading Puppet Agent plist file "+plist_file
    command = "launchctl load -w #{plist_file}"
    execute_command(message,command)
    message = "Information:\tStarting Puppet Agent "+plist_name
    command = "launchctl start #{plist_name}"
    execute_command(message,command)
  end
  plist_file = "/Library/LaunchDaemons/com.puppetlabs.puppetmaster.plist"
  plist_name = "com.puppetlabs.puppetmaster"
  if !File.exist?(plist_file)
    create_osx_puppet_master_plist()
    message = "Information:\tLoading Puppet Master plist file "+plist_file
    command = "launchctl load -w #{plist_file}"
    execute_command(message,command)
    message = "Information:\tStarting Puppet Master "+plist_name
    command = "launchctl start #{plist_name}"
    execute_command(message,command)
  end
  return
end

# Check OS X apache config

def check_osx_apache()
  ssl_dir = "/private/etc/apache2/ssl"
  check_dir_exists(ssl_dir)
  server_key = ssl_dir+"/server.key"
  if !File.exist?(server_key)
    message = "information:\tGenerating Apache SSL Server Key "+server_key
    command = "ssh-keygen -f #{server_key}"
    execute_command(message,command)
  end
  return
end

# Create OS X Puppet config

def create_osx_puppet_config()
  tmp_file    = "/tmp/puppet_config"
  puppet_file = "/etc/puppet/puppet.conf"
  if !File.exist?(puppet_file)
    config = []
    config.push("[main]")
    config.push("pluginsync = true")
    config.push("server = #{$default_host}")
    config.push("")
    config.push("[master]")
    config.push("vardir = /var/lib/puppet")
    config.push("libdir = $vardir/lib")
    config.push("ssldir = /etc/puppet/ssl")
    config.push("certname = #{$default_host}")
    config.push("")
    config.push("[agent]")
    config.push("vardir = /var/lib/puppet")
    config.push("libdir = $vardir/lib")
    config.push("ssldir = /etc/puppet/ssl")
    config.push("certname = #{$default_host}")
    config.push("")
    file = File.open(tmp_file,"w")
    config.each do |line|
      output = line+"\n"
      file.write(output)
    end
    file.close
    message = "Information:\tCreating Puppet configuration file "+puppet_file
    command = "cp #{tmp_file} #{puppet_file} ; rm #{tmp_file}"
    execute_command(message,command)
    print_contents_of_file("",puppet_file)
  end
  return
end

# Create OS X Puppet config

def create_osx_puppet_config()
  return
end

# Check OS X Puppet

def check_osx_puppet()
  check_osx_puppet_install()
  check_osx_puppet_plist()
  create_osx_puppet_config()
  return
end

# Check OS X IPS

def check_osx_ips()
  python_bin = "/usr/bin/python"
  pip_bin    = "/usr/bin/pip"
  setup_url  = "https://bitbucket.org/pypa/setuptools/raw/bootstrap/ez_setup.py"
  if !File.symlink?(pip_bin)
    message = "Information:\tInstalling Pip"
    command = "/usr/bin/easy_install --prefix=/usr pip"
    execute_command(message,command)
    message = "Information:\tUpdating Setuptools"
    command = "wget #{setup_url} -O |sudo #{python_bin}"
    execute_command(message,command)
    ["simplejson","coverage","pyOpenSSL","mercurial"].each do |module_name|
      message = "information:\tInstalling Python module "+module_name
      command = "#{pip_bin} install #{module_name}"
      execute_command(message,command)
    end
  end
  python_ver = %x[#{python_bin} --version |awk '{print $2}']
  python_ver = python_ver.chomp.split(/\./)[0..1].join(".")
  module_dir = "/usr/local/lin/python"+python_ver+"/site-packages"
  pkg_dest_dir = module_dir+"/pkg"
  check_dir_exists(pkg_dest_dir)
  hg_bin = "/usr/local/bin/hg"
  if !File.exist?(hg_bin)
    message = "Information:\tInstalling Mercurial"
    command = "brew install mercurial"
    execute_command(message,command)
  end
  pkgrepo_bin = "/usr/local/bin/pkgrepo"
  if !File.exist?(pkgrepo_bin)
    ips_url = "https://hg.java.net/hg/ips~pkg-gate"
    message = "Information:\tDownloading IPS source code"
    command = "cd #{$work_dir} ; hg clone #{ips_url} ips"
    execute_command(message,command)
  end
  return
end

# Check OSX service is enabled

def check_osx_service_is_enabled(service)
  service     = get_service_name(service)
  plist_file  = "/Library/LaunchDaemons/"+service+".plist"
  if !File.exist?(plist_file)
    plist_file = "/System"+plist_file
  end
  if !File.exist?(plist_file)
    handle_output("Warning:\tLaunch Agent not found for #{service}")
    exit
  end
  tmp_file  = "/tmp/tmp.plist"
  message   = "Information:\tChecking service "+service+" is enabled"
  if service.match(/dhcp/)
    command   = "cat #{plist_file} | grep Disabled |grep true"
  else
    command   = "cat #{plist_file} | grep -C1 Disabled |grep true"
  end
  output    = execute_command(message,command)
  if !output.match(/true/)
    if $verbose_mode == true
      handle_output("Information:\t#{service} enabled")
    end
  else
    backup_file(plist_file)
    copy      = []
    check     = 0
    file_info = IO.readlines(plist_file)
    file_info.each do |line|
      if line.match(/Disabled/)
        check = 1
      end
      if line.match(/Label/)
        check = 0
      end
      if check == 1 and line.match(/true/)
        copy.push(line.gsub(/true/,"false"))
      else
        copy.push(line)
      end
    end
    File.open(tmp_file,"w") {|file| file.puts copy}
    message = "Information:\tEnabling "+service
    command = "cp #{tmp_file} #{plist_file} ; rm #{tmp_file}"
    execute_command(message,command)
    message = "Information:\tLoading "+service+" profile"
    command = "launchctl load -w #{plist_file}"
    execute_command(message,command)
  end
  return
end

# Check TFTPd enabled on OS X

def check_osx_tftpd()
  service = "tftp"
  check_osx_service_is_enabled(service)
  return
end

# Check OS X brew package

def check_brew_pkg(pkg_name)
  message = "Information:\tChecking Brew package "+pkg_name
  command = "brew info #{pkg_name}"
  output  = execute_command(message,command)
  return output
end

# Install package with brew

def install_brew_pkg(pkg_name)
  pkg_status = check_brew_pkg(pkg_name)
  if !pkg_status.match(/[0-9]/)
    message = "Information:\tInstalling Package "+pkg_name
    command = "brew install #{pkg_name}"
    execute_command(message,command)
  end
  return
end

# Check OS X dnsmasq (used for puppet)

def check_osx_dnsmasq()
  pkg_name = "dnsmasq"
  install_brew_pkg(pkg_name)
  plist_file   = "/Library/LaunchDaemons/homebrew.mxcl.dnsmasq.plist"
  dnsmasq_file = "/usr/local/etc/dnsmasq.conf"
  if !File.exist?(plist_file)
    message = "Information:\tCreating Plist file "+plist_file+" for "+pkg_name
    command = "cp -fv /usr/local/opt/dnsmasq/*.plist /Library/LaunchDaemons"
    execute_command(message,command)
    message = "Information:\tCreating Configuration file "+plist_file
    command = "cp #{dnsmasq_file}.example #{dnsmasq_file}"
    execute_command(message,command)
    message = "Information:\tLoading Configuration for "+pkg_name
    command = "launchctl load -w #{plist_file}"
    execute_command(message,command)
  end
  return
end

# Check OSC DHCP installation on OS X

def check_osx_dhcpd_installed()
  brew_file   = "/usr/local/Library/Formula/isc-dhcp.rb"
  backup_file = brew_file+".orig"
  dhcpd_bin   = "/usr/local/sbin/dhcpd"
  if !File.symlink?(dhcpd_bin)
    pkg_name = "bind"
    install_brew_pkg(pkg_name)
    message  = "Information:\tUpdating Brew sources list"
    command  = "brew update"
    execute_command(message,command)
    message  = "Information:\tChecking OS X Version"
    command  = "sw_vers |grep ProductVersion |awk '{print $2}'"
    output   = execute_command(message,command)
    if output.match(/10\.9/)
      if File.exist?(brew_file)
        message = "Information:\tChecking version of ISC DHCPd"
        command = "cat #{brew_file} | grep url"
        output  = execute_command(message,command)
        if output.match(/4\.2\.5\-P1/)
          message = "Information:\tArchiving Brew file "+brew_file+" to "+backup_file
          command = "cp #{brew_file} #{backup_file}"
          execute_command(message,command)
          message = "Information:\tFixing Brew configuration file "+brew_file
          command = "cat #{backup_file} | grep -v sha1 | sed 's/4\.2\.5\-P1/4\.3\.0rc1/g' > #{brew_file}"
          execute_command(message,command)
        end
        pkg_name = "isc-dhcp"
        install_brew_pkg(pkg_name)
      end
        message = "Information:\tCreating Launchd service for ISC DHCPd"
        command = "cp -fv /usr/local/opt/isc-dhcp/*.plist /Library/LaunchDaemons"
        execute_command(message,command)
    end
    if !File.exist?($dhcpd_file)
      message = "Information:\tCreating DHCPd configuration file "+$dhcpd_file
      command = "touch #{$dhcpd_file}"
      execute_command(message,command)
    end
  end
  return
end

# Build DHCP plist file

def create_osx_dhcpd_plist()
  xml_output = []
  tmp_file   = "/tmp/plist.xml"
  plist_name = "homebrew.mxcl.isc-dhcp"
  plist_file = "/Library/LaunchDaemons/homebrew.mxcl.isc-dhcp.plist"
  dhcpd_bin  = "/usr/local/sbin/dhcpd"
  message    = "Information:\tChecking DHCPd configruation"
  command    = "cat #{plist_file} | grep '#{$default_net}'"
  output     = execute_command(message,command)
  if !output.match(/#{$default_net}/)
    xml = Builder::XmlMarkup.new(:target => xml_output, :indent => 2)
    xml.instruct! :xml, :version => "1.0", :encoding => "UTF-8"
    xml.declare! :DOCTYPE, :plist, :PUBLIC, :'"-//Apple Computer//DTD PLIST 1.0//EN"', :'"http://www.apple.com/DTDs/PropertyList-1.0.dtd"'
    xml.plist(:version => "1.0") {
      xml.dict {
        xml.key("label")
        xml.string(plist_name)
        xml.key("ProgramArguments")
        xml.array {
          xml.string(dhcpd_bin)
          xml.string($default_net)
          xml.string("-4")
          xml.string("-f")
        }
      }
      xml.key("Disabled") ; xml.false
      xml.key("KeepAlive") ; xml.true
      xml.key("RunAtLoad") ; xml.true
      xml.key("LowPriorityID") ; xml.true
    }
    file=File.open(tmp_file,"w")
    xml_output.each do |item|
      file.write(item)
    end
    file.close
    message = "Information:\tCreating service file "+plist_file
    command = "cp #{tmp_file} #{plist_file} ; rm #{tmp_file}"
    execute_command(message,command)
  end
  return
end

# Check ISC DHCP installed on OS X

def check_osx_dhcpd()
  check_osx_dhcpd_installed()
  create_osx_dhcpd_plist()
  service = "dhcp"
  check_osx_service_is_enabled(service)
  return
end

# Enable OS X service

def refresh_osx_service(service_name)
  if !service_name.match(/\./)
    if service_name.match(/dhcp/)
      service_name = "homebrew.mxcl.isc-"+service_name
    else
      service_name = "com.apple."+service_name+"d"
    end
  end
  disable_osx_service(service_name)
  enable_osx_service(service_name)
  return
end

# Enable OS X service

def enable_osx_service(service_name)
  check_osx_service_is_enabled(service_name)
  message = "Information:\tEnabling service "+service_name
  command = "launchctl start #{service_name}"
  output  = execute_command(message,command)
  return output
end

# Enable OS X service

def disable_osx_service(service_name)
  message = "Information:\tDisabling service "+service_name
  command = "launchctl stop #{service_name}"
  output  = execute_command(message,command)
  return output
end
