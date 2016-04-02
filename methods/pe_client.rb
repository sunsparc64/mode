# Windows related code

def output_pe_client_profile(install_client,install_ip,install_mac,output_file,install_service,install_type,install_label,install_license)
	timezone   = $default_windows_timezone
	bootsize   = $default_windows_bootsize
	locale     = $default_windows_locale
	xml_output = []
	xml      = Builder::XmlMarkup.new(:target => xml_output, :indent => 2)	
	xml.instruct! :xml, :version => "1.0", :encoding => "UTF-8"
	xml.unattend(:xmlns => "urn:schemas-microsoft-com:unattend") {
		xml.settings(:pass => "windowsPE") {
			xml.component(:"xmlns:wcm" => "http://schemas.microsoft.com/WMIConfig/2002/State", :"xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance", :name => "Microsoft-Windows-International-Core-WinPE", :processorArchitecture => "amd64", :publicKeyToken => "31bf3856ad364e35", :language => "neutral", :versionScope => "nonSxS") {
				xml.SetupUILanguage {
					xml.UILanguage("#{locale}")
				}
				xml.InputLocale("#{locale}")
				xml.SystemLocale("#{locale}")
				xml.UILanguage("#{locale}")
				xml.UILanguageFallback("#{locale}")
				xml.UserLocale("#{locale}")
			}
			xml.component(:"xmlns:wcm" => "http://schemas.microsoft.com/WMIConfig/2002/State", :"xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance", :name => "Microsoft-Windows-International-Core-WinPE", :processorArchitecture => "amd64", :publicKeyToken => "31bf3856ad364e35", :language => "neutral", :versionScope => "nonSxS") {
				xml.DiskConfiguration {
					xml.Disk(:"wcm:action" => "add") {
						xml.CreatePartitions {
							xml.CreatePartition(:"wcm:action" => "add") {
								xml.Order("1")
								xml.Size("#{bootsize}")
								xml.Type("Primary")
							}
						}
						xml.CreatePartitions {
							xml.CreatePartition(:"wcm:action" => "add") {
								xml.Extend("true")
								xml.Order("2")
								xml.Type("Primary")
							}
						}
						xml.ModifyPartition {
							xml.ModifyPartition(:"wcm:action" => "add") {
								xml.Active("true")
								xml.Format("NTFS")
								xml.Label("Boot")
								xml.Order("1")
								xml.PartitionID("1")
							}
						}
						xml.ModifyPartition {
							xml.ModifyPartition(:"wcm:action" => "add") {
								xml.Format("NTFS")
								xml.Label("System")
								xml.Order("2")
								xml.PartitionID("2")
							}
						}
						xml.DiskID("0")
						xml.WillWipeDisk("true")
					}
				}
				xml.ImageInstall {
					xml.OSImage {
						xml.InstallFrom {
							xml.MetaData(:"wcm:action" => "add") {
								xml.Key("/IMAGE/NAME ")
								xml.Value("#{install_label}")
							}
						}
						xml.InstallTo {
							xml.DiskID("0")
							xml.PartitionID("2")
						}
					}
				}
			}
			xml.UserData {
				xml.ProductKey {
					xml.Key("#{install_license}")
					xml.WillShowUI("OnError")
				}
			}
		}
		xml.settings(:pass => "specialize") {
			xml.component(:"xmlns:wcm" => "http://schemas.microsoft.com/WMIConfig/2002/State", :"xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance", :name => "Microsoft-Windows-Shell-Setup", :processorArchitecture => "amd64", :publicKeyToken => "31bf3856ad364e35", :language => "neutral", :versionScope => "nonSxS") {
				xml.OEMInformation {
					xml.HelpCustomized("false")
				}
			}
			xml.component(:"xmlns:wcm" => "http://schemas.microsoft.com/WMIConfig/2002/State", :"xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance", :name => "Microsoft-Windows-ServerManager-SvrMgrNc", :processorArchitecture => "amd64", :publicKeyToken => "31bf3856ad364e35", :language => "neutral", :versionScope => "nonSxS") {
				xml.IEHardenAdmin("false")
				xml.IEHardenUser("false")
			}
			xml.component(:"xmlns:wcm" => "http://schemas.microsoft.com/WMIConfig/2002/State", :"xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance", :name => "Microsoft-Windows-OutOfBoxExperience", :processorArchitecture => "amd64", :publicKeyToken => "31bf3856ad364e35", :language => "neutral", :versionScope => "nonSxS") {
				xml.DoNotOpenInitialConfigurationTasksAtLogon("true")
			}
			xml.component(:"xmlns:wcm" => "http://schemas.microsoft.com/WMIConfig/2002/State", :"xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance", :name => "Microsoft-Windows-Security-SPP-UX", :processorArchitecture => "amd64", :publicKeyToken => "31bf3856ad364e35", :language => "neutral", :versionScope => "nonSxS") {
				xml.SkipAutoActivation("true")
			}
		}
		xml.settings(:pass => "oobeSystem") {
			xml.component(:"xmlns:wcm" => "http://schemas.microsoft.com/WMIConfig/2002/State", :"xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance", :name => "Microsoft-Windows-Shell-Setup", :processorArchitecture => "amd64", :publicKeyToken => "31bf3856ad364e35", :language => "neutral", :versionScope => "nonSxS") {
				xml.AutoLogon {
					xml.Password {
						xml.Value("#{$q_struct["admin_password"].value}")
						xml.PlainText("true")
					}
					xml.Enabled("true")
					xml.Username("#{$q_struct["admin_user"]}")
				}
				xml.FirstLogonCommands {
					xml.SynchronousCommand(:"wcm:action" => "add") {
						xml.CommandLine('C:\Windows\SysWOW64\cmd.exe /c powershell -Command "Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force')
					}	
					xml.Description("Set Execution Policy 32 Bit")
				}
			}
		}
	}
	file = File.open(output_file,"w")
  xml_output.each do |item|
    file.write(item)
  end
  file.close
  message = "Information:\tValidating Windows configuration for "+install_client
  command = "xmllint #{output_file}"
  execute_command(message,command)
	return
