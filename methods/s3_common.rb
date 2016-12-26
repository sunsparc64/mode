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

# Initiate an AWS S3 Object connection

def initiate_aws_s3_object(install_access,install_secret,install_region)
  s3 = Aws::S3::Object.new(
    :region             =>  install_region, 
    :access_key_id      =>  install_access,
    :secret_access_key  =>  install_secret
  )
  return s3
end 

# Initiate an AWS S3 Presigner connection

def initiate_aws_s3_presigner(install_access,install_secret,install_region)
  s3 = Aws::S3::Presigner.new(
    :region             =>  install_region, 
    :access_key_id      =>  install_access,
    :secret_access_key  =>  install_secret
  )
  return s3
end 

# Get private URL for S3 bucket item

def get_s3_bucket_private_url(install_access,install_secret,install_region,install_bucket,install_object)
 s3  = initiate_aws_s3_presigner(install_access,install_secret,install_region)
 url = s3.presigned_url( :get_object, bucket: install_bucket, key: install_object )
 return url
end

# Get public URL for S3 bucket item

def get_s3_bucket_public_url(install_access,install_secret,install_region,install_bucket,install_object)
 s3  = initiate_aws_s3_resource(install_access,install_secret,install_region)
 url = s3.bucket(install_bucket).object(install_object).public_url
 return url
end

# Show URL for S3 bucket

def show_s3_bucket_url(install_access,install_secret,install_region,install_bucket,install_object,install_type)
  if install_type.match(/public/)
    url = get_s3_bucket_public_url(install_access,install_secret,install_region,install_bucket,install_object)
  else
    url = get_s3_bucket_private_url(install_access,install_secret,install_region,install_bucket,install_object)
  end
  handle_output(url)
  return
end

# List AWS buckets

def list_aws_buckets(install_bucket,install_access,install_secret,install_region)
  buckets = get_aws_buckets(install_access,install_secret,install_region)
  buckets.each do |bucket|
    bucket_name = bucket.name
    if install_bucket.match(/^all$|#{bucket_name}|^none$/)
      bucket_date = bucket.creation_date
      handle_output("#{bucket_name}\tcreated=#{bucket_date}")
    end
  end
  return
end

# List AWS bucket objects

def list_aws_bucket_objects(install_bucket,install_access,install_secret,install_region)
  buckets = get_aws_buckets(install_access,install_secret,install_region)
  buckets.each do |bucket|
    bucket_name = bucket.name
    if install_bucket.match(/^all$|#{bucket_name}/)
      handle_output("")
      handle_output("#{bucket_name}:")
      s3 = initiate_aws_s3_client(install_access,install_secret,install_region)
      objects = s3.list_objects_v2({ bucket: bucket_name })
      objects.contents.each do |object|
        object_key = object.key
        handle_output(object_key)
      end
    end
  end
  return
end
