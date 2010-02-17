require 'net/http'
require 'uri'
require 'digest/md5'
require 'thread'
require 'rubygems'
require 'json'

URL='http://localhost:9292'

@global_requests_counter=0
@global_counter_mutex=Mutex.new

@global_error_counter=0
@global_error_counter_mutex=Mutex.new

def start(room="test")
  doing_requests=true
  requests_counter=0
  requests_mutex=Mutex.new
  session=enter_room(generate_name(), room)
  events_thread=Thread.new do
    req=0
    while doing_requests do
      get_event(session, room)
      req+=1
    end
    requests_mutex.synchronize do
      requests_counter+=req
    end
  end
  messages_thread=Thread.new do
    req=0
    while doing_requests do
      post_message(session, room)
      req+=1
      sleep rand(10)
    end
    requests_mutex.synchronize do
      requests_counter+=req
    end
  end
  sleep 360
  doing_requests=false
  messages_thread.join
  events_thread.join
  @global_counter_mutex.synchronize do
    @global_requests_counter+=requests_counter
  end
end

def getJSON(method, params, room)
  request=URL+'/json/'+room+'/'+method+"?"+params
  result=Net::HTTP.get_response(URI.parse(request))
  json_result=JSON.parse result.body
  if((!result.kind_of?(Net::HTTPSuccess))||json_result['result']=='error')
    puts "There was error in request: "+request    
    @global_error_counter_mutex.synchronize do
      @global_error_counter+=1
    end
  end
  json_result
end

def enter_room(name, room)
  getJSON('enter', 'name='+name, room)['session']
end

def get_event(session, room)
  getJSON('get', 'session='+session, room)
end

def post_message(session, room)
  getJSON('message', 'session='+session+'&message=tst', room)
end

def generate_name
  Digest::MD5.hexdigest(Time.now.to_f.to_s)
end

puts "started test"

threads = []
start_time=Time.now

28.times do
  room_name=generate_name
  4.times do
    threads << Thread.new do
      sleep rand(5)
      start(room_name)
    end
  end
end

threads.each { |t| t.join }
finish_time=Time.now

puts "total requests done: "+@global_requests_counter.to_s
puts "errors counter: "+@global_error_counter.to_s
puts "tests lasted for: "+(finish_time-start_time).to_s
