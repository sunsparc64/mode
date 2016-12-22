# Code for CloudFormation Stacks

# List AWS CF stacks

def list_aws_cf_stacks(install_client,install_access,install_secret,install_region)
  if !install_client.match(/[A-Z]|[a-z]|[0-9]/)
    install_client = "all"
  end
  stacks = get_aws_cf_stacks(install_access,install_secret,install_region)
  stacks.each do |stack|
    stack_name  = stack.stack_name
    if install_client.match(/all/) or stack_name.match(/#{install_client}/)
      stack_id     = stack.stack_id
      stack_status = stack.stack_status
      name_length  = stack_name.length
      name_spacer  = ""
      name_length.times do
        name_spacer = name_spacer+" "
      end
      handle_output("#{stack_name} id=#{stack_id} stack_status=#{stack_status}") 
      instance_id = ""
      public_ip   = ""
      region_id   = ""
      stack.outputs.each do |output|
        if output.output_key.match(/InstanceId/)
          instance_id = output.output_value
        end
        if output.output_key.match(/PublicIP/)
          public_ip = output.output_value
        end
        if output.output_key.match(/AZ/)
          region_id = output.output_value
        end
        if output.output_key.match(/DNS/)
          public_dns = output.output_value
          handle_output("#{name_spacer} id=#{instance_id} ip=#{public_ip} dns=#{public_dns} az=#{region_id}") 
        end
      end
    end
  end
  return
end

# Delete AWS CF Stack

def delete_aws_cf_stack(install_access,install_secret,install_region,install_stack)
  if !install_stack.match(/[A-Z]|[a-z]|[0-9]/)
    handle_output("Warning:\tNo AWS CloudFormation Stack Name given")
    quit()
  end
  stacks = get_aws_cf_stacks(install_access,install_secret,install_region)
  stacks.each do |stack|
    stack_name  = stack.stack_name
    if install_stack.match(/all/) or stack_name.match(/#{install_stack}/)
      cf = initiate_aws_cf_client(install_access,install_secret,install_region)
      handle_output("Information:\tDeleting AWS CloudFormation Stack '#{stack_name}'")
      begin
        cf.delete_stack({ stack_name: stack_name, })
      rescue Aws::CloudFormation::Errors::AccessDenied
        handle_output("Warning:\tUser needs to be given appropriate rights in AWS IAM")
        quit()
      end
    end
  end
  return
end

# Create AWS CF Stack

def create_aws_cf_stack(install_access,install_secret,install_region)
  stack_name      = $q_struct["stack_name"].value
  instance_type   = $q_struct["instance_type"].value
  key_name        = $q_struct["key_name"].value
  ssh_location    = $q_struct["ssh_location"].value
  template_url    = $q_struct["template_url"].value
  security_groups = $q_struct["security_groups"].value
  cf = initiate_aws_cf_client(install_access,install_secret,install_region)
  handle_output("Information:\tCreating AWS CloudFormation Stack '#{stack_name}'")
  begin
    stack_id = cf.create_stack({
      stack_name:   stack_name,
      template_url: template_url,
      parameters: [
        {
          parameter_key:    "InstanceType",
          parameter_value:  instance_type,
        },
        {
          parameter_key:    "KeyName",
          parameter_value:  key_name,
        },
        {
          parameter_key:    "SSHLocation",
          parameter_value:  ssh_location,
        },
        #{
        #  parameter_key:    "SecurityGroups",
        #  parameter_value:  security_groups,
        #},
      ],
    })
  rescue Aws::CloudFormation::Errors::AccessDenied
    handle_output("Warning:\tUser needs to be given appropriate rights in AWS IAM")
    quit()
  end
  stack_id = stack_id.stack_id
  handle_output("Information:\tStack created with ID: #{stack_id}")
  return
end

# Create AWS CF Stack Config

def create_aws_cf_stack_config(install_name,install_ami,install_region,install_size,install_access,install_secret,install_type,install_number,install_key,install_keyfile,install_file,install_group,install_bucket)
  populate_aws_cf_questions(install_name,install_size,install_key,install_file,install_group)
  install_service = "aws"
  process_questions(install_service)
  exists = check_if_aws_cf_stack_exists(install_access,install_secret,install_region,install_name)
  if exists == "yes"
    handle_output("Warning:\tAWS CloudFormation Stack '#{install_name}' already exists")
    quit()
  end
  exists = check_if_aws_key_pair_exists(install_access,install_secret,install_region,install_key)
  if exists == "no"
    create_aws_key_pair(install_access,install_secret,install_region,install_key)
  else
    exists = check_if_aws_ssh_key_file_exists(install_key)
    if exists == "no"
      handle_output("Warning:\tSSH Key file '#{aws_ssh_key_file}' for AWS Key Pair '#{install_key}' does not exist")
      quit()
    end
  end
end

# Create AWS CF Stack from template

def configure_aws_cf_stack(install_name,install_ami,install_region,install_size,install_access,install_secret,install_type,install_number,install_key,install_keyfile,install_file,install_group,install_bucket)
  if !install_name.match(/[A-Z]|[a-z]|[0-9]/) or install_name.match(/^none$/)
    handle_output("Warning:\tNo name specified for AWS CloudFormation Stack")
    quit()
  end
  if !install_file.match(/[A-Z]|[a-z]|[0-9]/)
    if !install_bucket.match(/[A-Z]|[a-z]|[0-9]/)
      if !install_object.match(/[A-Z]|[a-z]|[0-9]/)
        handle_output("Warning:\tNo file, bucket, or object specified for AWS CloudFormation Stack")
        quit()
      end
    else
      install_file = get_s3_bucket_private_url(install_access,install_secret,install_region,install_bucket,install_key)
    end
  end
  if !install_key.match(/[A-Z]|[a-z]|[0-9]/)
    handle_output("Warning:\tNo Key Name given")
    if !install_keyfile.match(/[A-Z]|[a-z]|[0-9]/)
      install_key = install_name
    else
      install_key = File.basename(install_keyfile)
      install_key = install_key.split(/\./)[0..-2].join
    end
    handle_output("Information:\tSetting Key Name to #{install_key}")
  end
  if !install_key.match(/[A-Z]|[a-z]|[0-9]/)
    install_group = install_name
  end
  if $nosuffix == 0
    install_name  = get_aws_uniq_name(install_name,install_region)
    install_key   = get_aws_uniq_name(install_key,install_region)
    install_group = get_aws_uniq_name(install_group,install_region)
  end
  if !install_keyfile.match(/[A-Z]|[a-z]|[0-9]/)
    install_keyfile = $default_aws_ssh_key_dir+"/"+install_key+".pem"
    handle_output("Information:\tSetting Key file to #{install_keyfile}")
  end
  create_aws_cf_stack_config(install_name,install_ami,install_region,install_size,install_access,install_secret,install_type,install_number,install_key,install_keyfile,install_file,install_group,install_bucket)
  create_aws_cf_stack(install_access,install_secret,install_region)
  return
end

