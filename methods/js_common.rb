
# Common code to all Jumpstart functions

# Question/config structure

Js=Struct.new(:type, :question, :ask, :parameter, :value, :valid, :eval)

# UFS filesystems

Fs=Struct.new(:name, :mount, :slice, :mirror, :size)

def populate_js_fs_list()

  f_struct = {}
  f_order  = []

  name = "root"
  config = Fs.new(
    name      = "root",
    mount     = "/",
    slice     = "0",
    mirror    = "d10",
    size      = $default_slice_size
    )
  f_struct[name] = config
  f_order.push(name)

  name = "swap"
  config = Fs.new(
    name      = "swap",
    mount     = "/",
    slice     = "1",
    mirror    = "d20",
    size      = $default_slice_size
    )
  f_struct[name] = config
  f_order.push(name)

  name = "var"
  config = Fs.new(
    name      = "var",
    mount     = "/var",
    slice     = "3",
    mirror    = "d30",
    size      = $default_slice_size
    )
  f_struct[name] = config
  f_order.push(name)

  name = "opt"
  config = Fs.new(
    name      = "opt",
    mount     = "/opt",
    slice     = "4",
    mirror    = "d40",
    size      = "1024"
    )
  f_struct[name] = config
  f_order.push(name)

  name = "export"
  config = Fs.new(
    name      = "export",
    mount     = "/home/home",
    slice     = "5",
    mirror    = "d50",
    size      = "free"
    )
  f_struct[name] = config
  f_order.push(name)

  return f_struct,f_order
end

# Get ISO/repo version info

def get_js_iso_version(base_dir)
  message = "Checking:\tSolaris Version"
  command = "ls #{base_dir} |grep Solaris"
  output  = execute_command(message,command)
  iso_version = output.chomp
  iso_version = iso_version.split(/_/)[1]
  return iso_version
end

# Get ISO/repo update info

def get_js_iso_update(base_dir,os_version)
  update  = ""
  release = base_dir+"/Solaris_"+os_version+"/Product/SUNWsolnm/reloc/etc/release"
  message = "Checking:\tSolaris release"
  command = "cat #{release} |head -1 |awk '{print $4}'"
  output  = execute_command(message,command)
  if output.match(/_/)
    update = output.split(/_/)[1].gsub(/[a-z]/,"")
  else
    case output
    when /1\/06/
      update = "1"
    when /6\/06/
      update = "2"
    when /11\/06/
      update = "3"
    when /8\/07/
      update = "4"
    when /5\/08/
      update = "5"
    when /10\/08/
      update = "6"
    when /5\/09/
      update = "7"
    when /10\/09/
      update = "8"
    when /9\/10/
      update = "9"
    when /8\/11/
      update = "10"
    when /1\/13/
      update = "11"
    end
  end
  return update
end

# List available ISOs

def list_js_isos()
  search_string = "\\-ga\\-"
  iso_list      = check_iso_base_dir(search_string)
  if iso_list.length > 0
    handle_output("Available Jumpstart ISOs:")
    handle_output("") 
  end
  iso_list.each do |iso_file|
    iso_file    = iso_file.chomp
    iso_info    = File.basename(iso_file)
    iso_info    = iso_info.split(/-/)
    iso_version = iso_info[1..2].join("_")
    iso_arch    = iso_info[4]
    handle_output("ISO file:\t#{iso_file}")
    handle_output("Distribution:\tSolaris")
    handle_output("Version:\t#{iso_version}")
    handle_output("Architecture:\t#{iso_arch}")
    service_name     = "sol_"+iso_version+"_"+iso_arch
    repo_version_dir = $repo_base_dir+"/"+service_name
    if File.directory?(repo_version_dir)
      handle_output("Information:\tService Name #{service_name} (exists)")
    else
      handle_output("Information:\tService Name #{service_name}")
    end
    handle_output("") 
  end
  return
end
