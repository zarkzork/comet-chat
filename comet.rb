require 'monitor'
require 'digest/md5'

class Active_room
  def initialize(room)
    @room_id=room.id
    @sessions=Hash.new
  end

  def room
    Room.get(@room_id)
  end

  def enter(name)
    room_mates=Mate.all('room.id' => @room_id)
    mate=room_mates.first(:name => name)
    if !mate
      mate=Mate.create(:name => name, :room_id => @room_id)
      room=Room.get(@room_id)
      room.mates << mate
      room.save
    end
    session=Active_session.new(self, mate)
    @sessions[session.hexdigest]=session
  end

  def [](session_id)
    @sessions[session_id]
  end

  def post_event(event)
    @sessions.each_value do |session|
      session.post_event(event)
    end
  end
end


class Active_session
  attr :hexdigest
  attr :mate_id
  attr :active_room
  WAIT_TIMEOUT=30

  def initialize(active_room, mate)
    @mate_id=mate.id
    @hexdigest=
      Digest::MD5.hexdigest(Time.new.to_i.to_s+
                            'salty'+
                            self.object_id.to_s)
    @active_room=active_room
    @event_queue=Array.new
    @event_queue.extend(MonitorMixin)
    @cv=@event_queue.new_cond
  end

  def mate
    Mate.get(@mate_id)
  end

  def post_event(event)
    @event_queue.synchronize {
      @event_queue << event
      @cv.signal
    }
  end

  def get_event
    event=nil
    @event_queue.synchronize {
      begin
        event=nil
        @cv.wait(WAIT_TIMEOUT) if @event_queue.empty?
        event=@event_queue.pop if !@event_queue.empty?
      end while (event!=nil&&@mate_id==event.author.id)
    }
    event
  end
end
