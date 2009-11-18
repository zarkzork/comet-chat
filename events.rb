require 'rubygems'
require 'json'

class Event
  attr :author
  attr :created_at

  def initialize(name)
    @author=name
    @created_at=Time.now
  end

  def to_json(*a)
    json_hash.to_json(*a)
  end
  protected
  def json_hash
    {
      'type' => self.class.name,
      'author' => @author,
      'time' => @created_at.to_i
    }    
  end
end

class Mate_event < Event
  attr :status

  def initialize(name, status)
    super(name)
    @status=status
  end
  
  def to_json(*a)
    json_hash.to_json(*a)
  end

  protected
  def json_hash
    hash=super
    hash['status']=@status
    hash['mate']=@author
    hash
  end
end

class Text_event < Event
  attr :message

  def initialize(name, message)
    super(name)
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
  def initialize(name, message)
    super(name, message)
  end
end

class Typer_event < Text_event
  def initialize(name, message)
    super(name, message)
  end
end
