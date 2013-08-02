
require 'sinatra'
require 'sinatra/streaming'
require 'sinatra/reloader' if development?

#####################################################################
### 
###   Sinatra Configs and Global Settings
###
#####################################################################

configure do
  set :bind, "192.168.10.89"
  set :port, 80
end

### GET used to return device specific configuration file.  
### Here we're just stubbing a test file.

get '/juniper/config.cgi' do
  send_file("/usr/local/junos/configs/staging-switch.conf")
end

### GET used to download a Junos package (*.tgz) file.
### These can be stored anywhere on your sever, I just 
### happen to put mine in /usr/local/junos/packages

get '/juniper/os/:file' do |file|
  send_file("/usr/local/junos/packages/#{file}")
end

### GET used to retrieve an OP script (*.slax).
### These can be stored anywhere on your sever, I
### just happen to put mine in /usr/local/junos/slax

get '/juniper/script/:file' do |file|
  send_file("/usr/local/junos/slax/#{file}")
end

