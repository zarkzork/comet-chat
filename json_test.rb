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

  def initialize(*args)
    super(*args)
  end

  def setup
    @room_name="fdsfa"
  end
  
  def app
    Comet_chat.new
  end
  
  def enter_the_room(name)
    get "json/"+@room_name+"/enter", {:name =>name}
    assert last_response.ok?, "response was:"+last_response.body
    JSON(last_response.body)["session"]
  end

  def test_name_validation
    get "json/@@@/enter", {:name => "test"}
    assert last_response.status==503
  end
  
  def get_event(session)
    get 'json/'+@room_name+"/get", { :session => session }
    assert last_response.ok?, "response was:"+last_response.body
    result=JSON last_response.body
    assert result["result"]=="ok"
    result["event"]
  end

  def get_mates(session)
    get 'json/'+@room_name+'/mates', { :session => session}
    assert last_response.ok?, "response was:"+last_response.body
    result=JSON last_response.body
    assert result["result"]=="ok", last_response.body.to_s
    result["mates"]
  end
  
  # test that test fails with no name given
  def test_no_name
    get "json/"+@room_name+"/enter"
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
    get "json/"+@room_name+"/get", {:session => session}
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
    get 'json/'+@room_name+'/message', {:session => session1,
      :message=>"tst"}
    t.join
  end

  def test_mates
    @room_name="zz"
    enter_the_room "aa"
    session=enter_the_room "aad"
    result=get_mates session
    assert result==["aa","aad"]||result==["aad","aa"]
  end

  def test_twice_fail
    enter_the_room "zark"
    get "json/"+@room_name+"/enter", {:name =>"zark"}
    assert last_response.ok?, "response was:"+last_response.body
    assert JSON(last_response.body)["result"]=="duplicate"
  end

  #check that if there is two rooms /mates return different users
  def test_two_rooms_different_mates
    enter_the_room "zark"
    @room_name="anotherroom"
    session=enter_the_room "zork"
    result=get_mates session
    assert result==["zork"]
  end

end
