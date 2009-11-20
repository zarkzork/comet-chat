require 'test/unit'
require 'rubygems'
require 'rack/test'
require 'comet-chat'
require 'json'

# redefine default WAIT_TIMEOUT constant to speed up test passing
class Active_session
  WAIT_TIMEOUT=1
end

class JSON_test < Test::Unit::TestCase
  include Rack::Test::Methods

  ROOM_NAME="fdsfa"

  def initialize(*args)
    super(*args)
  end

  def app
    Comet_chat.new
  end
  
  def enter_the_room(name)
    get "json/"+ROOM_NAME+"/enter", {:name =>name}
    assert last_response.ok?
    JSON(last_response.body)["session"]
  end

  def get_event(session)
    get 'json/'+ROOM_NAME+"/get", { :session => session }
    assert last_response.ok?
    result=JSON last_response.body
    assert result["result"]=="ok"
    result["event"]
  end
  
  # test that test fails with no name given
  def test_no_name
    get "json/"+ROOM_NAME+"/enter"
    assert last_response.status==503
  end

  # try to enter the room
  def test_enter_the_room
    enter_the_room("test_enter")
    assert last_response.status==200
    response=JSON last_response.body
    assert response["session"]
    assert response["result"]=="ok"
    response
  end

  def test_timeout
    session=enter_the_room("test_timeout")
    get "json/"+ROOM_NAME+"/get", {:session => session}
    assert JSON(last_response.body)=={"result"=>"timeout"}
  end

  def test_simple_message
    session1=enter_the_room("1")
    session2=enter_the_room("2")
    t=Thread.new do
      result=get_event(session2)
      assert result["author"]=="1", "wrong author"
      assert result["type"]=="Message_event", "wrong type"
      assert result["message"]=="tst", "wrong message"
    end
    sleep 0.1
    get 'json/'+ROOM_NAME+'/message', {:session => session1,
      :message=>"tst"}
    t.join
  end
  
end
