# Common Windows (PE) related code

def list_pe_isos()
  install_os      = "win"
  install_method  = ""
  install_release = ""
  install_arch    = ""
  list_isos(install_os,install_method,install_release,install_arch)
  return
end