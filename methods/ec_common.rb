# AWS common code

# Initiates AWS EC2 Image connection

def initiate_aws_ec2_image(install_access,install_secret,install_region)
  ec2 = Aws::EC2::Image.new(
    :region             =>  install_region, 
    :access_key_id      =>  install_access,
    :secret_access_key  =>  install_secret
  )
  return ec2
end

# Initiate AWS EC2 Instance connection

def initiate_aws_ec2_instance(install_access,install_secret,install_region)
  ec2 = Aws::EC2::Instance.new(
    :region             =>  install_region, 
    :access_key_id      =>  install_access,
    :secret_access_key  =>  install_secret
  )
  return ec2
end

# Initiate AWS EC2 Client connection

def initiate_aws_ec2_client(install_access,install_secret,install_region)
  ec2 = Aws::EC2::Client.new(
    :region             =>  install_region, 
    :access_key_id      =>  install_access,
    :secret_access_key  =>  install_secret
  )
  return ec2
end

# Initiate an AWS EC2 Resource connection

def initiate_aws_ec2_resource(install_access,install_secret,install_region)
  ec2 = Aws::EC2::Resource.new(
    :region             =>  install_region, 
    :access_key_id      =>  install_access,
    :secret_access_key  =>  install_secret
  )
  return ec2
end 

# Initiate an EWS EC2 KeyPair connection

def initiate_aws_ec2_resource(install_access,install_secret,install_region)
  ec2 = Aws::EC2::KeyPair.new(
    :region             =>  install_region, 
    :access_key_id      =>  install_access,
    :secret_access_key  =>  install_secret
  )
  return ec2
end 

# Initiate IAM client connection

def initiate_aws_iam_client(install_access,install_secret,install_region)
  iam = Aws::IAM::Client.new(
    :region             =>  install_region, 
    :access_key_id      =>  install_access,
    :secret_access_key  =>  install_secret
  )
  return iam
end 

# Initiate IAM client connection

def initiate_aws_cw_client(install_access,install_secret,install_region)
  cw = Aws::CloudWatch::Client.new(
    :region             =>  install_region, 
    :access_key_id      =>  install_access,
    :secret_access_key  =>  install_secret
  )
  return cw
end


# Check AWS VM exists - Dummy function for packer

def check_aws_vm_exists(install_name)
  exists = "no"
  return exists
end

# Get Prefix List ID


def get_aws_prefix_list_id(install_access,install_secret,install_region)
  ec2 = initiate_aws_ec2_client(install_access,install_secret,install_region)
  id  = ec2.describe_prefix_lists.prefix_lists[0].prefix_list_id
  return id
end

# Get AWS billing

def get_aws_billing(install_access,install_secret,install_region)
  cw    = initiate_aws_cw_client(install_access,install_secret,install_region)
  stats = cw.get_metric_statistics({
   :namespace   => 'AWS/Billing',
   :metric_name => 'EstimatedCharges',
   :statistics  => ['Maximum'],
   :dimensions  => [{ :name => 'Currency', :value => 'AUD' }],
   :start_time  => (Time.now - (8*60*60)).iso8601,
   :end_time    => Time.now.iso8601,
   :period      => 300
  })
  pp stats
  return
end

# Get AWS snapshots

def get_aws_snapshots(install_access,install_secret,install_region)
  ec2 = initiate_aws_ec2_client(install_access,install_secret,install_region)
  begin
    snapshots = ec2.describe_snapshots.snapshots
  rescue Aws::EC2::Errors::AccessDenied
    handle_output("Warning:\tUser needs to be given appropriate rights in AWS IAM")
    quit()
  end
  return snapshots
end

# List AWS snapshots

