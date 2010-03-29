require 'lib/comet-chat'

use Rack::Static, :urls => ["/css/", "/img/", "/js/"], :root => Dir.pwd + "/public"

run Comet_chat.new
