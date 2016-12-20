# S3 common code

# Initiate an AWS S3 Bucket connection

def initiate_aws_s3_client(install_access,install_secret,install_region)
  s3 = Aws::S3::Client.new(
    :region             =>  install_region, 
    :access_key_id      =>  install_access,
    :secret_access_key  =>  install_secret
  )
  return s3
end 

# Initiate an AWS S3 Resource connection

def initiate_aws_s3_resource(install_access,install_secret,install_region)
  s3 = Aws::S3::Resource.new(
    :region             =>  install_region, 
    :access_key_id      =>  install_access,
    :secret_access_key  =>  install_secret
  )
  return s3
end 

# Initiate an AWS S3 Resource connection

def initiate_aws_s3_bucket(install_access,install_secret,install_region)
  s3 = Aws::S3::Bucket.new(
    :region             =>  install_region, 
    :access_key_id      =>  install_access,
    :secret_access_key  =>  install_secret
  )
  return s3
end 

