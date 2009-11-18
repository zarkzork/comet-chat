# gems
require 'rubygems'
require 'dm-core'
require 'sinatra'
require 'json'
require 'haml'
require 'sanitize'
# aplication stuff
require 'comet'
require 'events'
require 'activity_tracker'

class Comet_chat < Sinatra::Base
  enable :static
  set :public, './public'

  helpers do
    def validate(string)
      if (!string)||(!string =~ /^[a-zA-Z1-9]*$/)
        throw :halt, [503, "wrong symbol in param"]
      end
    end

    def sanitize(string)
      Sanitize.clean(string)
    end

    def get_session(room_digest, session_digest)
      validate room_digest
      validate session_digest
      result=@active_rooms[room_digest][session_digest]
      throw :halt, [503, { 'result' => 'error'}.to_json] if !result
      result
    end
  end

  def initialize
    @active_rooms={}
    @activity_tracker=Activity_tracker.new do |hash|
      session=get_session(hash[:room], hash[:session])
      session.active_room.post_event Mate_event.new(session.name, :left)
      session.active_room.remove session.hexdigest
    end
  end

  get '/' do
    result="Rooms:"
    @active_rooms.each{|r| result+=r.inspect+"\n"}
    result
  end

  get '/json/:room/enter' do
    room=params[:room]
    name=params[:name]
    validate room
    validate name
    active_room=@active_rooms[room]
    if !active_room
      @active_rooms[room]=active_room=Active_room.new
    else
      if active_room.contains_name? name
        return {'result' => 'duplicate'}.to_json
      end
    end
    session=active_room.enter(name)
    enter_event=Mate_event.new(name, :enter)
    session.active_room.post_event(enter_event)
    {
      'session' => session.hexdigest,
      'result'  => 'ok'
    }.to_json
  end

  get '/json/:room/leave' do
    room=params[:room]
    session=get_session(room, params[:session])
    session.active_room.post_event Mate_event.new(session.name, :left)
    session.active_room.remove session.hexdigest
  end
  
  get '/json/:room/mates' do
    room=params[:room]
    session=get_session(room, params[:session])
    return {
      'result' => 'error'
    }.json if !session
    room=session.active_room
    mates=room.names    
    {
      'result' => 'ok',
      'self_id' => session.name,
      'mates' => mates
    }.to_json
  end

  get '/json/:room/get' do
    event=nil
    room=params[:room]
    session_digest=params[:session]
    session=get_session(room, session_digest )
    @activity_tracker.active({:room => room,
                               :session => session_digest})
    event=session.get_event 
    return {'result' => 'timeout'}.to_json if !event
    {
      'result' => 'ok',
      'event' => event
    }.to_json
  end

  get '/json/:room/message' do
    room=params[:room]
    session_digest=params[:session]
    session=get_session(room, session_digest )
    @activity_tracker.active({:room => room,
                               :session => session_digest})
    message=params[:message]
    message=sanitize message
    message_event=Message_event.new(session.name, message)
    session.active_room.post_event(message_event)
    {'result' => 'ok'}.to_json
  end

  get '/json/:room/typer' do
    session=get_session(params[:room], params[:session])
    message=params[:message]
    message=sanitize message
    typer_event=Typer_event.new(session.name, message)
    session.active_room.post_event(typer_event)
    {'result' => 'ok'}.to_json
  end
  
end
