require 'monitor'
require 'thread'
require 'digest/md5'

class Active_room

  def initialize(topic="change me")
    @sessions=Hash.new
    @topic=topic
    @topic_mutex=Mutex.new
  end

  def topic
    @topic
  end
  
  def topic=(topic)
    @topic_mutex.synchronize do
      @topic=topic
    end
    @topic
  end

  def empty?
    @sessions.empty?
  end
  
  def enter(name)
    session=Active_session.new(self, name)
    @sessions[session.hexdigest]=session
  end

  def [](session_id)
    @sessions[session_id]
  end

  def names
    result=[]
    @sessions.each_value do |session|
      result.push session.name
    end
    result
  end
  
  def contains_name?(name)
    result=false
    @sessions.each_value do |session|
      result=true if session.name==name
    end
    result
  end

  def remove(session_id)
    @sessions.delete session_id
  end

  def post_event(event)
    @sessions.each_value do |session|
      session.post_event(event)
    end
  end
end


class Active_session
  attr :hexdigest
  attr :active_room
  attr :name
  
  WAIT_TIMEOUT=30

  def initialize(active_room, name)
    @active_room=active_room
    @event_queue=Array.new
    @event_queue.extend(MonitorMixin)
    @cv=@event_queue.new_cond
    @name=name
    @hexdigest=
      Digest::MD5.hexdigest(Time.new.to_i.to_s+
                            'salty'+
                            self.object_id.to_s)
  end

  def post_event(event)
    @event_queue.synchronize {
      @event_queue << event
      @cv.signal
    }
  end

  # sleep while there is no events or author of events is session
  # owner. end if none of this happend return error after timeout.
  def get_event
    event=nil
    finish_time=start_time=Time.now;
    time_to_sleep=0
    begin
      event=nil
      @event_queue.synchronize do
        time_to_sleep=WAIT_TIMEOUT-(finish_time-start_time)
        if time_to_sleep<0
          break
        end
        @cv.wait(time_to_sleep) if @event_queue.empty?
        event=@event_queue.pop if !@event_queue.empty?
        finish_time=Time.now
      end
    end while (event!=nil&&(@name==event.author))
    event
  end
end
