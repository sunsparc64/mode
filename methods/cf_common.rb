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