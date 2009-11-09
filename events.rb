require 'rubygems'
require 'json'

class Event
  attr :author
  attr :created_at

  def initialize(session)
    @author=session.mate
    @created_at=Time.now
  end

  def process
  end
  
  def to_json(*a)
    json_hash.to_json(*a)
  end
  protected
  def json_hash
    {
      'type' => self.class.name,
      'author' => @author.name,
      'time' => @created_at.to_i
    }    
  end
end


class Text_event < Event
  attr :message

  def initialize(session, message)
    super(session)
    @message=message
  end

  def to_json(*a)
    json_hash.to_json(*a)
  end
  
  protected
  def json_hash
    hash=super
    hash['message']=@message
    hash
  end
end

class Message_event < Text_event
  def initialize(session, message)
    super(session, message)
  end
end

class Typer_event < Text_event
  def initialize(session, message)
    super(session, message)
  end
end
