# Solaris LDoms support code

# Question/config structure

Ld = Struct.new(:question, :ask, :value, :valid, :eval)

def list_ldoms(install_vm)
  case install_vm
  when /ldom/
    list_all_ldoms()
  when /gdom/
    list_gdoms()
  when /cdom/
    list_cdoms()
  else
    list_all_ldoms()
  end
  return
end

def list_all_ldoms()
  list_cdoms()
  list_gdoms()
  return
end


  