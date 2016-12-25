
# Preseed configuration questions for Ubuntu

def populate_ps_questions(install_service,install_client,install_ip,install_mirror,install_type,install_vm)
  $q_struct = {}
  $q_order  = []

  name = "language"
  config = Ks.new(
    type      = "string",
    question  = "Language",
    ask       = "yes",
    parameter = "debian-installer/language",
    value     = $default_debian_language,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "country"
  config = Ks.new(
    type      = "string",
    question  = "Country",
    ask       = "yes",
    parameter = "debian-installer/country",
    value     = $default_country,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "locale"
  config = Ks.new(
    type      = "string",
    question  = "Locale",
    ask       = "yes",
    parameter = "debian-installer/locale",
    value     = $default_locale,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "console"
  config = Ks.new(
    type      = "boolean",
    question  = "Enable keymap detection",
    ask       = "no",
    parameter = "console-setup/ask_detect",
    value     = "false",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "layout"
  config = Ks.new(
    type      = "string",
    question  = "Keyboard layout",
    ask       = "no",
    parameter = "keyboard-configuration/layoutcode",
    value     = $default_keyboard.downcase,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "interface"
  config = Ks.new(
    type      = "select",
    question  = "Network interface",
    ask       = "yes",
    parameter = "netcfg/choose_interface",
    value     = $default_debian_interface,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "disable_autoconfig"
  config = Ks.new(
    type      = "boolean",
    question  = "Disable network autoconfig",
    ask       = "yes",
    parameter = "netcfg/disable_autoconfig",
    value     = $default_disable_autoconf,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "disable_dhcp"
  config = Ks.new(
    type      = "boolean",
    question  = "Disable DHCP",
    ask       = "yes",
    parameter = "netcfg/disable_dhcp",
    value     = $default_disable_dhcp,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "nameserver"
  config = Ks.new(
    type      = "string",
    question  = "Nameservers",
    ask       = "yes",
    parameter = "netcfg/get_nameservers",
    value     = "#{$default_nameserver}",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "ip"
  config = Ks.new(
    type      = "string",
    question  = "IP address",
    ask       = "yes",
    parameter = "netcfg/get_ipaddress",
    value     = install_ip,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "netmask"
  config = Ks.new(
    type      = "string",
    question  = "Netmask",
    ask       = "yes",
    parameter = "netcfg/get_netmask",
    value     = $default_netmask,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  gateway = install_ip.split(/\./)[0..2].join(".")+".254"

  name = "gateway"
  config = Ks.new(
    type      = "string",
    question  = "Gateway",
    ask       = "yes",
    parameter = "netcfg/get_gateway",
    value     = gateway,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  broadcast = install_ip.split(/\./)[0..2].join(".")+".255"

  name = "broadcast"
  config = Ks.new(
    type      = "",
    question  = "Broadcast",
    ask       = "yes",
    parameter = "",
    value     = broadcast,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  network_address = install_ip.split(/\./)[0..2].join(".")+".0"

  name = "network_address"
  config = Ks.new(
    type      = "",
    question  = "Network Address",
    ask       = "yes",
    parameter = "",
    value     = network_address,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "static"
  config = Ks.new(
    type      = "boolean",
    question  = "Confirm Static",
    ask       = "yes",
    parameter = "netcfg/confirm_static",
    value     = "true",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "hostname"
  config = Ks.new(
    type      = "string",
    question  = "Hostname",
    ask       = "yes",
    parameter = "netcfg/get_hostname",
    value     = install_client,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  if install_service.match(/ubuntu/)
    if install_service.match(/16_10/)
      if install_vm.match(/fusion/)
        $default_debian_interface = "ens33"
      else
        $default_debian_interface = "enp0s3"
      end
    end
  end

  name = "nic"
  config = Ks.new(
    type      = "",
    question  = "NIC",
    ask       = "yes",
    parameter = "",
    value     = $default_debian_interface,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  client_domain = %x[domainname]
  client_domain = client_domain.chomp
  if !client_domain.match(/[0-9]/)
    client_domain = $default_domainname
  end

  name = "domain"
  config = Ks.new(
    type      = "string",
    question  = "Domainname",
    ask       = "yes",
    parameter = "netcfg/get_domain",
    value     = client_domain,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "firmware"
  config = Ks.new(
    type      = "boolean",
    question  = "Prompt for firmware",
    ask       = "no",
    parameter = "hw-detect/load_firmware",
    value     = "false",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "clock"
  config = Ks.new(
    type      = "string",
    question  = "Hardware clock set to UTC",
    ask       = "yes",
    parameter = "clock-setup/utc",
    value     = "false",
    valid     = "false,true",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "timezone"
  config = Ks.new(
    type      = "string",
    question  = "Timezone",
    ask       = "yes",
    parameter = "time/zone",
    value     = $default_timezone,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "timeserver"
  config = Ks.new(
    type      = "string",
    question  = "Timeserer",
    ask       = "yes",
    parameter = "clock-setup/ntp-server",
    value     = $default_timeserver,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  if !install_mirror.match(/[a-z]/) or !install_mirror.match(/none/)

    if install_type.match(/packer/)

      name = "use_mirror"
      config = Ks.new(
        type      = "boolean",
        question  = "Mirror hostname",
        ask       = "no",
        parameter = "apt-setup/use_mirror",
        value     = $default_use_mirror,
        valid     = "",
        eval      = "no"
        )
      $q_struct[name] = config
      $q_order.push(name)

      name = "no_mirror"
      config = Ks.new(
        type      = "boolean",
        question  = "Mirror hostname",
        ask       = "no",
        parameter = "apt-setup/no_mirror",
        value     = $default_no_mirror,
        valid     = "",
        eval      = "no"
        )
      $q_struct[name] = config
      $q_order.push(name)

    else
      mirror_hostname = $default_host

      name = "mirror_country"
      config = Ks.new(
        type      = "string",
        question  = "Mirror country",
        ask       = "no",
        parameter = "mirror/country",
        value     = "manual",
        valid     = "",
        eval      = "no"
        )
      $q_struct[name] = config
      $q_order.push(name)

      name = "mirror_hostname"
      config = Ks.new(
        type      = "string",
        question  = "Mirror hostname",
        ask       = "no",
        parameter = "mirror/http/hostname",
        value     = mirror_hostname,
        valid     = "",
        eval      = "no"
        )
      $q_struct[name] = config
      $q_order.push(name)
    
      name = "mirror_directory"
      config = Ks.new(
        type      = "string",
        question  = "Mirror directory",
        ask       = "no",
        parameter = "mirror/http/directory",
        value     = "/"+install_service,
        valid     = "",
        eval      = "no"
        )
      $q_struct[name] = config
      $q_order.push(name)

    end
  
    name = "mirror_proxy"
    config = Ks.new(
      type      = "string",
      question  = "Mirror country",
      ask       = "no",
      parameter = "mirror/http/proxy",
      value     = "",
      valid     = "",
      eval      = "no"
      )
    $q_struct[name] = config
    $q_order.push(name)


  else

    name = "mirror_country"
    config = Ks.new(
      type      = "string",
      question  = "Mirror country",
      ask       = "yes",
      parameter = "mirror/country",
      value     = "manual",
      valid     = "",
      eval      = "no"
      )
    $q_struct[name] = config
    $q_order.push(name)

    name = "mirror_hostname"
    config = Ks.new(
      type      = "string",
      question  = "Mirror hostname",
      ask       = "yes",
      parameter = "mirror/http/hostname",
      value     = $local_ubuntu_mirror,
      valid     = "",
      eval      = "no"
      )
    $q_struct[name] = config
    $q_order.push(name)
  
    name = "mirror_directory"
    config = Ks.new(
      type      = "string",
      question  = "Mirror directory",
      ask       = "yes",
      parameter = "mirror/http/directory",
      value     = "/ubuntu",
      valid     = "",
      eval      = "no"
      )
    $q_struct[name] = config
    $q_order.push(name)
  
    name = "mirror_proxy"
    config = Ks.new(
      type      = "string",
      question  = "Mirror country",
      ask       = "yes",
      parameter = "mirror/http/proxy",
      value     = "",
      valid     = "",
      eval      = "no"
      )
    $q_struct[name] = config
    $q_order.push(name)

  end

  name = "updates"
  config = Ks.new(
    type      = "select",
    question  = "Update policy",
    ask       = "yes",
    parameter = "pkgsel/update-policy",
    value     = "none",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "software"
  config = Ks.new(
    type      = "multiselect",
    question  = "Software",
    ask       = "yes",
    parameter = "tasksel/first",
    value     = $default_ubuntu_software,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "exit"
  config = Ks.new(
    type      = "boolean",
    question  = "Exit installer",
    ask       = "yes",
    parameter = "debian-installer/exit/halt",
    value     = "false",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "partition_method"
  config = Ks.new(
    type      = "string",
    question  = "Parition method",
    ask       = "yes",
    parameter = "partman-auto/method",
    value     = "regular",
    valid     = "regular,lvm,crypto",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "purge_existing"
  config = Ks.new(
    type      = "boolean",
    question  = "Remove existing partitions",
    ask       = "yes",
    parameter = "partman-lvm/purge_lvm_from_device",
    value     = "true",
    valid     = "true,false",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "partition_write"
  config = Ks.new(
    type      = "boolean",
    question  = "Write parition",
    ask       = "yes",
    parameter = "partman-lvm/confirm",
    value     = "true",
    valid     = "true,flase",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "filesystem_layout"
  config = Ks.new(
    type      = "select",
    question  = "Filesystem layout",
    ask       = "yes",
    parameter = "partman-auto/choose_recipe",
    value     = "atomic",
    valid     = "atomic,home,multi",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "partition_label"
  config = Ks.new(
    type      = "boolean",
    question  = "Write partition label",
    ask       = "no",
    parameter = "partman-partitioning/confirm_write_new_label",
    value     = "true",
    valid     = "true,false",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "partition_finish"
  config = Ks.new(
    type      = "select",
    question  = "Finish partition",
    ask       = "no",
    parameter = "partman/choose_partition",
    value     = "finish",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "partition_confirm"
  config = Ks.new(
    type      = "boolean",
    question  = "Confirm partition",
    ask       = "no",
    parameter = "partman/confirm",
    value     = "true",
    valid     = "true,faule",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "partition_nooverwrite"
  config = Ks.new(
    type      = "boolean",
    question  = "Don't overwrite partition",
    ask       = "no",
    parameter = "partman/confirm_nooverwrite",
    value     = "true",
    valid     = "true,false",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "kernel_image"
  config = Ks.new(
    type      = "string",
    question  = "Kernel image",
    ask       = "yes",
    parameter = "base-installer/kernel/image",
    value     = "linux-generic",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  if !install_type.match(/packer/)

    pkg_list = [
      "avahi-daemon", "nfs-common", "openssh-server", 
      "puppet", "python-software-properties", "software-properties-common",
      "curl", "sysv-rc-conf", "lsb-core"
    ]
  
    name = "additional_packages"
    config = Ks.new(
      type      = "string",
      question  = "Additional packages",
      ask       = "yes",
      parameter = "pkgsel/include",
      value     = pkg_list.join(" "),
      valid     = "",
      eval      = "no"
      )
    $q_struct[name] = config
    $q_order.push(name)

  else

    pkg_list = [ "openssh-server" ]
  
    name = "additional_packages"
    config = Ks.new(
      type      = "string",
      question  = "Additional packages",
      ask       = "yes",
      parameter = "pkgsel/include",
      value     = pkg_list.join(" "),
      valid     = "",
      eval      = "no"
      )
    $q_struct[name] = config
    $q_order.push(name)

  end

  name = "root_login"
  config = Ks.new(
    type      = "boolean",
    question  = "Root login",
    ask       = "yes",
    parameter = "passwd/root-login",
    value     = "false",
    valid     = "true,false",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "make_user"
  config = Ks.new(
    type      = "boolean",
    question  = "Create user",
    ask       = "yes",
    parameter = "passwd/make-user",
    value     = "true",
    valid     = "true,false",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "root_password"
  config = Ks.new(
    type      = "",
    question  = "Root password",
    ask       = "yes",
    parameter = "",
    value     = $default_rootpassword,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "root_crypt"
  config = Ks.new(
    type      = "password",
    question  = "Root Password Crypt",
    ask       = "yes",
    parameter = "passwd/root-password-crypted",
    value     = get_password_crypt($default_rootpassword),
    valid     = "",
    eval      = "get_password_crypt(answer)"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "admin_fullname"
  config = Ks.new(
    type      = "string",
    question  = "User full name",
    ask       = "yes",
    parameter = "passwd/user-fullname",
    value     = $default_admin_name,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "admin_username"
  config = Ks.new(
    type      = "string",
    question  = "Username",
    ask       = "yes",
    parameter = "passwd/username",
    value     = $default_admin_user,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "admin_password"
  config = Ks.new(
    type      = "",
    question  = "User password",
    ask       = "yes",
    parameter = "",
    value     = $default_adminpassword,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "admin_crypt"
  config = Ks.new(
    type      = "password",
    question  = "User Password Crypt",
    ask       = "yes",
    parameter = "passwd/user-password-crypted",
    value     = get_password_crypt($default_adminpassword),
    valid     = "",
    eval      = "get_password_crypt(answer)"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "admin_groups"
  config = Ks.new(
    type      = "string",
    question  = "User groups",
    ask       = "yes",
    parameter = "passwd/user-default-groups",
    value     = "wheel",
    valid     = "",
    eval      = ""
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "admin_home_encrypt"
  config = Ks.new(
    type      = "boolean",
    question  = "Encrypt user home directory",
    ask       = "yes",
    parameter = "user-setup/encrypt-home",
    value     = "false",
    valid     = "",
    eval      = ""
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "install_grub_mbr"
  config = Ks.new(
    type      = "boolean",
    question  = "Install grub",
    ask       = "yes",
    parameter = "grub-installer/only_debian",
    value     = "true",
    valid     = "",
    eval      = ""
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "reboot_note"
  config = Ks.new(
    type      = "note",
    question  = "Install grub",
    ask       = "no",
    parameter = "finish-install/reboot_in_progress",
    value     = "",
    valid     = "",
    eval      = ""
    )
  $q_struct[name] = config
  $q_order.push(name)

  if install_type.match(/packer/)
    script_url = "http://"+$default_gateway+":"+$default_httpd_port+"/"+install_vm+"/"+install_client+"/"+install_client+"_post.sh"
  else
    script_url = "http://"+$default_host+"/clients/"+install_service+"/"+install_client+"/"+install_client+"_post.sh"
  end

#  if !install_type.match(/packer/)

    name = "late_command"
    config = Ks.new(
      type      = "string",
      question  = "Post install commands",
      ask       = "yes",
      parameter = "preseed/late_command",
      value     = "in-target wget -O /tmp/post_install.sh #{script_url} ; in-target chmod 700 /tmp/post_install.sh ; in-target sh /tmp/post_install.sh",
      valid     = "",
      eval      = ""
      )
    $q_struct[name] = config
    $q_order.push(name)

#  end

  return
end
