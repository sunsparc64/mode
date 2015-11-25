# VC client code

# Handle VCSA OVA

def handle_vcsa_ova(install_file,install_service)
  if install_file.match(/iso$/)
    uid = %x[id -u].chomp
    check_dir_exists($repo_base_dir)
    check_dir_owner($repo_base_dir,uid)
    repo_version_dir = $repo_base_dir+"/"+install_service
    check_dir_exists(repo_version_dir)
    check_dir_owner(repo_version_dir,uid)
    copy_iso(install_file,repo_version_dir)
    install_file = repo_version_dir+"/vcsa/vmware-vcsa"
    umount_iso()
  end
  return install_file
end

# Deploy VCSA image

def deploy_vcsa_vm(install_server,install_datastore,install_server_admin,install_server_password,install_server_network,install_client,
                   install_size,install_root_password,install_timeserver,install_admin_password,install_domainname,install_sitename,
                   install_ipfamily,install_mode,install_ip,install_netmask,install_gateway,install_nameserver,install_service,install_file)
  populate_vcsa_questions(install_server,install_datastore,install_server_admin,install_server_password,install_server_network,install_client,
                          install_size,install_root_password,install_timeserver,install_admin_password,install_domainname,install_sitename,
                          install_ipfamily,install_mode,install_ip,install_netmask,install_gateway,install_nameserver,install_service,install_file)
  process_questions(install_service)
  install_server          = $q_struct["esx.hostname"].value
  install_datastore       = $q_struct["esx.datastore"].value
  install_server_admin    = $q_struct["esx.username"].value
  install_server_password = $q_struct["esx.password"].value
  install_size            = $q_struct["deployment.option"].value
  install_server_network  = $q_struct["deployment.network"].value
  install_client          = $q_struct["appliance.name"].value
  install_root_password   = $q_struct["root.password"].value
  install_timeserver      = $q_struct["ntp.servers"].value
  install_admin_password  = $q_struct["password"].value
  install_domainname      = $q_struct["domain-name"].value
  install_sitename        = $q_struct["site-name"].value
  install_ipfamily        = $q_struct["ip.family"].value
  install_ip              = $q_struct["ip"].value
  install_netmask         = $q_struct["prefix"].value
  install_gateway         = $q_struct["gateway"].value
  install_nameserver      = $q_struct["dns.servers"].value
  vcsa_json_file = create_vcsa_json(install_server,install_datastore,install_server_admin,install_server_password,install_server_network,install_client,
                                    install_size,install_root_password,install_timeserver,install_admin_password,install_domainname,install_sitename,
                                    install_ipfamily,install_mode,install_ip,install_netmask,install_gateway,install_nameserver,install_service,install_file)
  #create_cvsa_deploy_script(install_server,install_datastore,install_server_admin,install_server_password,install_server_network,install_client,
  #                          install_size,install_root_password,install_timeserver,install_admin_password,install_domainname,install_sitename,
  #                          install_ipfamily,install_mode,install_ip,install_netmask,install_gateway,install_nameserver,install_service,install_file)
  repo_version_dir = $repo_base_dir+"/"+install_service
  if $os_name.match(/Darwin/)
    deployment_dir = repo_version_dir+"/vcsa-cli-installer/mac"
  end
  if $os_name.match(/Linux/)
    deployment_dir = repo_version_dir+"/vcsa-cli-installer/lin64"
  end
  if File.directory?(deployment_dir)
    message = "Information:\tDeploying VCSA OVA"
    command = "cd #{deployment_dir} ; echo yes | ./vcsa-deploy #{vcsa_json_file} --accept-eula"
    execute_command(message,command)
  end
  return
end

# Create deployment script

