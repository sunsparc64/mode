
# Kickstart client routines

# List ks clients

def list_ks_clients()
  service_type = "Kickstart"
  list_clients(service_type)
  return
end

# Configure client PXE boot

def configure_ks_pxe_client(install_client,install_ip,install_mac,install_arch,install_service)
  tftp_pxe_file = install_mac.gsub(/:/,"")
  tftp_pxe_file = tftp_pxe_file.upcase
  tftp_pxe_file = "01"+tftp_pxe_file+".pxelinux"
  test_file     = $tftp_dir+"/"+tftp_pxe_file
  tmp_file      = "/tmp/pxecfg"
  if File.symlink?(test_file)
    message = "Information:\tRemoving old PXE boot file "+test_file
    command = "rm #{test_file}"
    execute_command(message,command)
  end
  if install_service.match(/ubuntu/)
    pxelinux_file = install_service+"/images/pxeboot/netboot/pxelinux.0"
  else
    pxelinux_file = install_service+"/usr/share/syslinux/pxelinux.0"
  end
  message = "Information:\tCreating PXE boot file for "+install_client+" with MAC address "+install_mac
  command = "cd #{$tftp_dir} ; ln -s #{pxelinux_file} #{tftp_pxe_file}"
  execute_command(message,command)
  pxe_cfg_dir  = $tftp_dir+"/pxelinux.cfg"
  pxe_cfg_file = install_mac.gsub(/:/,"-")
  pxe_cfg_file = "01-"+pxe_cfg_file
  pxe_cfg_file = pxe_cfg_file.downcase
  pxe_cfg_file = pxe_cfg_dir+"/"+pxe_cfg_file
  if install_service.match(/sles/)
    vmlinuz_file = "/"+install_service+"/boot/#{install_arch}/loader/linux"
  else
    vmlinuz_file = "/"+install_service+"/images/pxeboot/vmlinuz"
  end
  if install_service.match(/ubuntu/)
    if install_service.match(/x86_64/)
      initrd_file  = "/"+install_service+"/images/pxeboot/netboot/ubuntu-installer/amd64/initrd.gz"
    else
      initrd_file  = "/"+install_service+"/images/pxeboot/netboot/ubuntu-installer/i386/initrd.gz"
    end
    if install_service.match(/14_10|15/)
      ldlinux_link = $tftp_dir+"/ldlinux.c32"
      if !File.exist?(ldlinux_link) and !File.symlink?(ldlinux_link)
        ldlinux_file = install_service+"/images/pxeboot/netboot/ldlinux.c32"
        message = "Information:\tCreating symlink for ldlinux.c32"
        command = "ln -s #{ldlinux_file} #{ldlinux_link}"
        execute_command(message,command)
      end
    end
  else
    if install_service.match(/sles/)
      initrd_file  = "/"+install_service+"/boot/#{install_arch}/loader/initrd"
    else
      initrd_file  = "/"+install_service+"/images/pxeboot/initrd.img"
    end
  end
  if $os_name.match(/Darwin/)
    vmlinuz_file = vmlinuz_file.gsub(/^\//,"")
    initrd_file  = initrd_file.gsub(/^\//,"")
  end
  if install_service.match(/packer/)
    host_info = $default_gateway+":"+$default_httpd_port
  else
    host_info = $default_host
  end
  ks_url       = "http://"+host_info+"/clients/"+install_service+"/"+install_client+"/"+install_client+".cfg"
  autoyast_url = "http://"+host_info+"/clients/"+install_service+"/"+install_client+"/"+install_client+".xml"
  install_url  = "http://"+host_info+"/"+install_service
  file         = File.open(tmp_file,"w")
  if $serial_mode == true
    file.write("serial 0 115200\n")
    file.write("prompt 0\n")
  end
  file.write("DEFAULT LINUX\n")
  file.write("LABEL LINUX\n")
  file.write("  KERNEL #{vmlinuz_file}\n")
  if install_service.match(/ubuntu/)
    install_ip         = $q_struct["ip"].value
    install_domain     = $q_struct["domain"].value
    install_nic        = $q_struct["nic"].value
    install_gateway    = $q_struct["gateway"].value
    install_netmask    = $q_struct["netmask"].value
    install_network    = $q_struct["network_address"].value
    install_nameserver = $q_struct["nameserver"].value
    disable_dhcp      = $q_struct["disable_dhcp"].value
    if disable_dhcp.match(/true/)
      append_string = "  APPEND auto=true priority=critical preseed/url=#{ks_url} console-keymaps-at/keymap=us locale=en_US hostname=#{install_client} domain=#{install_domain} interface=#{install_nic} netcfg/get_ipaddress=#{install_ip} netcfg/get_netmask=#{install_netmask} netcfg/get_gateway=#{install_gateway} netcfg/get_nameservers=#{install_nameserver} netcfg/disable_dhcp=true initrd=#{initrd_file}"
    else
      append_string = "  APPEND "
    end
  else
    if install_service.match(/sles/)
      append_string = "  APPEND initrd=#{initrd_file} install=#{install_url} autoyast=#{autoyast_url} language=#{$default_language}"
    else
      if install_service.match(/fedora_2[0-3]/)
        append_string = "  APPEND initrd=#{initrd_file} ks=#{ks_url} ip=#{install_ip} netmask=#{$default_netmask}"
      else
        append_string = "  APPEND initrd=#{initrd_file} ks=#{ks_url} ksdevice=bootif ip=#{install_ip} netmask=#{$default_netmask}"
      end
    end
  end
  if $text_mode == true
    if install_service.match(/sles/)
      append_string = append_string+" textmode=1"
    else
      append_string = append_string+" text"
    end
  end
  if $serial_mode == true
    append_string = append_string+" serial console=ttyS0"
  end
  append_string = append_string+"\n"
  file.write(append_string)
  file.close
  message = "Information:\tCreating PXE configuration file "+pxe_cfg_file
  command = "cp #{tmp_file} #{pxe_cfg_file} ; rm #{tmp_file}"
  execute_command(message,command)
  print_contents_of_file("",pxe_cfg_file)
  return
end

# Unconfigure client PXE boot

def unconfigure_ks_pxe_client(install_client)
  install_mac = get_install_mac(install_client)
  if !install_mac
    handle_output("Warning:\tNo MAC Address entry found for #{install_client}")
    exit
  end
  tftp_pxe_file = install_mac.gsub(/:/,"")
  tftp_pxe_file = tftp_pxe_file.upcase
  tftp_pxe_file = "01"+tftp_pxe_file+".pxelinux"
  tftp_pxe_file = $tftp_dir+"/"+tftp_pxe_file
  if File.exist?(tftp_pxe_file)
    message = "Information:\tRemoving PXE boot file "+tftp_pxe_file+" for "+install_client
    command = "rm #{tftp_pxe_file}"
    output  = execute_command(message,command)
  end
  pxe_cfg_dir  = $tftp_dir+"/pxelinux.cfg"
  pxe_cfg_file = install_mac.gsub(/:/,"-")
  pxe_cfg_file = "01-"+pxe_cfg_file
  pxe_cfg_file = pxe_cfg_file.downcase
  pxe_cfg_file = pxe_cfg_dir+"/"+pxe_cfg_file
  if File.exist?(pxe_cfg_file)
    message = "Information:\tRemoving PXE boot config file "+pxe_cfg_file+" for "+install_client
    command = "rm #{pxe_cfg_file}"
    output  = execute_command(message,command)
  end
  unconfigure_ks_dhcp_client(install_client)
  return
end

# Configure DHCP entry

def configure_ks_dhcp_client(install_client,install_mac,install_ip,install_arch,install_service)
  add_dhcp_client(install_client,install_mac,install_ip,install_arch,install_service)
  return
end

# Unconfigure DHCP client

def unconfigure_ks_dhcp_client(install_client)
  remove_dhcp_client(install_client)
  return
end

# Configure Kickstart client

def configure_ks_client(install_client,install_arch,install_mac,install_ip,install_model,publisherhost,install_service,
                        install_file,install_memory,install_cpu,install_network,install_license,install_mirror,install_type,install_vm)
  if !install_arch.match(/[a-z]/)
    if install_service.match(/i386/)
      install_arch = "i386"
    else
      install_arch = "x86_64"
    end
  end
  configure_ks_pxe_boot(install_service,install_arch)
  repo_version_dir = $repo_base_dir+"/"+install_service
  add_apache_alias($client_base_dir)
  client_dir = $client_base_dir+"/"+install_service+"/"+install_client
  check_fs_exists(client_dir)
  if !File.directory?(repo_version_dir)
    handle_output("Warning:\tService #{install_service} does not exist")
    handle_output("") 
    list_ks_services()
    exit
  end
  check_dir_exists(client_dir)
  if install_service.match(/sles/)
    output_file = client_dir+"/"+install_client+".xml"
  else
    output_file = client_dir+"/"+install_client+".cfg"
  end
  delete_file(output_file)
  if install_service.match(/fedora|rhel|centos|sl_|oel/)
    populate_ks_questions(install_service,install_client,install_ip,install_type)
    process_questions(install_service)
    output_ks_header(install_client,output_file)
    pkg_list = populate_ks_pkg_list(install_service)
    output_ks_pkg_list(install_client,pkg_list,output_file,install_service)
    post_list = populate_ks_post_list(install_arch,install_service,publisherhost,install_client,install_ip,install_vm)
    output_ks_post_list(install_client,post_list,output_file,install_service)
  else
    if install_service.match(/sles/)
      populate_ks_questions(install_service,install_client,install_ip,install_type)
      process_questions(install_service)
      output_ay_client_profile(install_client,install_ip,install_mac,output_file,install_service)
    else
      if install_service.match(/ubuntu|debian/)
        populate_ps_questions(install_service,install_client,install_ip,install_mirror,install_type,install_vm)
        process_questions(install_service)
        output_ps_header(install_client,output_file)
        output_file = client_dir+"/"+install_client+"_post.sh"
        post_list   = populate_ps_post_list(install_client,install_service,install_type,install_vm)
        output_ks_post_list(install_client,post_list,output_file,install_service)
        output_file = client_dir+"/"+install_client+"_first_boot.sh"
        post_list   = populate_ps_first_boot_list(install_service)
        output_ks_post_list(install_client,post_list,output_file,install_service)
      end
    end
  end
  configure_ks_pxe_client(install_client,install_ip,install_mac,install_arch,install_service)
  configure_ks_dhcp_client(install_client,install_mac,install_ip,install_arch,install_service)
  add_hosts_entry(install_client,install_ip)
  return
end

# Unconfigure Kickstart client

def unconfigure_ks_client(install_client,install_mac,install_service)
  unconfigure_ks_pxe_client(install_client)
  unconfigure_ks_dhcp_client(install_client)
  return
end

# Populate post commands

def populate_ks_post_list(install_arch,install_service,publisherhost,install_client,install_ip,install_vm)
  gateway_ip  = $default_gateway
  post_list   = []
  admin_group = $q_struct["admin_group"].value
  admin_user  = $q_struct["admin_username"].value
  admin_crypt = $q_struct["admin_crypt"].value
  admin_home  = $q_struct["admin_home"].value
  admin_uid   = $q_struct["admin_uid"].value
  admin_gid   = $q_struct["admin_gid"].value
  nic_name    = $q_struct["nic"].value
  epel_file   = "/etc/yum.repos.d/epel.repo"
  beta_file   = "/etc/yum.repos.d/public-yum-ol6-beta.repo"
  post_list.push("")
  post_list.push("# Fix timezone")
  post_list.push("")
  post_list.push("rm /etc/localtime")
  post_list.push("cd /etc ; ln -s ../usr/share/zoneinfo/#{$default_timezone} /etc/localtime")
  post_list.push("")
  post_list.push("# Add Admin user")
  post_list.push("")
  post_list.push("groupadd #{admin_group}")
  post_list.push("groupadd #{admin_user}")
  post_list.push("")
  post_list.push("# Add admin user")
  post_list.push("")
  post_list.push("useradd -p '#{admin_crypt}' -g #{admin_user} -G #{admin_group} -d #{admin_home} -m #{admin_user}")
  post_list.push("")
  post_list.push("# Setup sudoers")
  post_list.push("")
  post_list.push("echo \"#{admin_user} ALL=(ALL) NOPASSWD:ALL\" >> /etc/sudoers")
  post_list.push("")
  resolv_conf = "/etc/resolv.conf"
  post_list.push("# Create #{resolv_conf}")
  post_list.push("")
  post_list.push("echo 'nameserver #{$default_nameserver}' >> #{resolv_conf}")
  post_list.push("echo 'search local' >> #{resolv_conf}")
  post_list.push("")
  post_list.push("route add default gw #{gateway_ip}")
  post_list.push("echo 'GATEWAY=#{gateway_ip}' > /etc/sysconfig/network")
  if install_service.match(/rhel_[5,6]/)
    post_list.push("echo 'NETWORKING=yes' >> /etc/sysconfig/network")
    post_list.push("echo 'HOSTNAME=#{install_client}' >> /etc/sysconfig/network")
    post_list.push("")
    post_list.push("echo 'default via #{gateway_ip} dev #{nic_name}' > /etc/sysconfig/network-scripts/route-eth0")
  end
  post_list.push("")
  if install_service.match(/centos|fedora|rhel|sl_|oel/)
    if install_service.match(/centos_5|fedora_18|rhel_5|sl_5|oel_5/)
      epel_url = "http://"+$local_epel_mirror+"/pub/epel/5/i386/epel-release-5-4.noarch.rpm"
    end
    if install_service.match(/centos_6|fedora_19|fedora_20|rhel_6|sl_6|oel_6/)
      epel_url = "http://"+$local_epel_mirror+"/pub/epel/6/i386/epel-release-6-8.noarch.rpm"
    end
    if install_service.match(/centos/)
      repo_file = "/etc/yum.repos.d/CentOS-Base.repo"
    end
    if install_service.match(/sl_/)
      repo_file = "/etc/yum.repos.d/sl.repo"
    end
    if install_service.match(/centos|sl_/)
      post_list.push("# Change mirror for yum")
      post_list.push("")
      post_list.push("echo 'Changing default mirror for yum'")
      post_list.push("cp #{repo_file} #{repo_file}.orig")
    end
  end
  if install_service.match(/centos/)
    post_list.push("sed -i 's/^mirror./#&/g' #{repo_file}")
    post_list.push("sed -i 's/^#\\(baseurl\\)/\\1/g' #{repo_file}")
    post_list.push("sed -i 's,#{$default_centos_mirror},#{$local_centos_mirror},g' #{repo_file}")
  end
  if install_service.match(/sl_/)
    post_list.push("sed -i 's,#{$default_sl_mirror},#{$local_sl_mirror},g' #{repo_file}")
  end
  if install_service.match(/_[5,6]/)
    if install_service.match(/_5/)
      epel_url = "http://"+$local_epel_mirror+"/pub/epel/5/"+install_arch+"/epel-release-5-4.noarch.rpm"
    end
    if install_service.match(/_6/)
      epel_url = "http://"+$local_epel_mirror+"/pub/epel/6/"+install_arch+"/epel-release-6-8.noarch.rpm"
    end
    if install_service.match(/_7/)
      epel_url = "http://"+$local_epel_mirror+"/pub/epel/beta/7/"+install_arch+"/epel-release-7-0.2.noarch.rpm"
    end
    post_list.push("")
    post_list.push("# Configure Epel repo")
    post_list.push("")
    post_list.push("rpm -i #{epel_url}")
    post_list.push("cp #{epel_file} #{epel_file}.orig")
    post_list.push("sed -i 's/^mirror./#&/g' #{epel_file}")
    post_list.push("sed -i 's/^#\\(baseurl\\)/\\1/g' #{epel_file}")
    post_list.push("sed -i 's/7/beta\\/7/g' #{epel_file}")
    post_list.push("sed -i 's,#{$default_epel_mirror},#{$local_epel_mirror},g' #{epel_file}")
    post_list.push("yum -y update")
    post_list.push("")
  end
  if $default_options.match(/puppet/)
    rpm_list  = populate_puppet_rpm_list(install_service,install_arch)
    rpm_file  = rpm_list.grep(/facter/)[0]
    if rpm_file
      rpm_file  = rpm_file.split(/\//)[1..-1].join("/")
      local_url = "http://"+publisherhost+"/puppet/"+rpm_file
      post_list.push("rpm -i #{local_url}")
    end
    rpm_file  = rpm_list.grep(/hiera/)[0]
    if rpm_file
      rpm_file  = rpm_file.split(/\//)[1..-1].join("/")
      local_url = "http://"+publisherhost+"/puppet/"+rpm_file
      post_list.push("rpm -i #{local_url}")
    end
    rpm_list.each do |rpm_file|
      if !rpm_file.match(/facter|hiera/)
        rpm_file  = rpm_file.split(/\//)[1..-1].join("/")
        local_url = "http://"+publisherhost+"/puppet/"+rpm_file
        post_list.push("rpm -i #{local_url}")
      end
    end
  end
  post_list.push("")
  post_list.push("# Avahi daemon for mDNS")
  post_list.push("")
  post_list.push("chkconfig avahi-daemon on")
  post_list.push("service avahi-daemon start")
  post_list.push("")
  post_list.push("# Install VM tools")
  post_list.push("")
  post_list.push("export OSREL=`lsb_release -r |awk '{print $2}' |cut -f1 -d'.'`")
  post_list.push("export OSARCH=`uname -p`")
  post_list.push("if [ \"`dmidecode |grep VMware`\" ]; then")
  post_list.push("  echo 'Installing VMware RPMs'")
  post_list.push("  echo -e \"[vmware-tools]\\nname=VMware Tools\\nbaseurl=http://#{publisherhost}/vmware\\nenabled=1\\ngpgcheck=0\" >> /etc/yum.repos.d/vmware-tools.repo")
  post_list.push("  yum -y install vmware-tools-core")
  post_list.push("fi")
  post_list.push("")
  post_list.push("# Enable serial console")
  post_list.push("")
  post_list.push("sed -i 's/9600/115200/' /etc/inittab")
  post_list.push("sed -i 's/kernel.*/& console=ttyS0,115200n8/' /etc/grub.conf")
  post_list.push("")
  if install_service.match(/oel_6_5/)
    post_list.push("# OEL beta repo")
    post_list.push("")
    post_list.push("echo '[uek3_beta]' > #{beta_file}")
    post_list.push("echo 'name=Unbreakable Enterprise Kernel Release 3 for Oracle Linux 6 ($basearch)' >> #{beta_file}")
    post_list.push("echo 'baseurl=http://public-yum.oracle.com/beta/repo/OracleLinux/OL6/uek3/$basearch/' >> #{beta_file}")
    post_list.push("echo 'gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-oracle' >> #{beta_file}")
    post_list.push("echo 'gpgcheck=1' >> #{beta_file}")
    post_list.push("echo 'enabled=1' >> #{beta_file}")
    post_list.push("")
    post_list.push("yum update")
    post_list.push("yum -y install dtrace-utils")
    post_list.push("yum -y install dtrace-modules")
    post_list.push("groupadd dtrace")
    post_list.push("usermod -a -G dtrace #{admin_user}")
    post_list.push("echo 'kernel==\"dtrace/dtrace\", GROUP=\"dtrace\" MODE=\"0660\"' > /etc/udev/rules.d/10-dtrace.rules")
    post_list.push("echo '/sbin/modprobe dtrace' >> /etc/rc.modules")
    post_list.push("echo '/sbin/modprobe profile' >> /etc/rc.modules")
    post_list.push("echo '/sbin/modprobe sdt' >> /etc/rc.modules")
    post_list.push("echo '/sbin/modprobe systrace' >> /etc/rc.modules")
    post_list.push("echo '/sbin/modprobe dt_test' >> /etc/rc.modules")
    post_list.push("chmod 755 /etc/rc.modules")
    post_list.push("")
  end
  if install_service.match(/rhel_/)
    post_list.push("# Add host entry")
    post_list.push("")
    post_list.push("echo '#{install_ip} #{install_client}' >> /etc/hosts")
    post_list.push("echo 'HOSTNAME=#{install_client}' >> /etc/sysconfig/network")
    post_list.push("")
  end
  if $mode_copykeys == true
    post_list.push("# Copy SSH keys")
    post_list.push("")
    ssh_key = $home_dir+"/.ssh/id_rsa.pub"
    key_dir = install_service+"/keys"
    check_dir_exists(key_dir)
    auth_file = key_dir+"/authorized_keys"
    message   = "Copying:\tSSH keys"
    command   = "cp #{ssh_key} #{auth_file}"
    execute_command(message,command)
    ssh_dir   = admin_home+"/.ssh"
    ssh_url   = "http://#{publisherhost}/#{install_service}/keys/authorized_keys"
    auth_file = ssh_dir+"/authorized_keys"
    post_list.push("mkdir #{ssh_dir}/.ssh")
    post_list.push("chown #{admin_uid}:#{admin_gid} #{ssh_dir}")
    post_list.push("cd #{ssh_dir} ; wget #{ssh_url} -O #{auth_file}")
    post_list.push("chown #{admin_uid}:#{admin_gid} #{auth_file}")
    post_list.push("chmod 644 #{auth_file}")
    post_list.push("")
  end
  if $default_options.match(/puppet/)
    puppet_config = "/etc/puppet/puppet.conf"
    post_list.push("# Puppet configuration")
    post_list.push("")
    post_list.push("echo '[main]' > #{puppet_config}")
    post_list.push("echo 'logdir=/var/log/puppet' >> #{puppet_config}")
    post_list.push("echo 'vardir=/var/lib/puppet' >> #{puppet_config}")
    post_list.push("echo 'ssldir=/var/lib/puppet/ssl' >> #{puppet_config}")
    post_list.push("echo 'rundir=/var/run/puppet' >> #{puppet_config}")
    post_list.push("echo 'factpath=$vardir/lib/facter' >> #{puppet_config}")
    post_list.push("")
    post_list.push("puppet agent --test")
    post_list.push("")
  end
  if install_vm.match(/vbox/)
    post_list.push("# Install VirtualBox Tools")
    post_list.push("")
    post_list.push("mkdir /mnt/cdrom")
    post_list.push("if [ \"`dmidecode |grep VirtualBox`\" ]; then")
    post_list.push("  echo 'Installing VirtualBox Guest Additions'")
    post_list.push("  mount /dev/cdrom /mnt/cdrom")
    post_list.push("  /mnt/cdrom/VBoxLinuxAdditions.run")
    post_list.push("  umount /mnt/cdrom")
    post_list.push("fi")
    post_list.push("")
  end
  if install_service.match(/rhel|centos/)
    post_list.push("# Enable serial console")
    post_list.push("")
    post_list.push("grubby --update-kernel=ALL --args=\"console=ttyS0\"")
    post_list.push("")
  end
  if $altrepo_mode == true
    post_list.push("mkdir /tmp/rpms")
    post_list.push("cd /tmp/rpms")
    alt_url  = "http://"+$default_host
    rpm_list = build_ks_alt_rpm_list(install_service)
    alt_dir  = $repo_base_dir+"/"+install_service+"/alt"
    if $verbose_mode == true
      handle_output("Checking:\tAdditional packages")
    end
    if File.directory?(alt_dir)
      rpm_list.each do |rpm_url|
        rpm_file = File.basename(rpm_url)
        rpm_file = alt_dir+"/"+rpm_file
        rpm_url  = alt_url+"/"+rpm_file
        if File.exist?(rpm_file)
          post_list.push("wget #{rpm_url}")
        end
      end
    end
    post_list.push("rpm -i *.rpm")
    post_list.push("cd /tmp")
    post_list.push("rm -rf /tmp/rpms")
  end
  post_list.push("")
  return post_list
end

# Populat a list of additional packages to install

def populate_ks_pkg_list(install_service)
  pkg_list = []
  if install_service.match(/centos|fedora|rhel|sl_|oel/)
    if !install_service.match(/fedora_[19,20,21,22,23,24]/)
      pkg_list.push("@base")
    end
    pkg_list.push("@core")
    if install_service.match(/[a-z]_6/)
      pkg_list.push("@console-internet")
      pkg_list.push("@system-admin-tools")
    end
    if !install_service.match(/sl_6|[a-z]_5|fedora_[19,20,21,22,23,24]/)
      pkg_list.push("@network-file-system-client")
    end
    if install_service.match(/centos_[6,7]|fedora_[18,19,20,21,22,23,24]|rhel_[6,7]|oel_[6,7]|sl_[6,7]/)
      if !install_service.match(/fedora_[23,24]/)
        pkg_list.push("redhat-lsb-core")
        if !install_service.match(/rhel_6|oel_6/)
          pkg_list.push("augeas")
        end
        pkg_list.push("tk")
      end
      if !install_service.match(/fedora_24/)
        pkg_list.push("ruby")
        pkg_list.push("ruby-irb")
        pkg_list.push("ruby-libs")
        pkg_list.push("rubygems")
      end
      if !install_service.match(/_7|fedora_[23,24]/)
        pkg_list.push("ruby-rdoc")
      end
      pkg_list.push("augeas-libs")
    end
    if !install_service.match(/fedora_[19,20,21,22,23,24]|[rhel,centos]_7/)
      pkg_list.push("grub")
      pkg_list.push("libselinux-ruby")
    end
    pkg_list.push("e2fsprogs")
    pkg_list.push("lvm2")
    if !install_service.match(/fedora_[23,24]/)
      pkg_list.push("kernel-devel")
      pkg_list.push("automake")
      pkg_list.push("autoconf")
      pkg_list.push("avahi")
      pkg_list.push("lftp")
    end
    pkg_list.push("kernel-headers")
    pkg_list.push("dos2unix")
    pkg_list.push("unix2dos")
    if !install_service.match(/[rhel,oel]_7|fedora_24/)
      pkg_list.push("ruby-devel")
    end
    if !install_service.match(/fedora_24/)
      pkg_list.push("zlib-devel")
    end
    if !install_service.match(/fedora_[23,24]/)
      pkg_list.push("libgpg-error-devel")
      pkg_list.push("libxml2-devel")
      pkg_list.push("libgcrypt-devel")
      pkg_list.push("xz-devel")
      pkg_list.push("libxslt-devel")
      pkg_list.push("libstdc++-devel")
      if !install_service.match(/rhel_5|fedora_[23,24]/)
        pkg_list.push("perl-TermReadKey")
        pkg_list.push("git")
        pkg_list.push("perl-Git")
      end
      pkg_list.push("gcc")
      pkg_list.push("gcc-c++")
      pkg_list.push("dhcp")
      pkg_list.push("xinetd")
      pkg_list.push("tftp-server")
    end
    if !install_service.match(/rhel_[5,6]|oel_6/)
      pkg_list.push("libgnome-keyring")
    end
    if !install_service.match(/rhel_5/)
      pkg_list.push("perl-Error")
    end
    pkg_list.push("httpd")
    if install_service.match(/fedora_[19,20,21,22,23,24]/)
      pkg_list.push("net-tools")
      pkg_list.push("bind-utils")
    end
    if !install_service.match(/fedora_[19,20,21,22,23,24]/)
      pkg_list.push("ntp")
    end
    pkg_list.push("rsync")
    if install_service.match(/sl_6/)
      pkg_list.push("-samba-client")
    end
  end
  return pkg_list
end

# Output the Kickstart file header

def output_ks_header(install_client,output_file)
  tmp_file = "/tmp/ks_"+install_client
  file=File.open(tmp_file, 'w')
  $q_order.each do |key|
    if $q_struct[key].type.match(/output/)
      if !$q_struct[key].parameter.match(/[a-z,A-Z]/)
        output = $q_struct[key].value+"\n"
      else
        output = $q_struct[key].parameter+" "+$q_struct[key].value+"\n"
      end
      file.write(output)
    end
  end
  file.close
  message = "Creating:\tKickstart file "+output_file
  command = "cp #{tmp_file} #{output_file} ; rm #{tmp_file}"
  execute_command(message,command)
  return
end

# Output the ks packages list

def output_ks_pkg_list(install_client,pkg_list,output_file,install_service)
  tmp_file = "/tmp/ks_pkg_"+install_client
  file     = File.open(tmp_file, 'w')
  output   = "\n%packages\n"
  file.write(output)
  pkg_list.each do |pkg_name|
    output = pkg_name+"\n"
    file.write(output)
  end
  if install_service.match(/fedora_[19,20]|[centos,rhel,oel,sl]_7/)
    output   = "\n%end\n"
    file.write(output)
  end
  file.close
  message = "Updating:\tKickstart file "+output_file
  command = "cat #{tmp_file} >> #{output_file} ; rm #{tmp_file}"
  execute_command(message,command)
  return
end

# Output the ks packages list

def output_ks_post_list(install_client,post_list,output_file,install_service)
  tmp_file = "/tmp/postinstall_"+install_client
  if install_service.match(/centos|fedora|rhel|sl_|oel/)
    message = "Information:\tAppending post install script "+output_file
    command = "cp #{output_file} #{tmp_file}"
    file=File.open(tmp_file, 'a')
    output = "\n%post\n"
    command = "cat #{tmp_file} >> #{output_file} ; rm #{tmp_file}"
  else
    file=File.open(tmp_file, 'w')
    output = "#!/bin/sh\n"
    command = "cp #{tmp_file} #{output_file} ; rm #{tmp_file}"
  end
  file.write(output)
  post_list.each do |line|
    output = line+"\n"
    file.write(output)
  end
  if install_service.match(/fedora_[19,20]|[centos,rhel,sl]_7/)
    output   = "\n%end\n"
    file.write(output)
  end
  file.close
  message = "Information:\tCreating post install script "+output_file
  execute_command(message,command)
  print_contents_of_file("",output_file)
  return
end

# Check service install_service

def check_ks_install_service(install_service)
  if !install_service.match(/[a-z,A-Z]/)
    handle_output("Warning:\tService name not given")
    exit
  end
  client_list = Dir.entries($repo_base_dir)
  if !client_list.grep(install_service)
    handle_output("Warning:\tService name #{install_service} does not exist")
    exit
  end
  return
end
