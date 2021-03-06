# Code for Preseed clients

# List Preseed clients

def list_ps_clients()
  service_type = "Preseed"
  list_clients(service_type)
end

# Configure Preseed client

def configure_ps_client(install_client,install_arch,install_mac,install_ip,install_model,publisherhost,install_service,
                        install_file,install_memory,install_cpu,install_network,install_license,install_mirror,install_type)
  configure_ks_client(install_client,install_arch,install_mac,install_ip,install_model,publisherhost,install_service,
                      install_file,install_memory,install_cpu,install_network,install_license,install_mirror,install_type)
  return
end

# Unconfigure Preseed client

def unconfigure_ps_client(client_name,client_mac,service_name)
  unconfigure_ks_client(client_name,client_mac,service_name)
  return
end

# Output the Preseed file contents

def output_ps_header(client_name,output_file)
  tmp_file = "/tmp/preseed_"+client_name
  file = File.open(tmp_file, 'w')
  $q_order.each do |key|
    if $q_struct[key].parameter.match(/[a-z,A-Z]/)
      output = "d-i "+$q_struct[key].parameter+" "+$q_struct[key].type+" "+$q_struct[key].value+"\n"
      file.write(output)
    end
  end
  file.close
  message = "Creating:\tPreseed file "+output_file+" for "+client_name
  command = "cp #{tmp_file} #{output_file} ; rm #{tmp_file}"
  execute_command(message,command)
  print_contents_of_file("",output_file)
  return
end

# Populate first boot commands

def populate_ps_first_boot_list(install_service)
  post_list        = []
  client_ip        = $q_struct["ip"].value
  if install_service.match(/ubuntu/)
    if install_service.match(/16_10/)
      client_nic = "eth0"
    else
      client_nic = $q_struct["nic"].value
    end
  else
    client_nic = $q_struct["nic"].value
  end
  client_gateway    = $q_struct["gateway"].value
  client_netmask    = $q_struct["netmask"].value
  client_network    = $q_struct["network_address"].value
  client_broadcast  = $q_struct["broadcast"].value
  admin_user        = $q_struct["admin_username"].value
  client_nameserver = $q_struct["nameserver"].value
  client_domain     = $q_struct["domain"].value
  post_list.push("")
  post_list.push("echo 'GRUB_CMDLINE_LINUX=\"net.ifnames=0\"' >>/etc/default/grub")
  post_list.push("update-grub")
  post_list.push("")
  post_list.push("export TERM=vt100")
  post_list.push("export LANGUAGE=en_US.UTF-8")
  post_list.push("export LANG=en_US.UTF-8")
  post_list.push("export LC_ALL=en_US.UTF-8")
  post_list.push("locale-gen en_US.UTF-8")
  post_list.push("dpkg-reconfigure locales")
  post_list.push("")
  post_list.push("# Configure apt mirror")
  post_list.push("")
  post_list.push("cp /etc/apt/sources.list /etc/apt/sources.list.orig")
  post_list.push("sed -i 's,#{$default_ubuntu_mirror},#{$local_ubuntu_mirror},g' /etc/apt/sources.list")
  post_list.push("")
  post_list.push("# Setup sudoers")
  post_list.push("")
  post_list.push("echo \"#{admin_user} ALL=(ALL) NOPASSWD:ALL\" >> /etc/sudoers.d/sysadmin")
  post_list.push("")
  post_list.push("# Enable serial console")
  post_list.push("")
  post_list.push("echo 'start on stopped rc or RUNLEVEL=[12345]' > /etc/init/ttyS0.conf")
  post_list.push("echo 'stop on runlevel [!12345]' >> /etc/init/ttyS0.conf")
  post_list.push("echo 'respawn' >> /etc/init/ttyS0.conf")
  post_list.push("echo 'exec /sbin/getty -L 115200 ttyS0 vt100' >> /etc/init/ttyS0.conf")
  post_list.push("start ttyS0")
  post_list.push("")
  post_list.push("# Configure network")
  post_list.push("")
  net_config = "/etc/network/interfaces"
  post_list.push("sed -i 's/^#GRUB_TERMINAL/GRUB_TERMINAL=console/' /etc/default/grub")
  post_list.push("echo 'GRUB_SERIAL_COMMAND=\"serial --speed=115200 --unit=0 --word=8 --parity=no --stop=1\"' >> /etc/default/grub")
  post_list.push("echo '# The loopback network interface' > #{net_config}")
  post_list.push("echo 'auto lo' >> #{net_config}")
  post_list.push("echo 'iface lo inet loopback' >> #{net_config}")
  post_list.push("echo '# The primary network interface' >> #{net_config}")
  post_list.push("echo 'auto #{client_nic}' >> #{net_config}")
  post_list.push("echo 'iface #{client_nic} inet static' >> #{net_config}")
  post_list.push("echo 'address #{client_ip}' >> #{net_config}")
  post_list.push("echo 'gateway #{client_gateway}' >> #{net_config}")
  post_list.push("echo 'netmask #{client_netmask}' >> #{net_config}")
  post_list.push("echo 'network #{client_network}' >> #{net_config}")
  post_list.push("echo 'broadcast #{client_broadcast}' >> #{net_config}")
  post_list.push("echo 'dns-search #{client_domain}' >> #{net_config}")
  post_list.push("echo 'dns-nameservers #{client_nameserver}' >> #{net_config}")
  post_list.push("")
  resolv_conf = "/etc/resolvconf/resolv.conf.d/base"
  post_list.push("# Configure hosts file")
  post_list.push("")
  post_list.push("echo 'nameserver #{$default_nameserver}' > #{resolv_conf}")
  post_list.push("echo 'search local' >> #{resolv_conf}")
  post_list.push("")
