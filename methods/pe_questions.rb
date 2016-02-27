# Preseed configuration questions for Windows

def populate_pe_questions(install_service,install_client,install_ip,install_mirror,install_type,install_locale,install_license,install_timezone)
  $q_struct = {}
  $q_order  = []

  name = "language"
  config = Ks.new(
    type      = "string",
    question  = "Language",
    ask       = "yes",
    parameter = "",
    value     = install_locale,
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

  name = "admin_user"
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

  name = "admin_password"
  config = Ks.new(
    type      = "string",
    question  = "Admin Password",
    ask       = "yes",
    parameter = "",
    value     = $default_admin_passwor,
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