def create_cvsa_deploy_script(install_server,install_datastore,install_server_admin,install_server_password,install_server_network,install_client,
                              install_size,install_root_password,install_timeserver,install_admin_password,install_domainname,install_sitename,
                              install_ipfamily,install_mode,install_ip,install_netmask,install_gateway,install_nameserver,install_service,install_file)
  install_netmask = install_netmask.gsub(/\//,"")
  uid = %x[id -u].chomp
  check_dir_exists($client_base_dir)
  check_dir_owner($client_base_dir,uid)
  service_dir = $client_base_dir+"/"+install_service
  check_dir_exists(service_dir)
  client_dir  = service_dir+"/"+install_client
  check_dir_exists(client_dir)
  output_file = client_dir+"/"+install_client+".sh"
  check_dir_exists(client_dir)
  file = File.open(output_file,"w")
  file.write("#!/bin/bash\n")
  file.write("\n")
  file.write("OVFTOOL=\"#{$ovftool_bin}\"\n")
  file.write("VCSA_OVA=#{install_file}\n")
  file.write("\n")
  file.write("ESXI_HOST=#{install_server}\n")
  file.write("ESXI_USERNAME=#{install_server_admin}\n")
  file.write("ESXI_PASSWORD=#{install_server_password}\n")
  file.write("VM_NETWORK=\"#{install_server_network}\"\n")
  file.write("VM_DATASTORE=#{install_datastore}\n")
  file.write("\n")
  file.write("# Configurations for VC Management Node\n")
  file.write("VCSA_VMNAME=#{install_client}\n")
  file.write("VCSA_ROOT_PASSWORD=#{install_admin_password}\n")
  file.write("VCSA_NETWORK_MODE=static\n")
  file.write("VCSA_NETWORK_FAMILY=#{install_ipfamily}\n")
  file.write("## IP Network Prefix (CIDR notation)\n")
  file.write("VCSA_NETWORK_PREFIX=#{install_netmask}\n")
  file.write("## Same value as VCSA_IP if no DNS\n")
  file.write("VCSA_HOSTNAME=#{install_ip}\n")
  file.write("VCSA_IP=#{install_ip}\n")
  file.write("VCSA_GATEWAY=#{install_gateway}\n")
  file.write("VCSA_DNS=#{install_nameserver}\n")
  file.write("VCSA_ENABLE_SSH=True\n")
  file.write("VCSA_DEPLOYMENT_SIZE=#{install_size}\n")
  file.write("\n")
  file.write("# Configuration for SSO\n")
  file.write("SSO_DOMAIN_NAME=#{install_domainname}\n")
  file.write("SSO_SITE_NAME=#{install_sitename}\n")
  file.write("SSO_ADMIN_PASSWORD=#{install_admin_password}\n")
  file.write("\n")
  file.write("# NTP Servers\n")
  file.write("NTP_SERVERS=#{install_timeserver}\n")
  file.write("\n")
  file.write("### DO NOT EDIT BEYOND HERE ###\n")
  file.write("\n")
  file.write("echo -e \"\nDeploying vCenter Server Appliance Embedded w/PSC ${VCSA_VMNAME} ...\"\n")
  file.write("\"${OVFTOOL}\" --acceptAllEulas --skipManifestCheck --X:injectOvfEnv --allowExtraConfig --X:enableHiddenProperties --X:waitForIp --sourceType=OVA --powerOn \\\n")
  file.write("\"--net:Network 1=${VM_NETWORK}\" --datastore=${VM_DATASTORE} --diskMode=thin --name=${VCSA_VMNAME} \\\n")
  file.write("\"--deploymentOption=${VCSA_DEPLOYMENT_SIZE}\" \\\n")
  file.write("\"--prop:guestinfo.cis.vmdir.domain-name=${SSO_DOMAIN_NAME}\" \\\n")
  file.write("\"--prop:guestinfo.cis.vmdir.site-name=${SSO_SITE_NAME}\" \\\n")
  file.write("\"--prop:guestinfo.cis.vmdir.password=${SSO_ADMIN_PASSWORD}\" \\\n")
  file.write("\"--prop:guestinfo.cis.appliance.net.addr.family=${VCSA_NETWORK_FAMILY}\" \\\n")
  file.write("\"--prop:guestinfo.cis.appliance.net.addr=${VCSA_IP}\" \\\n")
  file.write("\"--prop:guestinfo.cis.appliance.net.pnid=${VCSA_HOSTNAME}\" \\\n")
  file.write("\"--prop:guestinfo.cis.appliance.net.prefix=${VCSA_NETWORK_PREFIX}\" \\\n")
  file.write("\"--prop:guestinfo.cis.appliance.net.mode=${VCSA_NETWORK_MODE}\" \\\n")
  file.write("\"--prop:guestinfo.cis.appliance.net.dns.servers=${VCSA_DNS}\" \\\n")
  file.write("\"--prop:guestinfo.cis.appliance.net.gateway=${VCSA_GATEWAY}\" \\\n")
  file.write("\"--prop:guestinfo.cis.appliance.root.passwd=${VCSA_ROOT_PASSWORD}\" \\\n")
  file.write("\"--prop:guestinfo.cis.appliance.ssh.enabled=${VCSA_ENABLE_SSH}\" \\\n")
  file.write("\"--prop:guestinfo.cis.appliance.ntp.servers=${NTP_SERVERS}\" \\\n")
  file.write("${VCSA_OVA} \"vi://${ESXI_USERNAME}:${ESXI_PASSWORD}@${ESXI_HOST}/\"\n")
  file.close()
  if File.exist?(output_file)
    %x[chmod +x #{output_file}]
  end
  return output_file
end

# Create VCSA JSON file

def create_vcsa_json(install_server,install_datastore,install_server_admin,install_server_password,install_server_network,install_client,
                     install_size,install_root_password,install_timeserver,install_admin_password,install_domainname,install_sitename,
                     install_ipfamily,install_mode,install_ip,install_netmask,install_gateway,install_nameserver,install_service,install_file)
  install_netmask = install_netmask.gsub(/\//,"")
  string = "{ 
              \"__comments\":
              [
                \"VCSA deployment\"
              ],

              \"deployment\":
              {
                \"esx.hostname\":\"#{install_server}\",
                \"esx.datastore\":\"#{install_datastore}\",
                \"esx.username\":\"#{install_server_admin}\",
                \"esx.password\":\"#{install_server_password}\",
                \"deployment.option\":\"#{install_size}\",
                \"deployment.network\":\"#{install_server_network}\",
                \"appliance.name\":\"#{install_client}\",
                \"appliance.thin.disk.mode\":#{$default_thindiskmode}
              }, 


              \"vcsa\":
              {

                \"system\":
                {
                  \"root.password\":\"#{install_root_password}\",
                  \"ssh.enable\":true,
                  \"ntp.servers\":\"#{install_timeserver}\"
                },

                \"sso\":
                {
                  \"password\":\"#{install_admin_password}\",
                  \"domain-name\":\"#{install_domainname}\",
                  \"site-name\":\"#{install_sitename}\"
                },

                \"networking\":
                {
                  \"ip.family\":\"#{install_ipfamily}\",
                  \"mode\":\"static\",
                  \"ip\":\"#{install_ip}\",
                  \"prefix\":\"#{install_netmask}\",
                  \"gateway\":\"#{install_gateway}\",
                  \"dns.servers\":\"#{install_nameserver}\",
                  \"system.name\":\"#{install_ip}\"
                }
              }
            }"
    uid = %x[id -u].chomp
    check_dir_exists($client_base_dir)
    check_dir_owner($client_base_dir,uid)
    service_dir = $client_base_dir+"/"+install_service
    check_dir_exists(service_dir)
    client_dir  = service_dir+"/"+install_client
    check_dir_exists(client_dir)
    output_file = client_dir+"/"+install_client+".json"
    check_dir_exists(client_dir)
    json   = JSON.parse(string)
    output = JSON.pretty_generate(json)
    file   = File.open(output_file,"w")
    file.write(output)
    file.close()
  return output_file
end