#  puppet_config = "/etc/puppet/puppet.conf"
#  post_list.push("# Puppet configuration")
#  post_list.push("")
#  post_list.push("echo '[main]' > #{puppet_config}")
#  post_list.push("echo 'logdir=/var/log/puppet' >> #{puppet_config}")
#  post_list.push("echo 'vardir=/var/lib/puppet' >> #{puppet_config}")
#  post_list.push("echo 'ssldir=/var/lib/puppet/ssl' >> #{puppet_config}")
#  post_list.push("echo 'rundir=/var/run/puppet' >> #{puppet_config}")
#  post_list.push("echo 'factpath=$vardir/lib/facter' >> #{puppet_config}")
#  post_list.push("echo 'templatedir=$confdir/templates' >> #{puppet_config}")
#  post_list.push("")
#  post_list.push("puppet agent --test")
  post_list.push("")
  post_list.push("# Configure sources.list")
  post_list.push("")
  post_list.push("export UBUNTU_RELEASE=`lsb_release -sc`")
  post_list.push("")
  post_list.push("echo \"\" >> /etc/apt/sources.list")
  post_list.push("echo \"###### Ubuntu Main Repos\" >> /etc/apt/sources.list")
  post_list.push("echo \"deb http://#{$default_ubuntu_mirror} $UBUNTU_RELEASE main restricted universe multiverse\" >> /etc/apt/sources.list")
  post_list.push("echo \"deb-src http://#{$default_ubuntu_mirror} $UBUNTU_RELEASE main restricted universe multiverse\" >> /etc/apt/sources.list")
  post_list.push("echo \"\" >> /etc/apt/sources.list")
  post_list.push("echo \"###### Ubuntu Update Repos\" >> /etc/apt/sources.list")
  post_list.push("echo \"deb http://#{$default_ubuntu_mirror}/ubuntu $UBUNTU_RELEASE-security main restricted universe multiverse\" >> /etc/apt/sources.list")
  post_list.push("echo \"deb-src http://#{$default_ubuntu_mirror}/ubuntu $UBUNTU_RELEASE-security main restricted universe multiverse\" >> /etc/apt/sources.list")
  post_list.push("echo \"deb http://#{$default_ubuntu_mirror}/ubuntu $UBUNTU_RELEASE-updates main restricted universe multiverse\" >> /etc/apt/sources.list")
  post_list.push("echo \"deb-src http://#{$default_ubuntu_mirror}/ubuntu $UBUNTU_RELEASE-updates main restricted universe multiverse\" >> /etc/apt/sources.list")
  post_list.push("echo \"deb http://#{$default_ubuntu_mirror}/ubuntu $UBUNTU_RELEASE-proposed main restricted universe multiverse\" >> /etc/apt/sources.list")
  post_list.push("echo \"deb-src http://#{$default_ubuntu_mirror}/ubuntu $UBUNTU_RELEASE-proposed main restricted universe multiverse\" >> /etc/apt/sources.list")
  post_list.push("echo \"deb http://#{$default_ubuntu_mirror}/ubuntu $UBUNTU_RELEASE-backports main restricted universe multiverse\" >> /etc/apt/sources.list")
  post_list.push("echo \"deb-src http://#{$default_ubuntu_mirror}/ubuntu $UBUNTU_RELEASE-backports main restricted universe multiverse\" >> /etc/apt/sources.list")
