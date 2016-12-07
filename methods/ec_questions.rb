# Questions for AWS

# Get AWS AMI name

def get_aws_ami_name(install_client,install_region)
	if !install_client.match(/#{$default_aws_suffix}/)
	  value = install_client+"-"+$default_aws_suffix+"-"+install_region
	else
		value = install_client
	end
  return value
end

# Populate AWS questions

def populate_aws_questions(install_client,install_ami,install_region,install_size,install_access,install_secret,user_data_file)
  $q_struct = {}
  $q_order  = []

  name   = "name"
  config = Ks.new(
    type      = "",
    question  = "AMI Name",
    ask       = "yes",
    parameter = "",
    value     = "aws",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name   = "access_key"
  config = Ks.new(
    type      = "",
    question  = "Access Key",
    ask       = "yes",
    parameter = "",
    value     = install_access,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name   = "secret_key"
  config = Ks.new(
    type      = "",
    question  = "Secret Key",
    ask       = "yes",
    parameter = "",
    value     = install_secret,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name   = "type"
  config = Ks.new(
    type      = "",
    question  = "AWS Type",
    ask       = "yes",
    parameter = "",
    value     = $default_aws_type,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name   = "source_ami"
  config = Ks.new(
    type      = "",
    question  = "Source AMI",
    ask       = "yes",
    parameter = "",
    value     = install_ami,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name   = "region"
  config = Ks.new(
    type      = "",
    question  = "Region",
    ask       = "yes",
    parameter = "",
    value     = install_region,
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
    value     = install_size,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name   = "ssh_username"
  config = Ks.new(
    type      = "",
    question  = "SSH Username",
    ask       = "yes",
    parameter = "",
    value     = $default_admin_user,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name   = "ami_name"
  config = Ks.new(
    type      = "",
    question  = "AMI Name",
    ask       = "yes",
    parameter = "",
    value     = get_aws_ami_name(install_client,install_region),
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name   = "user_data_file"
  config = Ks.new(
    type      = "",
    question  = "User Data File",
    ask       = "yes",
    parameter = "",
    value     = user_data_file,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  return
end