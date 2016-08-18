#!/usr/bin/env ruby

# Name:         mode (Multi OS Deployment Engine) webserver
# Version:      0.0.3
# Release:      1
# License:      CC-BA (Creative Commons By Attribution)
#               http://creativecommons.org/licenses/by/4.0/legalcode
# Group:        System
# Source:       N/A
# URL:          http://lateralblast.com.au/
# Distribution: UNIX
# Vendor:       Lateral Blast
# Packager:     Richard Spindler <richard@lateralblast.com.au>
# Description:  Ruby script for processing mode

# Load required gems

require 'rubygems'
require 'pathname'
require 'etc'
require 'date'

def install_gem(gem_name)
  puts "Information:\tInstalling #{gem_name}"
  %x[gem install #{gem_name}]
  Gem.clear_paths
  return
end

begin
  require 'sinatra'
rescue LoadError
  install_gem("sinatra")
end
begin
  require 'fileutils'
rescue LoadError
  install_gem("fileutils")
end
begin
  require 'hex_string'
rescue LoadError
  install_gem("hex_string")
end
begin
  require 'unpack'
rescue LoadError
  install_gem("unpack")
end
begin
  require 'enumerate'
rescue LoadError
  install_gem("enumerate")
end
begin
  require 'iconv'
rescue LoadError
  install_gem("iconv")
end
begin
  require 'bcrypt'
rescue LoadError
  install_gem("bcrypt")
end
begin
  require 'fileutils'
rescue LoadError
  install_gem("fileutils")
end
begin
  require 'parseconfig'
rescue LoadError
  install_gem("parseconfig")
end

# Some webserver defaults

default_bind       = "127.0.0.1"
default_exceptions = false
default_port       = "9495"
default_sessions   = "true"
default_errors     = "false"
enable_ssl         = true
enable_auth        = false
enable_upload      = false
$ssl_dir           = Dir.pwd+"/ssl"
ssl_certificate    = $ssl_dir+"/cert.crt"
ssl_key            = $ssl_dir+"/pkey.pem"
$ssl_password      = "123456"

# Only allow uploads if we has authentication

if !enable_auth == true
  enable_upload = false
end

set :port,            default_port
set :bind,            default_bind
set :sessions,        default_sessions
set :dump_errors,     default_errors
set :show_exceptions, default_exceptions

# Load methods

if Dir.exist?("./methods")
  file_list = Dir.entries("./methods")
  for file in file_list
    if file =~ /rb$/
      require "./methods/#{file}"
    end
  end
end

# SSL config

if enable_ssl == true
  require 'webrick/ssl'
  require 'webrick/https'
  if !File.directory?($ssl_dir)
    puts "Information: Creating "+$ssl_dir
    Dir.mkdir($ssl_dir)
  end
  if !File.exist?(ssl_certificate) or !File.exist?(ssl_key)
    %x[openssl req -x509 -nodes -days 365 -newkey rsa:1024 -keyout #{ssl_key} -out #{ssl_certificate}]
  end
  set :ssl_certificate, ssl_certificate
  set :ssl_key, ssl_key
  module Sinatra
    class Application
      def self.run!
        certificate_content = File.open(ssl_certificate).read
        key_content = File.open(ssl_key).read
  
        server_options = {
          :Host => bind,
          :Port => port,
          :SSLEnable => true,
          :SSLCertificate => OpenSSL::X509::Certificate.new(certificate_content),
          :SSLPrivateKey => OpenSSL::PKey::RSA.new(key_content,$ssl_password)
        }
  
        Rack::Handler::WEBrick.run self, server_options do |server|
          [:INT, :TERM].each { |sig| trap(sig) { server.stop } }
          server.threaded = settings.threaded if server.respond_to? :threaded=
          set :running, true
        end
      end
    end
  end
end

# htpasswd authentication

# Set up global files

$htpasswd_file = Dir.pwd+"/views/.htpasswd"

if enable_auth == true
  module Sinatra
    class Application
    
      helpers do
        def protect!
          unless authorized?
            response['WWW-Authenticate'] = %(Basic realm="Restricted Area")
            throw(:halt, [401, "Not authorized\n"])
          end
        end
  
        def authorized?
          @auth ||=  Rack::Auth::Basic::Request.new(request.env)
          passwd = File.open($htpasswd_file).read.split("\n").map {|credential| credential.split(':')}
          if @auth.provided? && @auth.basic? && @auth.credentials
            user, pass = @auth.credentials
            auth = passwd.assoc(user)
            crypt = BCrypt::Password.create(auth[1])
            return false unless auth
            [user, crypt] == auth
          end
        end
      end
    end
  end
end

# Set global variables
# Set defaults
# Unlike the reporting script, these currently don't get auto detected

set_global_vars()

before do
  set_global_vars()
  check_local_config("client")
  $verbose_mode  = 0
  $output_format = "html"
  $output_text   = []
end

# handle error - redirect to help

error do
  head  = []
  body  = []
  head  = File.readlines("./views/layout.html")
  body  = File.readlines("./views/help.html")
  array = head + body
  array = array.join("\n")
  "#{array}"
end

# handle 404

not_found do
  head  = []
  body  = []
  head  = File.readlines("./views/layout.html")
  body  = File.readlines("./views/help.html")
  array = head + body
  array = array.join("\n")
  "#{array}"
end

# handle help

get '/help' do
  head  = []
  body  = []
  head  = File.readlines("./views/layout.html")
  body  = File.readlines("./views/help.html")
  array = head + body
  array = array.join("\n")
  "#{array}"
end

# handle version

get '/version' do
  head  = []
  body  = []
  foot  = []
  head  = File.readlines("./views/layout.html")
  head  = html_header(head,"Mode")
  body  = print_version()
  foot  = html_footer(foot)
  array = head + body + foot
  array = array.join("\n")
  "#{array}"
end 

# handle /

get '/' do
  head = []
  body = []
  foot = []
  head = File.readlines("./views/layout.html")
  head = html_header(head,"Mode")
  if params["help"]
    redirect "/help"
  end
  if params["version"]
    redirect "/version"
  end
  if params["client"]
    install_client = params["client"]
  else
    install_client = ""
  end
  if params["action"]
    install_action = params["action"]
  else
    redirect "/help"
  end
  if params["vm"]
    install_vm = params["vm"]
  else
    install_vm = ""
  end
  if params["method"]
    install_method = params["method"]
  else
    install_method = ""
  end
  if params["os"]
    install_os = params["os"]
  else
    install_os = ""
  end
  if params["type"]
    install_type = params["type"]
  else
    install_type = ""
  end
  case install_action
  when /help/
    redirect "/help"
  when /display|view|show|prop/
    if install_client.match(/[a-z,A-Z]/)
      if install_vm.match(/[a-z]/) and !install_vm.match(/none/)
        eval"[show_#{install_vm}_vm_config(install_client)]"
      else
        get_client_config(install_client,install_service,install_method,install_type)
      end
    else
      handle_output("Warning:\tClient name not specified")
    end
  when /list/
    if install_type.match(/[a-z]/)
      if install_type.match(/iso/)
        if install_method.match(/[a-z]/)
          eval"[list_#{install_method}_isos]"
        else
          list_os_isos(install_os)
        end
      end
      if install_type.match(/packer/)
        list_packer_clients(install_vm)
      end
    else
      if install_vm.match(/[a-z]/)
        list_vm(install_vm,install_os,install_method)
      end
    end
  end
  body  = $output_text
  foot  = html_footer(foot)
  array = head + body + foot
  array = array.join("\n")
  "#{array}"
end