end

# Populate Windows winrm powershell script

def populate_winrm_psh()
	winrm_psh = []
	winrm_psh.push("netsh advfirewall firewall set rule group=\"remote administration\" new enable=yes")
	winrm_psh.push("netsh advfirewall firewall add rule name=\"Open Port 5985\" dir=in action=allow protocol=TCP localport=5985")
	winrm_psh.push("")
	winrm_psh.push("winrm quickconfig -q")
	winrm_psh.push("winrm quickconfig -transport:http")
	winrm_psh.push("winrm set winrm/config '@{MaxTimeoutms=\"7200000\"}'")
	winrm_psh.push("winrm set winrm/config/winrs '@{MaxMemoryPerShellMB=\"0\"}'")
	winrm_psh.push("winrm set winrm/config/winrs '@{MaxProcessesPerShell=\"0\"}'")
	winrm_psh.push("winrm set winrm/config/winrs '@{MaxShellsPerUser=\"0\"}'")
	winrm_psh.push("winrm set winrm/config/service '@{AllowUnencrypted=\"true\"}'")
	winrm_psh.push("winrm set winrm/config/service/auth '@{Basic=\"true\"}'")
	winrm_psh.push("winrm set winrm/config/client/auth '@{Basic=\"true\"}'")
	winrm_psh.push("")
	winrm_psh.push("net stop winrm")
	winrm_psh.push("sc.exe config winrm start= auto")
	winrm_psh.push("net start winrm")
	return winrm_psh
end

# Output Windows winrm powershell script

def output_winrm_psh(install_client,winrm_psh,output_file)
	file = File.open(output_file,"w")
  winrm_psh.each do |item|
  	line = item+"\n"
    file.write(line)
  end
  file.close
  if $verbose_mode == 1
	  message = "Information:\tContents of Windows winrm powershell file: "+output_file+" for: "+install_client
	  command = "cat #{output_file}"
	  execute_command(message,command)
	end
	return
end
