# Ansible client code

# List ansible clients

def list_ansible_aws_clients()
  list_ansible_clients("aws")
  return
end

def list_ansible_clients(install_vm)
  ansible_dir = $client_base_dir+"/ansible"
  if !install_vm.match(/[a-z,A-Z]/) or install_vm.match(/none/)
    vm_types = [ 'fusion', 'vbox', 'aws' ]
  else
    vm_types = []
    vm_types.push(install_vm)
  end
  vm_types.each do |vm_type|
    vm_dir = ansible_dir+"/"+vm_type
    if File.directory?(vm_dir)
      handle_output("")
      case vm_type
      when /vbox/
        vm_title = "VirtualBox"
      when /aws/
        vm_title = "AWS"
      else
        vm_title = "VMware Fusion"
      end
      vm_list = Dir.entries(vm_dir)
      if vm_list.length > 0
        if $output_format.match(/html/)
          handle_output("<h1>Available Packer #{vm_title} clients</h1>")
          handle_output("<table border=\"1\">")
          handle_output("<tr>")
          handle_output("<th>VM</th>")
          handle_output("<th>OS</th>")
          handle_output("</tr>")
        else
          handle_output("Ansible #{vm_title} clients:")
          handle_output("")
        end
        vm_list.each do |vm_name|
          if vm_name.match(/[a-z,A-Z]/)
            yaml_file = vm_dir+"/"+vm_name+"/"+vm_name+".yaml"
            if File.exist?(yaml_file)
              yaml = File.readlines(yaml_file)
              if vm_type.match(/aws/)
                vm_os = "AMI"
              else
                vm_os = yaml.grep(/guest_os_type/)[0].split(/:/)[1].split(/"/)[1]
              end
              if $output_format.match(/html/)
                handle_output("<tr>")
                handle_output("<td>#{vm_name}</td>")
                handle_output("<td>#{vm_os}</td>")
                handle_output("</tr>")
              else
                handle_output("#{vm_name} os=#{vm_os}")
              end
            end
          end
        end
        if $output_format.match(/html/)
          handle_output("</table>")
        else
          handle_output("")
        end
      end
    end
  end
  return
end

# Delete a packer image

def unconfigure_ansible_client(install_client,install_vm)
  if $verbose_mode == true
    handle_output("Information:\tDeleting Ansible Image for #{install_client}")
  end
  packer_dir = $client_base_dir+"/ansible/"+install_vm
  client_dir = packer_dir+"/"+install_client
  host_file  = client_dir+"/hosts"
  yaml_file  = client_dir+"/"+install_client+".yaml"
  [ host_file, yaml_file ].each do |file_name|
    if File.exist?(file_name)
      if $verbose_mode == true
        handle_output("Information:\tDeleting file #{file_name}")
      end
      File.delete(file_name)
    end
  end
  return
end

# Get Ansible AWS instance information

def get_ansible_instance_info(install_name)
  info_file = "/tmp/"+install_name+".output"
  if File.exist?(info_file)
    file_data    = File.readlines(info_file)
    reservations = JSON.parse(file_data.join("\n"))
    reservations["instances"].each do |instance|
      instance_id = instance["id"]
      image_id    = instance["image_id"]
      status      = instance["state"]
      if !status.match(/terminated|shut/)
        if status.match(/running/)
          public_ip  = instance["public_ip"]
          public_dns = instance["dns_name"]
        else
          public_ip  = "NA"
          public_dns = "NA"
        end
        string = "id="+instance_id+" image="+image_id+" ip="+public_ip+" dns="+public_dns+" status="+status
      else
        string = "id="+instance_id+" image="+image_id+" status="+status
      end
      handle_output(string)
    end
    File.delete(info_file)
  else
    handle_output("Warning:\tNo instance information found")
  end 
  return
end

# Configure Ansible AWS client

def configure_ansible_aws_client(install_name,install_type,install_ami,install_region,install_size,install_access,install_secret,install_number,install_key,install_keyfile,install_group,install_desc,install_ports)
  create_ansible_aws_install_files(install_name,install_type,install_ami,install_region,install_size,install_access,install_secret,install_number,install_key,install_keyfile,install_group,install_desc,install_ports)
  return
end

# Create Ansible AWS client

def create_ansible_aws_install_files(install_name,install_type,install_ami,install_region,install_size,install_access,install_secret,install_number,install_key,install_keyfile,install_group,install_desc,install_ports)
  if !install_number.match(/[0,9]/)
    handle_output("Warning:\tIncorrect number of instances specified: '#{install_number}'")
    quit()
  end
  install_name,install_key,install_keyfile,install_group,install_ports = handle_aws_values(install_name,install_key,install_keyfile,install_access,install_secret,install_region,install_group,install_desc,install_type,install_ports)
  exists = check_if_aws_image_exists(install_name,install_access,install_secret,install_region)
  if exists == "yes"
    handle_output("Warning:\tAWS AMI already exists with name #{install_name}")
    exit
  end
  if !install_ami.match(/^ami/)
    old_install_ami = install_ami
    ec2,install_ami = get_aws_image(old_install_ami,install_access,install_secret,install_region)
    if install_ami.match(/^none$/)
      handle_output("Warning:\tNo AWS AMI ID found for #{old_install_ami}")
      install_ami = $default_aws_ami
      handle_output("Information:\tSetting AWS AMI ID to #{install_ami}")
    else
      handle_output("Information:\tFound AWS AMI ID #{install_ami} for #{old_install_ami}")
    end
  end
  user_data_file = ""
  client_dir     = $client_base_dir+"/ansible/aws/"+install_name
  check_dir_exists(client_dir)
  populate_aws_questions(install_name,install_ami,install_region,install_size,install_access,install_secret,user_data_file,install_type,install_number,install_key,install_keyfile,install_group,install_ports)
  install_service = "aws"
  process_questions(install_service)
  create_ansible_aws_yaml()
  return
end

# Build Ansible AWS client

def build_ansible_aws_config(install_name,install_access,install_secret,install_region)
  exists = check_if_aws_image_exists(install_name,install_access,install_secret,install_region)
  if exists == "yes"
    handle_output("Warning:\tAWS image already exists for '#{install_name}'")
    exit
  end
  client_dir = $client_base_dir+"/ansible/aws/"+install_name
  yaml_file  = client_dir+"/"+install_name+".yaml"
  if !File.exist?(yaml_file)
    handle_output("Warning:\tAnsible AWS config file '#{yaml_file}' does not exist")
    exit
  end
  message    = "Information:\tBuilding Ansible AWS instance using AMI name '#{install_name}' using '#{yaml_file}'"
  command    = "cd #{client_dir} ; ansible-playbook -i hosts #{yaml_file}"
  execute_command(message,command)
  get_ansible_instance_info(install_name)
  return
end


