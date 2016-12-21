# Cloud Formation common code

# Initiate Cloud Formation Stack

def initiate_aws_cf_client(install_access,install_secret,install_region)
  cf = Aws::CloudFormation::Client.new(
    :region             =>  install_region, 
    :access_key_id      =>  install_access,
    :secret_access_key  =>  install_secret
  )
  return cf
end 

# Get list of AWS CF stacks

def get_aws_cf_stacks(install_access,install_secret,install_region)
  cf = initiate_aws_cf_client(install_access,install_secret,install_region)
  begin
    stacks = cf.describe_stacks.stacks 
  rescue Aws::CloudFormation::Errors::AccessDenied
    handle_output("Warning:\tUser needs to be given appropriate rights in AWS IAM")
    quit()
  end
  return stacks
end

# Check if AWS CF Stack exists

def check_if_aws_cf_stack_exists(install_access,install_secret,install_region,install_name)
  exists = "no"
  stacks = get_aws_cf_stacks(install_access,install_secret,install_region)
  stacks.each do |stack|
    stack_name  = stack.stack_name
    if stack_name.match(/#{install_name}/)
      exists = "yes"
      return exists
    end
  end
  return exists
end

