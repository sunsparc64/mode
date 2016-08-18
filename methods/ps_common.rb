# Common PS code

# List available Ubuntu ISOs

def list_ps_isos()
  search_string = "ubuntu|debian|purity"
  linux_type    = "Preseed (Ubuntu/Debian)"
  list_linux_isos(search_string,linux_type)
  return
end