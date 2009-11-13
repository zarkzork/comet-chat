# gems
require 'rubygems'
require 'dm-core'
require 'sinatra'
require 'json'
require 'haml'
require 'sanitize'
# aplication stuff
require 'model'
require 'comet'
require 'events'
# run tests before start
require 'tests'

DataMapper.setup(:default,
                 ENV['DATABASE_URL'] || "sqlite3:///#{ Dir.pwd}/test.db")
DataMapper.auto_migrate!

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

    def get_session(session_digest)
      validate session_digest
      @sessions[session_digest]
    end
  end

  def initialize
    room=Room.create(:topic => 'Test-room')
    active_room=Active_room.new(room)
    @active_rooms={room.hexdigest => active_room}
    @sessions=Hash.new
  end

  get '/' do
    result="Rooms:"
    @active_rooms.each{|r| result+=r.inspect+"\n"}
    result+="sessions:"
    @sessions.each{|s| result+=s.inspect+"\n"}
    result
  end

  get '/:room' do
    room_digest=params[:room]
    validate room_digest
    @room=Room.first(:hexdigest => room_digest)
    throw :halt, [404, "room not found"] if !@room
    haml :enter
  end
  
  get '/json/:room/enter' do
    room=params[:room]
    name=params[:name]
    validate room
    validate name
    active_room=@active_rooms[room]
    if !active_room
      if db_room=Room.first(:hexdigest => room)
        active_room=Active_room.new(db_room) if db_room
      end
    end
    if !active_room
      return {'result' => 'error'}.to_json;
    end
    session=active_room.enter(name)
    @sessions[session.hexdigest]=session
    enter_event=Mate_event.new(session, :enter)
    session.active_room.post_event(enter_event)
    {
      'session' => session.hexdigest,
      'result'  => 'ok'
    }.to_json
  end

  get '/json/mates' do
    session=get_session(params[:session])
    room=session.active_room.room
    mates=Array.new
    room.mates.each do |mate|
      mates << mate
    end
    {
      'result' => 'ok',
      'self_id' => session.mate_id,
      'mates' => mates
    }.to_json
  end

  get '/json/get' do
    event=nil
    session=get_session(params[:session])
    if(session)
      event=session.get_event 
    end
    return {'result' => 'timeout'}.to_json if !event
    puts "sending to "+session.mate.name+" from "+event.author.name
    {
      'result' => 'ok',
      'event' => event
    }.to_json
  end

  get '/json/message' do
    session=get_session(params[:session])
    message=params[:message]
    message=sanitize message
    message_event=Message_event.new(session, message)
    session.active_room.post_event(message_event)
    {'result' => 'ok'}.to_json
  end

  get '/json/typer' do
    session=get_session(params[:session])
    message=params[:message]
    message=sanitize message
    typer_event=Typer_event.new(session, message)
    session.active_room.post_event(typer_event)
    {'result' => 'ok'}.to_json
  end
  
end
  
