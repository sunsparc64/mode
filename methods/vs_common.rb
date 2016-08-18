
# Common routines for server and client configuration

# Question/config structure

Vs = Struct.new(:type, :question, :ask, :parameter, :value, :valid, :eval)

def check_promisc_mode()
  promisc_file="/Library/Preferences/VMware Fusion/promiscAuthorized"
  if !File.exists?(promisc_file)
    %x[sudo touch "/Library/Preferences/VMware Fusion/promiscAuthorized"]
  end
  return
end

# List available ISOs

def list_vs_isos()
  search_string = "VMvisor"
  linux_type    = "vSphere / ESXi"
  list_linux_isos(search_string,linux_type)
  return
end