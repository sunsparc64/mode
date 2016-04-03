# Preseed configuration questions for Windows

def populate_pe_questions(install_service,install_client,install_ip,install_mirror,install_type,install_locale,install_license,install_timezone,install_arch,install_label)
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

  return
end
