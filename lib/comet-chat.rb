libdir = File.dirname(__FILE__)
$LOAD_PATH.unshift(libdir) unless $LOAD_PATH.include?(libdir)

# general ruby
require 'rubygems'
require 'sinatra'
require 'json'
require 'sanitize'
# aplication stuff
require 'comet'
require 'events'
require 'activity_tracker'

class Comet_chat < Sinatra::Base
  enable :static

  helpers do

    # helper method that ensures given string is matched regexp
    # /^[a-zA-Z1-9]*$/. +name+ is optional name of paramers to be
    # checked to produce error messages
    def validate(string, name=:unknown_param, custom_message=nil)
      if string !~ /^[a-zA-Z0-9_]+$/
        message=custom_message||"wrong symbol or"+
          " param missing: "+name.inspect
        throw :halt, [503, {'result' => 'error',
                        'message' => message}.to_json]
      end
    end

    # invoke Sanitize.clean()
    def sanitize(string)
      throw :halt, [503, {'result' => 'error'}.to_json] if !string
      Sanitize.clean(string)
    end

    def get_session(room_digest, session_digest)
      validate room_digest, :room_digest
      validate session_digest, :session_digest
      room=@active_rooms[room_digest]
      throw :halt, [503, {
                      'result' => 'error',
                      'message' => 'There is no such room.'
                    }.to_json] if !room
      result=room[session_digest]
      throw :halt, [503, {
                      'result' => 'error',
                      'message' => 'There is no such user in the room.'
                    }.to_json] if !result
      result
    end
  end

  def initialize
    @active_rooms={}
    @activity_tracker=Activity_tracker.new do |hash|
      # this block is called when activity timeout for room is expired
      session=get_session(hash[:room], hash[:session])
      session.active_room.post_event Mate_event.new(session.name, :left)
      session.active_room.remove session.hexdigest
      @active_rooms.delete hash[:room] if session.active_room.empty?
    end
    @activity_tracker.timeout=Active_session::WAIT_TIMEOUT*3
  end

  get '/' do
    erb :index
  end
  
  get '/json/:room/enter' do
    room=params[:room]
    name=params[:name]
    validate room, :room
    name=sanitize name
    throw :halt, [503, {'result' => 'empty'}.to_json] if name.empty?
    active_room=@active_rooms[room]
    if !active_room
      @active_rooms[room]=active_room=Active_room.new
    else
      if active_room.contains_name?(name)
        return {'result' => 'duplicate'}.to_json
      end
    end
    session=active_room.enter(name)
    @activity_tracker.active({:room => room,
                               :session => session.hexdigest})
    enter_event=Mate_event.new(name, :enter)
    session.active_room.post_event(enter_event)
    {
      'topic' => active_room.topic,
      'session' => session.hexdigest,
      'result'  => 'ok'
    }.to_json
  end

  get '/json/:room/leave' do
    room=params[:room]
    session_digest=params[:session]
    session=get_session(room, session_digest )
    @activity_tracker.done({:room => room,
                             :session => session_digest})
    {
      'result' => 'ok'
    }.to_json
  end
  
  get '/json/:room/mates' do
    room=params[:room]
    session=get_session(room, params[:session])
    room=session.active_room
    mates=room.names    
    {
      'result' => 'ok',
      'self_id' => session.name,
      'mates' => mates
    }.to_json
  end

  # Main "comet" method this is very long request
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

  #
  # message and topic event handling
  #

  get '/json/:room/:type' do
    pass unless %w[message typer topic].include? params[:type]
    room = params[:room]
    session_digest = params[:session]
    session = get_session(room, session_digest )
    message = params[:message]
    message = sanitize message
    event = case params[:type]
            when "message"
              Message_event.new(session.name, message)
            when "typer"
              Typer_event.new(session.name, message)
            when "topic"
              Topic_event.new(session.name, message)
            end
    session.active_room.post_event(event)
    {'result' => 'ok'}.to_json
  end

  # return room chat page
  get '/:room' do
    validate params[:room], :room, "wrong symbol in room name."
    erb :chat
  end
end
