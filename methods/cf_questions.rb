# AWS CloudFormation questions

# Populate AWS CF questions

def populate_aws_cf_questions(install_name,install_ami,install_region,install_size,install_access,install_secret,install_type,install_number,install_key,install_keyfile,install_file,install_group)
  $q_struct = {}
  $q_order  = []

  name   = "stack_name"
  config = Ks.new(
    type      = "",
    question  = "Stack Name",
    ask       = "yes",
    parameter = "",
    value     = install_name,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name   = "instance_type"
  config = Ks.new(
    type      = "",
    question  = "Instance Type",
    ask       = "yes",
    parameter = "",
    value     = $default_aws_size,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name   = "key_name"
  config = Ks.new(
    type      = "",
    question  = "Key Name",
    ask       = "yes",
    parameter = "",
    value     = install_key,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name   = "ssh_location"
  config = Ks.new(
    type      = "",
    question  = "SSH Location",
    ask       = "yes",
    parameter = "",
    value     = $default_cf_ssh_location,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name   = "template_url"
  config = Ks.new(
    type      = "",
    question  = "Template Location",
    ask       = "yes",
    parameter = "",
    value     = install_file,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name   = "security_groups"
  config = Ks.new(
    type      = "",
    question  = "Security Groups",
    ask       = "yes",
    parameter = "",
    value     = install_group,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  return
end