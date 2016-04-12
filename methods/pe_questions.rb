# Preseed configuration questions for Windows

def populate_pe_questions(install_service,install_client,install_ip,install_mirror,install_type,install_locale,install_license,
                          install_timezone,install_arch,install_label,install_shell,install_vm,install_network)
  if !install_shell.match(/[a-z]/)
    install_shell = $default_install_shell
  end
  if install_label.match(/2012/)
    if install_vm.match(/fusion/)
      network_name = "Ethernet0"
    else
      network_name = "Ethernet"
    end
  else
    network_name = "Local Area Connection"
  end

  $q_struct = {}
  $q_order  = []

  name = "install_label"
  config = Ks.new(
    type      = "string",
    question  = "Installation Label",
    ask       = "yes",
    parameter = "",
    value     = install_label,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "cpu_arch"
  config = Ks.new(
    type      = "string",
    question  = "CPU Architecture",
    ask       = "yes",
    parameter = "",
    value     = install_arch.gsub(/x86_64/,"amd64"),
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "boot_disk_size"
  config = Ks.new(
    type      = "string",
    question  = "Boot disk size",
    ask       = "yes",
    parameter = "",
    value     = $default_boot_disk_size,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "language"
  config = Ks.new(
    type      = "string",
    question  = "Language",
    ask       = "yes",
    parameter = "",
    value     = install_locale.gsub(/_/,"-"),
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
    parameter = "",
    value     = install_locale.gsub(/_/,"-"),
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "organisation"
  config = Ks.new(
    type      = "string",
    question  = "Organisation",
    ask       = "yes",
    parameter = "",
    value     = $default_organisation,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "timezone"
  config = Ks.new(
    type      = "string",
    question  = "Time Zone",
    ask       = "yes",
    parameter = "",
    value     = install_timezone,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "admin_username"
  config = Ks.new(
    type      = "string",
    question  = "Admin Username",
    ask       = "yes",
    parameter = "",
    value     = $default_admin_user,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "admin_fullname"
  config = Ks.new(
    type      = "string",
    question  = "Admin Fullname",
    ask       = "yes",
    parameter = "",
    value     = $default_admin_name,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "admin_password"
  config = Ks.new(
    type      = "string",
    question  = "Admin Password",
    ask       = "yes",
    parameter = "",
    value     = $default_admin_password,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "license_key"
  config = Ks.new(
    type      = "string",
    question  = "License Key",
    ask       = "yes",
    parameter = "",
    value     = install_license,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "search_domain"
  config = Ks.new(
    type      = "string",
    question  = "Search Domain",
    ask       = "yes",
    parameter = "",
    value     = $default_domainname,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "install_shell"
  config = Ks.new(
    type      = "string",
    question  = "Install Shell",
    ask       = "yes",
    parameter = "",
    value     = install_shell,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "network_type"
  config = Ks.new(
    type      = "string",
    question  = "Network Type",
    ask       = "yes",
    parameter = "",
    value     = install_network,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  install_network = $q_struct["network_type"].value

  if install_network.match(/hostonly|bridged/)

    name = "network_name"
    config = Ks.new(
      type      = "string",
      question  = "Network Name",
      ask       = "yes",
      parameter = "",
      value     = network_name,
      valid     = "",
      eval      = "no"
      )
    $q_struct[name] = config
    $q_order.push(name)

    name = "ip_address"
    config = Ks.new(
      type      = "string",
      question  = "IP Address",
      ask       = "yes",
      parameter = "",
      value     = install_ip,
      valid     = "",
      eval      = "no"
      )
    $q_struct[name] = config
    $q_order.push(name)

    name = "gateway_address"
    config = Ks.new(
      type      = "string",
      question  = "Gateway Address",
      ask       = "yes",
      parameter = "",
      value     = $default_gateway_ip,
      valid     = "",
      eval      = "no"
      )
    $q_struct[name] = config
    $q_order.push(name)

    name = "network_cidr"
    config = Ks.new(
      type      = "string",
      question  = "Network CIDR",
      ask       = "yes",
      parameter = "",
      value     = $default_cidr,
      valid     = "",
      eval      = "no"
      )
    $q_struct[name] = config
    $q_order.push(name)

    name = "nameserver_ip"
    config = Ks.new(
      type      = "string",
      question  = "Nameserver IP Address",
      ask       = "yes",
      parameter = "",
      value     = $default_nameserver,
      valid     = "",
      eval      = "no"
      )
    $q_struct[name] = config
    $q_order.push(name)

  end
  return
end
