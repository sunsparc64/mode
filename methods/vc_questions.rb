
# Code for VC

# Configuration questions for VCSA

def populate_vcsa_questions(install_server,install_datastore,install_serveradmin,install_serverpassword,install_server_network,install_client,
                            install_size,install_root_password,install_timeserver,install_admin_password,install_domainname,install_sitename,
                            install_ipfamily,install_mode,install_ip,install_netmask,install_gateway,install_nameserver,install_service,install_file)

  $q_struct = {}
  $q_order  = []

  name = "esx.hostname"
  config = Ks.new(
    type      = "string",
    question  = "ESX Server Hostname",
    ask       = "yes",
    parameter = "esx.hostname",
    value     = install_server,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "esx.datastore"
  config = Ks.new(
    type      = "string",
    question  = "Datastore",
    ask       = "yes",
    parameter = "esx.datastore",
    value     = install_datastore,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "esx.username"
  config = Ks.new(
    type      = "string",
    question  = "ESX Username",
    ask       = "yes",
    parameter = "esx.username",
    value     = install_serveradmin,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "esx.password"
  config = Ks.new(
    type      = "string",
    question  = "ESX Password",
    ask       = "no",
    parameter = "esx.password",
    value     = install_serverpassword,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "deployment.option"
  config = Ks.new(
    type      = "string",
    question  = "Deployment Option",
    ask       = "no",
    parameter = "deployment.option",
    value     = install_size,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "deployment.network"
  config = Ks.new(
    type      = "string",
    question  = "Deployment Network",
    ask       = "yes",
    parameter = "deployment.network",
    value     = install_server_network,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "appliance.name"
  config = Ks.new(
    type      = "string",
    question  = "Appliance Name",
    ask       = "yes",
    parameter = "appliance.name",
    value     = install_client,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "appliance.thin.disk.mode"
  config = Ks.new(
    type      = "boolean",
    question  = "Appliance Disk Mode",
    ask       = "yes",
    parameter = "appliance.thin.disk.mode",
    value     = "true",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "root.password"
  config = Ks.new(
    type      = "string",
    question  = "Root Password",
    ask       = "yes",
    parameter = "root.password",
    value     = install_root_password,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "ssh.enable"
  config = Ks.new(
    type      = "boolean",
    question  = "SSH Enable",
    ask       = "yes",
    parameter = "ssh.enable",
    value     = $default_sshenable,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "ntp.servers"
  config = Ks.new(
    type      = "string",
    question  = "NTP Servers",
    ask       = "yes",
    parameter = "ntp.servers",
    value     = install_timeserver,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "password"
  config = Ks.new(
    type      = "string",
    question  = "SSO password",
    ask       = "yes",
    parameter = "password",
    value     = install_admin_password,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "domain-name"
  config = Ks.new(
    type      = "string",
    question  = "NTP Servers",
    ask       = "yes",
    parameter = "ntp.servers",
    value     = install_domainname,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "site-name"
  config = Ks.new(
    type      = "string",
    question  = "Site Name",
    ask       = "yes",
    parameter = "ntp.servers",
    value     = install_domainname.split(/\./)[0],
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "ip.family"
  config = Ks.new(
    type      = "string",
    question  = "IP Family",
    ask       = "yes",
    parameter = "ip.family",
    value     = $default_ipfamily,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "mode"
  config = Ks.new(
    type      = "string",
    question  = "IP Configuration",
    ask       = "yes",
    parameter = "mode",
    value     = "static",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "ip"
  config = Ks.new(
    type      = "string",
    question  = "IP Address",
    ask       = "yes",
    parameter = "ip",
    value     = install_ip,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "prefix"
  config = Ks.new(
    type      = "string",
    question  = "Subnet Mask",
    ask       = "yes",
    parameter = "prefix",
    value     = install_netmask,
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

  name = "dns.servers"
  config = Ks.new(
    type      = "string",
    question  = "Nameserver(s)",
    ask       = "yes",
    parameter = "dns.servers",
    value     = install_nameserver,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "system.name"
  config = Ks.new(
    type      = "string",
    question  = "Hostname",
    ask       = "yes",
    parameter = "system.name",
    value     = install_ip,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  return
end
