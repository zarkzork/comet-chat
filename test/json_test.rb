require 'test/unit'
require 'rubygems'
require 'rack/test'
require 'json'
require 'lib/comet-chat'


# redefine default WAIT_TIMEOUT constant to speed up test passing
class Active_session
  WAIT_TIMEOUT=0.5
end

# Basic test for JSON chat api.
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

  # Empty cannot be empty.
  def test_empty_name
    result=enter_the_room("", {:check_response => false})
    assert result["result"]=='empty'
    assert last_response.status==503
  end

  # test that leaving work
  def test_leave
    session=enter_the_room("zark")["session"]
    leave(session)
  end
  
  # Test that duplicate name are not allowed
  def test_twice_fail
    enter_the_room "zark"
    result=enter_the_room "zark", {:check_response => false}
    assert last_response.ok?, "response was:"+last_response.body
    assert result["result"]=="duplicate"
  end
  
  # Try to enter the room.
  def test_enter_the_room
    enter_the_room("test_name")
  end

  # Test that if no events occur during timeout, result 'timeout' will
  # be returned.
  def test_timeout
    session=enter_the_room("test_timeout")["session"]
    response=get_event(session, {:check_response => false})
    assert last_response.ok?
    assert response["result"] == 'timeout'
  end

  # Simple chat session test.
  def test_simple_message_session
    session1=enter_the_room("1")['session']
    session2=enter_the_room("2")['session']
    t=Thread.new do
      result=get_event(session2)
      assert result["author"]=="1", "wrong author"
      assert result["type"]=="Message_event", "wrong type"
      assert result["message"]=="tst", "wrong message"
    end
    sleep 0.1
    message(session1, 'tst')
    t.join
  end

  # Test that room returns propers mates.
  def test_mates
    enter_the_room "Not me"
    #change test room
    @room_name="zz"
    # add dude that will left by timeout
    enter_the_room "a"
    sleep Active_session::WAIT_TIMEOUT*6
    # enter and the leave
    session=enter_the_room("leaver")["session"]
    leave session
    # add couple of dudes
    enter_the_room "b"
    session=enter_the_room("c")["session"]
    # check that everything ok
    result=get_mates(session)["mates"]
    assert result == ["b","c"] || result == ["c","b"], "result:"+
      result.join(",")
  end

  private

  # Makes json request to the server via Rack::Test::Methods
  # +options+ is hash which can contain:
  # +:request+ => +:get+ or +:post+.
  # +:check_response => true of false.
  def json_request(uri, params={}, options={})
    request=options[:request]||:get
    send(request, "json/#{@room_name}/"+uri, params)
    response=JSON(last_response.body)
    if options[:check_response] != false
      message="status:"+last_response.status.to_s+
        "body: "+last_response.body
      assert last_response.ok?, message
      assert response["result"] == "ok", message
    end
    response
  end

  # Enters the chat room. Options will be used in +json_request()+
  def enter_the_room(name, options={})
    json_request "enter", {:name => name}, options
  end

  def leave(session, options={})
    json_request "leave", {:session => session}, options
  end
  
  # Gets event from chat. Options will be used in +json_request()+
  def get_event(session, options={})
    json_request "get", {:session => session}, options
  end

  # Gets mates from chat. Options will be used in +json_request()+
  def get_mates(session, options={})
    json_request "mates", {:session => session}, options
  end

  # Post message to chat. Options will be used in +json_request()+
  def message(session, message, options={})
    json_request "message", {:session => session,
      :message => message}, options
  end
  
  # Post typer to chat. Options will be used in +json_request()+
  def typer(session, message, options={})
    json_request "message", {:session => session,
      :message => message}, options
  end
end
