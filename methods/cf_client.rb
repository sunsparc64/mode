# Code for Cloud Formation Stacks

def configure_aws_cf_stack(install_client,install_access,install_secret,install_region,install_file)
    if install_file.match(/^http/)
    download_file = "/tmp/"+File.basename(install_file)
    download_http = open(install_file)
    IO.copy_stream(download_http,download_file)
    install_file = download_file
  end
  cf = initiate_aws_cf_client(install_access,install_secret,instddall_region)
  return
end

# List AWS CF stacks

def list_aws_cf_stacks(install_client,install_access,install_secret,install_region)
  if !install_client.match(/[A-Z]|[a-z]|[0-9]/)
    install_client = "all"
  end
  stacks = get_aws_cf_stacks(install_access,install_secret,install_region)
  stacks.each do |stack|
    stack_name  = stack.stack_name
    if install_client.match(/all/) or stack_name.match(/#{install_client}/)
      stack_id    = stack.stack_id
      name_length = stack_name.length
      name_spacer = ""
      name_length.times do
        name_spacer = name_spacer+" "
      end
      handle_output("#{stack_name} id=#{stack_id}") 
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

def delete_aws_cf_stack(install_client,install_access,install_secret,install_region)
  stacks = get_aws_cf_stacks(install_access,install_secret,install_region)
  stacks.each do |stack|
    stack_name  = stack.stack_name
    if install_client.match(/all/) or stack_name.match(/#{install_client}/)
      cf = initiate_aws_cf_client(install_access,install_secret,install_region)
      handle_output("Information:\tDeleting AWS CloudFormation Stack '#{install_client}'")
      cf.delete_stack({ stack_name: install_client, })
    end
  end
  return
end
