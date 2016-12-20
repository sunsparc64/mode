# S3 related code

# Create AWS S3 bucket

def create_aws_s3_bucket(install_access,install_secret,install_region,install_bucket)
  s3 = initiate_aws_s3_resource(install_access,install_secret,install_region)
  if s3.bucket(install_bucket).exists?
    handle_output("Information:\tBucket: #{install_bucket} already exists")
    s3 = initiate_aws_s3_client(install_access,install_secret,install_region)
    begin
      s3.head_bucket({ bucket: install_bucket, })
    rescue
      handle_output("Warning:\tDo not have permissions to access bucket: #{install_bucket}")
      quit()
    end
  else
    handle_output("Information:\tCreating S3 bucket: #{install_bucket}")
    s3.create_bucket({ acl: install_acl, bucket: install_bucket, create_bucket_configuration: { location_constraint: install_region, }, })
  end
  return s3
end

# Get AWS S3 bucket ACL

def get_aws_s3_bucket_acl(install_access,install_secret,install_region,install_bucket)
  s3  = initiate_aws_s3_client(install_access,install_secret,install_region)
  begin
    acl = s3.get_bucket_acl(bucket: install_bucket)
  rescue Aws::S3::Errors::AccessDenied
    handle_output("Warning:\tUser needs to be given appropriate rights in AWS IAM")
    quit()
  end
  return acl
end

# Show AWS S3 bucket ACL

def show_aws_s3_bucket_acl(install_access,install_secret,install_region,install_bucket)
  acl    = get_aws_s3_bucket_acl(install_access,install_secret,install_region,install_bucket)
  owner  = acl.owner.display_name
  handle_output("#{install_bucket}\towner=#{owner}")
  acl.grants.each_with_index do |grantee,counter|
    owner = grantee[0].display_name
    email = grantee[0].email_address
    id    = grantee[0].id
    type  = grantee[0].type
    uri   = grantee[0].uri
    perms = grantee.permission
    handle_output("grants[#{counter}]\towner=#{owner}\temail=#{email}\ttype=#{type}\turi=#{uri}\tid=#{id}\tperms=#{perms}")
  end
  return
end

# Set AWS S3 bucket ACL

def set_aws_s3_bucket_acl(install_access,install_secret,install_region,install_bucket,install_email,install_grant,install_perms)
  s3 = initiate_aws_s3_resource(install_access,install_secret,install_region)
  return
end

# Upload file to S3 bucker

def upload_file_to_aws_bucket(install_access,install_secret,install_region,install_file,install_key,install_bucket)
  if install_file.match(/^http/)
    download_file = "/tmp/"+File.basename(install_file)
    download_http = open(install_file)
    IO.copy_stream(download_http,download_file)
    install_file = download_file
  end
  if !File.exist?(install_file)
    handle_output("Warning:\tFile '#{install_file}' does not exist")
    quit()
  end
  if !install_bucket.match(/[A-Z]|[a-z]|[0-9]/)
    handle_output("Warning:\tNo Bucket name given")
    install_bucket =  $default_aws_bucket 
    handle_output("Information:\tSetting Bucket to default bucket '#{install_bucket}'")
  end
  exists = check_if_aws_bucket_exists(install_access,install_secret,install_region,install_bucket)
  if exists == "no"
     s3 = create_aws_s3_bucket(install_access,install_secret,install_region,install_bucket)
  end
  if !install_key.match(/[A-Z]|[a-z]|[0-9]/)
    install_key = $default_aws_base_object+"/"+File.basename(install_file)
  end
  s3 = initiate_aws_s3_resource(install_access,install_secret,install_region)
  handle_output("Information:\tUploading: File '#{install_file}' with key: '#{install_key}' to bucket: '#{install_bucket}'")
  s3.bucket(install_bucket).object(install_key).upload_file(install_file)
  return
end

# Download file from S3 bucket

def download_file_from_aws_bucket(install_access,install_secret,install_region,install_file,install_key,install_bucket)
  if !install_bucket.match(/[A-Z]|[a-z]|[0-9]/)
    handle_output("Warning:\tNo Bucket name given")
    install_bucket =  $default_aws_bucket 
    handle_output("Information:\tSetting Bucket to default bucket '#{install_bucket}'")
  end
  if !install_key.match(/[A-Z]|[a-z]|[0-9]/)
    install_key = $default_aws_base_object+"/"+File.basename(install_file)
  end
  if install_file.match(/\//)
    dir_name = Pathname.new(install_file)
    dir_name = dir_name.dirname
    if !File.directory?(dir_name) and !File.symlink?(dir_name)
      FileUtils.mkdir_p(dir_name)
    end
  end
  s3 = initiate_aws_s3_client(install_access,install_secret,install_region)
  handle_output("Information:\tDownloading: Key '#{install_key}' from bucket: '#{install_bucket}' to file: '#{install_file}'")
  s3.get_object({ bucket: install_bucket, key: install_key, }, target: install_file )
  return
end

# Get buckets

def get_aws_buckets(install_access,install_secret,install_region)
  s3 = initiate_aws_s3_client(install_access,install_secret,install_region)
  begin
    buckets = s3.list_buckets.buckets
  rescue Aws::S3::Errors::AccessDenied
    handle_output("Warning:\tUser needs to be given appropriate rights in AWS IAM")
    quit()
  end
  return buckets
end

# List AWS buckets

def list_aws_buckets(install_bucket,install_access,install_secret,install_region)
  if !install_bucket.match(/[A-Z]|[a-z]|[0-9]/)
    install_bucket = "all"
  end
  buckets = get_aws_buckets(install_access,install_secret,install_region)
  buckets.each do |bucket|
    bucket_name = bucket.name
    if install_bucket.match(/^all$|#{bucket_name}/)
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

# Check if AWS bucket exists

def check_if_aws_bucket_exists(install_access,install_secret,install_region,install_bucket)
  exists  = "no"
  buckets = get_aws_buckets(install_access,install_secret,install_region)
  buckets.each do |bucket|
    bucket_name = bucket.name
    if bucket_name.match(/#{install_bucket}/)
      exists = "yes"
      return exists
    end
  end
  return exists
end
