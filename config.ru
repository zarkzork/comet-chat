require 'lib/comet-chat'

ENV['RACK_ENV'] = "production"
Comet_chat.configure do |app|
   app.set :root, Dir.pwd
end

use Rack::Static, :urls => ["/css", "/img", "/js"], :root => Dir.pwd + "/public"

run Comet_chat.new