#  post_list.push("")
#  post_list.push("apt-get clean")
#  post_list.push("apt-get update")
#  post_list.push("apt-get install -y openssh-server")
#  post_list.push("")
#  post_list.push("# Install VM tools")
#  post_list.push("")
#  post_list.push("if [ \"`dmidecode |grep VMware`\" ]; then")
#  post_list.push("  apt-get install -y --no-install-recommends open-vm-tools")
#  post_list.push("fi")
  post_list.push("")
  post_list.push("# Disable script and reboot")
  post_list.push("")
  post_list.push("update-rc.d -f firstboot.sh remove")
  post_list.push("mv /etc/init.d/firstboot.sh /etc/init.d/_firstboot.sh")
  post_list.push("/sbin/reboot")
  post_list.push("")
  return post_list
end

# Populate post commands

def populate_ps_post_list(client_name,service_name,install_type,install_vm)
  post_list  = []
  if install_type.match(/packer/)
    script_url = "http://"+$default_gateway+":"+$default_httpd_port+"/"+install_vm+"/"+client_name+"/"+client_name+"_first_boot.sh"
  else
    script_url = "http://"+$default_host+"/"+service_name+"/"+client_name+"_first_boot.sh"
  end
  post_list.push("/usr/bin/wget -O /root/firstboot.sh #{script_url}")
  first_boot = "/etc/init.d/firstboot.sh"
  post_list.push("chmod +x /root/firstboot.sh")
  post_list.push("echo '#!/bin/bash' > #{first_boot}")
  post_list.push("echo '' >> #{first_boot}")
  post_list.push("echo '### BEGIN INIT INFO' >> #{first_boot}")
  post_list.push("echo '# Provides:        firstboot' >> #{first_boot}")
  post_list.push("echo '# Required-Start:  $networking' >> #{first_boot}")
  post_list.push("echo '# Required-Stop:   $networking' >> #{first_boot}")
  post_list.push("echo '# Default-Start:   2 3 4 5' >> #{first_boot}")
  post_list.push("echo '# Default-Stop:    0 1 6' >> #{first_boot}")
  post_list.push("echo '# Short-Description: A script that runs once' >> #{first_boot}")
  post_list.push("echo '# Description: A script that runs once' >> #{first_boot}")
  post_list.push("echo '### END INIT INFO' >> #{first_boot}")
  post_list.push("echo '' >> #{first_boot}")
  post_list.push("echo 'cd /root ; /usr/bin/nohup sh -x /root/firstboot.sh > /var/log/firstboot.log' >> #{first_boot}")
  post_list.push("")
  post_list.push("chmod +x #{first_boot}")
  post_list.push("update-rc.d firstboot.sh defaults")
  post_list.push("")
  return post_list
end
