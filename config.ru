require 'lib/comet-chat'

ENV['RACK_ENV'] = "production"
Comet_chat.configure do |app|
   app.set :root, Dir.pwd
 end

run Comet_chat.new