def list_aws_snapshots(install_access,install_secret,install_region,install_snapshot)
  owner_id  = get_aws_owner_id(install_access,install_secret,install_region)
  snapshots = get_aws_snapshots(install_access,install_secret,install_region)
  snapshots.each do |snapshot|
    snapshot_id    = snapshot.snapshot_id
    snapshot_owner = snapshot.owner_id
    if snapshot_owner == owner_id
      if install_snapshot.match(/[0-9]/)
        if snapshot_id.match(/^#{install_snapshot}$/)
          handle_output("#{snapshot_id}")
        end
      else
        handle_output("#{snapshot_id}")
      end
    end
  end
  return
end

# Delete AWS snapshot

def delete_aws_snapshot(install_client,install_access,install_secret,install_region,install_snapshot)
  if !install_snapshot.match(/[A-Z]|[a-z]|[0-9]/)
    handle_output("Warning:\tNo Snapshot ID specified")
    return
  end
  owner_id  = get_aws_owner_id(install_access,install_secret,install_region)
  snapshots = get_aws_snapshots(install_access,install_secret,install_region)
  ec2       = initiate_aws_ec2_client(install_access,install_secret,install_region)
  snapshots.each do |snapshot|
    snapshot_id     = snapshot.snapshot_id
    snapshot_owner  = snapshot.owner_id
    if snapshot_owner == owner_id
      if snapshot_id.match(/^#{install_snapshot}$/) or install_snapshot == "all"
        handle_output("Information:\tDeleting Snapshot ID #{snapshot_id}")
        begin
          ec2.delete_snapshot({snapshot_id: snapshot_id})
        rescue 
          handle_output("Warning:\tUnable to delete Snapshot ID #{snapshot_id}")
        end
      end
    end
  end
  return
end

# Get AWS unique name

def get_aws_uniq_name(install_name,install_region)
  if !install_name.match(/#{$default_aws_suffix}/)
    value = install_name+"-"+$default_aws_suffix+"-"+install_region
  else
    value = install_name
  end
  return value
end

# Get AWS reservations

def get_aws_reservations(install_access,install_secret,install_region)
  ec2 = initiate_aws_ec2_client(install_access,install_secret,install_region)
  begin
    reservations = ec2.describe_instances({ }).reservations
  rescue Aws::EC2::Errors::AccessDenied
    handle_output("Warning:\tUser needs to be given appropriate rights in AWS IAM")
    quit()
  end
  return ec2,reservations
end

# Get AWS Key Pairs

def get_aws_key_pairs(install_access,install_secret,install_region)
  ec2 = initiate_aws_ec2_client(install_access,install_secret,install_region)
  begin
    key_pairs = ec2.describe_key_pairs({ }).key_pairs
  rescue Aws::EC2::Errors::AccessDenied
    handle_output("Warning:\tUser needs to be given appropriate rights in AWS IAM")
    quit()
  end
  return ec2,key_pairs
end

# Get instance security group 

def get_aws_instance_security_group(install_access,install_secret,install_region,install_id)
  group = "none"
  ec2,reservations = get_aws_reservations(install_access,install_secret,install_region)
  reservations.each do |reservation|
    reservation["instances"].each do |instance|
      instance_id = instance.instance_id
      group       = instance.security_groups[0].group_name
      if instance_id.match(/#{install_id}/)
        return group
      end
    end
  end
  return group
end

# Check if AWS EC2 security group exists


def check_if_aws_security_group_exists(install_access,install_secret,install_region,install_group)
  exists = "no"
  groups = get_aws_security_groups(install_access,install_secret,install_region)
  groups.each do |group|
    group_name = group.group_name
    if install_group.match(/^#{group_name}$/)
      exists = "yes"
      return exists
    end
  end
  return exists
end

# Get AWS EC2 security groups

def get_aws_security_groups(install_access,install_secret,install_region)
  ec2    = initiate_aws_ec2_client(install_access,install_secret,install_region)
  groups = ec2.describe_security_groups.security_groups 
  return groups
end

# Get AWS EC2 security group IF

def get_aws_security_group_id(install_access,install_secret,install_region,install_group)
  group_id = "none"
  groups   = get_aws_security_groups(install_access,install_secret,install_region)
  groups.each do |group|
    group_name = group.group_name
    group_id   = group.group_id
    if install_group.match(/^#{group_name}$/)
      return group_id
    end
  end
  return group_id
end

# Add ingress rule to AWS EC2 security group

def remove_ingress_rule_from_aws_security_group(install_access,install_secret,install_region,install_group,install_proto,install_to,install_from,install_cidr)
  ec2 = initiate_aws_ec2_client(install_access,install_secret,install_region)
  prefix_list_id = get_aws_prefix_list_id(install_access,install_secret,install_region)
  handle_output("Information:\tDeleting ingress rule to security group #{install_group} (Protocol: #{install_proto} From: #{install_from} To: #{install_to} CIDR: #{install_cidr})")
  ec2.revoke_security_group_ingress({
    group_id: install_group,
    ip_permissions: [
      {
        ip_protocol:  install_proto,
        from_port:    install_from,
        to_port:      install_to,
        ip_ranges: [
          {
            cidr_ip: install_cidr,
          },
        ],
      },
    ],
  })
  return
end

# Add egress rule to AWS EC2 security group

def remove_egress_rule_from_aws_security_group(install_access,install_secret,install_region,install_group,install_proto,install_to,install_from,install_cidr)
  ec2 = initiate_aws_ec2_client(install_access,install_secret,install_region)
  prefix_list_id = get_aws_prefix_list_id(install_access,install_secret,install_region)
  handle_output("Information:\tDeleting egress rule to security group #{install_group} (Protocol: #{install_proto} From: #{install_from} To: #{install_to} CIDR: #{install_cidr})")
  ec2.revoke_security_group_egress({
    group_id: install_group,
    ip_permissions: [
      {
        ip_protocol:  install_proto,
        from_port:    install_from,
        to_port:      install_to,
        ip_ranges: [
          {
            cidr_ip: install_cidr,
          },
        ],
      },
    ],
  })
  return
end

# Add rule to AWS EC2 security group

def remove_rule_from_aws_security_group(install_access,install_secret,install_region,install_group,install_proto,install_to,install_from,install_cidr,install_dir)
  if !install_group.match(/^sg/)
    install_group = get_aws_security_group_id(install_access,install_secret,install_region,install_group)
  end
  if install_dir.match(/egress/)
    remove_egress_rule_from_aws_security_group(install_access,install_secret,install_region,install_group,install_proto,install_to,install_from,install_cidr)
  else
    remove_ingress_rule_from_aws_security_group(install_access,install_secret,install_region,install_group,install_proto,install_to,install_from,install_cidr)
  end
  return
end

# Add ingress rule to AWS EC2 security group

def add_ingress_rule_to_aws_security_group(install_access,install_secret,install_region,install_group,install_proto,install_to,install_from,install_cidr)
  ec2 = initiate_aws_ec2_client(install_access,install_secret,install_region)
  prefix_list_id = get_aws_prefix_list_id(install_access,install_secret,install_region)
  handle_output("Information:\tAdding ingress rule to security group #{install_group} (Protocol: #{install_proto} From: #{install_from} To: #{install_to} CIDR: #{install_cidr})")
  begin
    ec2.authorize_security_group_ingress({
      group_id: install_group,
      ip_permissions: [
        {
          ip_protocol:  install_proto,
          from_port:    install_from,
          to_port:      install_to,
          ip_ranges: [
            {
              cidr_ip: install_cidr,
            },
          ],
        },
      ],
    })
  rescue Aws::EC2::Errors::InvalidPermissionDuplicate
    handle_output("Warning:\tRule already exists")
  end
  return
end

# Add egress rule to AWS EC2 security group

def add_egress_rule_to_aws_security_group(install_access,install_secret,install_region,install_group,install_proto,install_to,install_from,install_cidr)
  ec2 = initiate_aws_ec2_client(install_access,install_secret,install_region)
  prefix_list_id = get_aws_prefix_list_id(install_access,install_secret,install_region)
  handle_output("Information:\tAdding egress rule to security group #{install_group} (Protocol: #{install_proto} From: #{install_from} To: #{install_to} CIDR: #{install_cidr})")
  begin
    ec2.authorize_security_group_egress({
      group_id: install_group,
      ip_permissions: [
        {
          ip_protocol:  install_proto,
          from_port:    install_from,
          to_port:      install_to,
          ip_ranges: [
            {
              cidr_ip: install_cidr,
            },
          ],
        },
      ],
    })
  rescue Aws::EC2::Errors::InvalidPermissionDuplicate
    handle_output("Warning:\tRule already exists")
  end
  return
end

# Add rule to AWS EC2 security group

def add_rule_to_aws_security_group(install_access,install_secret,install_region,install_group,install_proto,install_to,install_from,install_cidr,install_dir)
  if !install_group.match(/^sg/)
    install_group = get_aws_security_group_id(install_access,install_secret,install_region,install_group)
  end
  if install_dir.match(/egress/)
    add_egress_rule_to_aws_security_group(install_access,install_secret,install_region,install_group,install_proto,install_to,install_from,install_cidr)
  else
    add_ingress_rule_to_aws_security_group(install_access,install_secret,install_region,install_group,install_proto,install_to,install_from,install_cidr)
  end
  return
end

# Create AWS EC2 security group

def create_aws_security_group(install_access,install_secret,install_region,install_group,install_desc)
  if !install_desc.match(/[A-Z]|[a-z]|[0-9]/)
    handle_output("Information:\tNo description given, using group name '#{install_group}'")
    install_desc = install_group
  end
  exists = check_if_aws_security_group_exists(install_access,install_secret,install_region,install_group)
  if exists == "yes"
    handle_output("Warning:\tSecurity group '#{install_group}' already exists")
  else
    handle_output("Information:\tCreating security group '#{install_group}'")
    ec2 = initiate_aws_ec2_client(install_access,install_secret,install_region)
    ec2.create_security_group({ group_name: install_group, description: install_desc })
  end
  return
end

# Delete AWS EC2 security group

def delete_aws_security_group(install_access,install_secret,install_region,install_group)
  exists = check_if_aws_security_group_exists(install_access,install_secret,install_region,install_group)
  if exists == "yes"
    handle_output("Information:\tDeleting security group '#{install_group}'")
    ec2 = initiate_aws_ec2_client(install_access,install_secret,install_region)
    ec2.delete_security_group({ group_name: install_group })
  else
    handle_output("Warning:\tSecurity group '#{install_group}' doesn't exist")
  end
  return
end

def handle_ip_perms(ip_perms,type,group_name)
  name_length = group_name.length
  name_spacer = ""
  name_length.times do
    name_spacer = name_spacer+" "
  end
  ip_perms.each do |ip_perm|
    ip_protocol  = ip_perm.ip_protocol
    from_port    = ip_perm.from_port.to_s
    to_port      = ip_perm.to_port.to_s
    cidr_ip      = []
    ip_ranges    = ip_perm.ip_ranges
    ipv_6_ranges = ip_perm.ipv_6_ranges
    ip_ranges.each do |ip_range|
      range = ip_range.cidr_ip
      cidr_ip.push(range)
    end
    cidr_ip = cidr_ip.join(",")
    if ip_protocol and from_port and to_port
      if ip_protocol.match(/[a-z]/) and cidr_ip.match(/[0-9]/)
        ip_rule = ip_protocol+","+from_port+","+to_port
        handle_output("#{name_spacer} rule=#{ip_rule} range=#{cidr_ip} (IPv4 #{type})")
      end
    end
    cidr_ip = []
    ipv_6_ranges.each do |ip_range|
      range = ip_range.cidr_ip
      cidr_ip.push(range)
    end
    cidr_ip = cidr_ip.join(",")
    if ip_protocol and from_port and to_port
      if ip_protocol.match(/[a-z]/) and cidr_ip.match(/[0-9]/)
        ip_rule = ip_protocol+","+from_port+","+to_port
        handle_output("#{name_spacer} rule=#{ip_rule} range=#{cidr_ip} (IPv4 #{type})")
      end
    end
  end
  return
end

# List AWS EC2 security groups

def list_aws_security_groups(install_access,install_secret,install_region,install_group)
  if !install_group.match(/[a-z]|[a-z]|[0-9]/)
    install_group = "all"
  end
  groups = get_aws_security_groups(install_access,install_secret,install_region)
  groups.each do |group|
    group_name = group.group_name
    if install_group.match(/^all$|^#{group_name}$/)
      description = group.description
      handle_output("#{group_name} desc=\"#{description}\"")
      ip_perms = group.ip_permissions
      handle_ip_perms(ip_perms,"Ingress",group_name)
      ip_perms = group.ip_permissions_egress
      handle_ip_perms(ip_perms,"Egress",group_name)
    end
  end
  return
end


# Get instance key pair

def get_aws_instance_key_name(install_access,install_secret,install_region,install_id)
  key_name = "none"
  ec2,reservations = get_aws_reservations(install_access,install_secret,install_region)
  reservations.each do |reservation|
    reservation["instances"].each do |instance|
      instance_id = instance.instance_id
      key_name    = instance.key_name
      if instance_id.match(/#{install_id}/)
        return key_name
      end
    end
  end
  return key_name
end

# Get instance IP

def get_aws_instance_ip(install_access,install_secret,install_region,install_id)
  public_ip = "none"
  ec2,reservations = get_aws_reservations(install_access,install_secret,install_region)
  reservations.each do |reservation|
    reservation["instances"].each do |instance|
      instance_id = instance.instance_id
      public_ip  = instance.public_ip_address
      if instance_id.match(/#{install_id}/)
        return public_ip
      end
    end
  end
  return public_ip
end

# Get AWS owner ID

def get_aws_owner_id(install_access,install_secret,install_region)
  iam = initiate_aws_iam_client(install_access,install_secret,install_region)
  begin
    user = iam.get_user()
  rescue Aws::EC2::Errors::AccessDenied
    handle_output("Warning:\tUser needs to be given appropriate rights in AWS IAM")
    quit()
  end
  owner_id = user[0].arn.split(/:/)[4]
  return owner_id
end

# Get list of AWS images

def get_aws_images(install_access,install_secret,install_region)
  ec2 = initiate_aws_ec2_client(install_access,install_secret,install_region)
  begin
    images = ec2.describe_images({ owners: ["self"] }).images
  rescue Aws::EC2::Errors::AccessDenied
    handle_output("Warning:\tUser needs to be given appropriate rights in AWS IAM")
    quit()
  end
  return ec2,images
end

# List AWS images

def list_aws_images(install_access,install_secret,install_region)
  ec2,images = get_aws_images(install_access,install_secret,install_region)
  images.each do |image|
    image_name = image.name
    image_id   = image.image_id
    handle_output("#{image_name}\tid=#{image_id}")
  end
  return
end

# Get AWS image ID

def get_aws_image(install_client,install_access,install_secret,install_region)
  image_id   = "none"
  ec2,images = get_aws_images(install_access,install_secret,install_region)
  images.each do |image|
    image_name = image.image_location.split(/\//)[1]
    if image_name.match(/^#{install_client}/)
      image_id = image.image_id
      return ec2,image_id
    end
  end
  return ec2,image_id
end

# Delete AWS image

def delete_aws_image(install_client,install_access,install_secret,install_region)
  ec2,image_id = get_aws_image(install_client,install_access,install_secret,install_region)
  if image_id == "none"
    handle_output("Warning:\tNo AWS Image exists for '#{install_client}'")
    quit()  
  else
    handle_output("Information:\tDeleting Image ID #{image_id} for '#{install_client}'")
    ec2.deregister_image({ dry_run: false, image_id: image_id, })
  end
  return
end

# Check if AWS image exists

def check_if_aws_image_exists(install_client,install_access,install_secret,install_region)
  exists     = "no"
  ec2,images = get_aws_images(install_access,install_secret,install_region)
  images.each do |image|
    if image.name.match(/^#{install_client}/)
      exists = "yes"
      return exists
    end
  end
  return exists
end

# Get vagrant version

def get_vagrant_version()
  vagrant_version = %x[$vagrant_bin --version].chomp
  return vagrant_version
end

# Check vagrant aws plugin is installed

def check_vagrant_aws_is_installed()
  check_vagrant_is_installed()
  plugin_list = %x[vagrant plugin list]
  if !plugin_list.match(/aws/)
    message = "Information:\tInstalling Vagrant AWS Plugin"
    command = "vagrant plugin install vagrant-aws"
    execute_command(message,command)
  end
  return
end

# Check vagrant is installed

def check_vagrant_is_installed()
  $vagrant_bin = %x[which vagrant].chomp
  if !$vagrant_bin.match(/vagrant/)
    if $os_name.match(/Darwin/)
      vagrant_pkg = "vagrant_"+$vagrant_version+"_"+$os_name.downcase+".dmg"
      vagrant_url = "https://releases.hashicorp.com/vagrant/"+$vagrant_version+"/"+vagrant_pkg
    else
      if $os_mach.match(/64/)
        vagrant_pkg = "vagrant_"+$vagrant_version+"_"+$os_name.downcase+"_amd64.zip"
        vagrant_url = "https://releases.hashicorp.com/vagrant/"+$vagrant_version+"/"+vagrant_pkg
      else
        vagrant_pkg = "vagrant_"+$vagrant_version+"_"+$os_name.downcase+"_386.zip"
        vagrant_url = "https://releases.hashicorp.com/vagrant/"+$vagrant_version+"/"+vagrant_pkg
      end
    end
    tmp_file = "/tmp/"+vagrant_pkg
    if !File.exist?(tmp_file)
      wget_file(vagrant_url,tmp_file)
    end
    if !File.directory?("/usr/local/bin") and !File.symlink?("/usr/local/bin")
      message = "Information:\tCreating /usr/local/bin"
      command = "mkdir /usr/local/bin"
      execute_command(message,command)
    end
    if $os_name.match(/Darwin/)
      message = "Information:\tMounting Vagrant Image"
      command = "hdiutil attach #{vagrant_pkg}"
      execute_command(message,command)
      message = "Information:\tInstalling Vagrant Image"
      command = "installer -package /Volumes/Vagrant/Vagrant.pkg -target /"
      execute_command(message,command)
    else
      message = "Information:\tInstalling Vagrant"
    end
    execute_command(message,command)
  end
  return
end

# get AWS credentials

def get_aws_creds(install_creds)
  install_access = ""
  install_secret = ""
  if File.exist?(install_creds)
    file_creds = File.readlines(install_creds)
    file_creds.each do |line|
      line = line.chomp
      if !line.match(/^#/)
        if line.match(/:/)
          (install_access,install_secret) = line.split(/:/)
        end
        if line.match(/AWS_ACCESS_KEY|aws_access_key_id/)
          install_access = line.gsub(/export|AWS_ACCESS_KEY|aws_access_key_id|=|"|\s+/,"")
        end
        if line.match(/AWS_SECRET_KEY|aws_secret_access_key/)
          install_secret = line.gsub(/export|AWS_SECRET_KEY|aws_secret_access_key|=|"|\s+/,"")
        end
      end
    end
  else
    handle_output("Warning:\tCredentials file '#{install_creds}' does not exit")
  end
  return install_access,install_secret
end

# Check AWS CLI is installed

def check_if_aws_cli_is_installed()
  aws_cli = %x[which aws]
  if !aws_cli.match(/aws/)
    handle_output("Warning:\tAWS CLI not installed")
    if $os_name.match(/Darwin/)
      handle_output("Information:\tInstalling AWS CLI")
      brew_install("awscli")
    end
  end
  return
end

# Create AWS Creds file

def create_aws_creds_file(install_creds,install_access,install_secret)
  file = File.open(install_creds,"w")
  file.write("[default]\n")
  file.write("aws_access_key_id = #{install_access}\n")
  file.write("aws_secret_access_key = #{install_secret}\n")
  file.close
  return
end

# Check if AWS Key Pair exists

def check_if_aws_key_pair_exists(install_access,install_secret,install_region,install_key)
  exists = "no"
  ec2,key_pairs = get_aws_key_pairs(install_access,install_secret,install_region)
  key_pairs.each do |key_pair|
    key_name = key_pair.key_name
    if key_name.match(/^#{install_key}$/)
      exists = "yes"
    end
  end
  return exists
end

# Check if AWS key file exists

def check_if_aws_ssh_key_file_exists(install_key)
  aws_ssh_key = $default_aws_ssh_key_dir+"/"+install_key+".pem"
  if File.exists?(aws_ssh_key)
    exists = "yes"
  else
    exists = "no"
  end
  return exists
end

# Create AWS Key Pair

def create_aws_key_pair(install_access,install_secret,install_region,install_key)
  aws_ssh_dir = $home_dir+"/.ssh/aws"
  check_my_dir_exists(aws_ssh_dir)
  if $nosuffix == 0
    install_key = get_aws_uniq_name(install_key,install_region)
  end
  exists = check_if_aws_key_pair_exists(install_access,install_secret,install_region,install_key)
  if exists == "yes"
    handle_output("Warning:\tKey Pair '#{install_key}' already exists")
    quit()
  else
    handle_output("Information:\tCreating Key Pair '#{install_key}'")
    ec2      = initiate_aws_ec2_client(install_access,install_secret,install_region)
    key_pair = ec2.create_key_pair({ key_name: install_key }).key_material
    key_file = aws_ssh_dir+"/"+install_key+".pem"
    handle_output("Information:\tSaving Key Pair '#{install_key}' to '#{key_file}'")
    file = File.open(key_file,"w")
    file.write(key_pair)
    file.close
    message = "Information:\tSetting permissions on '#{key_file}' to 400"
    command = "chmod 400 #{key_file}"
    execute_command(message,command)
  end
  return
end

# Delete AWS Key Pair

def delete_aws_key_pair(install_access,install_secret,install_region,install_key)
  aws_ssh_dir = $home_dir+"/.ssh/aws"
  if $nosuffix == 0
    install_key = get_aws_uniq_name(install_key,install_region)
  end
  exists = check_if_aws_key_pair_exists(install_access,install_secret,install_region,install_key)
  if exists == "no"
    handle_output("Warning:\tAWS Key Pair '#{install_key}' does not exist")
    quit()
  else
    handle_output("Information:\tDeleting AWS Key Pair '#{install_key}'")
    ec2      = initiate_aws_ec2_client(install_access,install_secret,install_region)
    key_pair = ec2.delete_key_pair({ key_name: install_key })
    key_file = aws_ssh_dir+"/"+install_key+".pem"
    if File.exist?(key_file)
      handle_output("Information:\tDeleting AWS Key Pair file '#{key_file}'")
      File.delete(key_file)
    end
  end
  return
end

# List AWS Key Pairs

def list_aws_key_pairs(install_access,install_secret,install_region,install_key)
  ec2,key_pairs = get_aws_key_pairs(install_access,install_secret,install_region)
  key_pairs.each do |key_pair|
    key_name = key_pair.key_name
    if install_key.match(/[A-Z]|[a-z]|[0-9]/)
      if key_name.match(/^#{install_key}$/)
        handle_output(key_name)
      end
    else
      handle_output(key_name)
    end
  end
  return
end
