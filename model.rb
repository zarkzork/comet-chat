require 'rubygems'
require 'json'
require 'dm-core'
require 'digest/md5'

class Room
  include DataMapper::Resource
  
  # proc needed to generate hash digest
  private
    digest_proc=Proc.new { |r, p|
    Digest::MD5.hexdigest(Time.new.to_i.to_s+
                          'salty'+
                          self.object_id.to_s)[0..6]
  }
  
  public
  property :id, Serial
  property(:hexdigest,
           String,
           :writer => :private,
           :default => digest_proc)
  property :topic, String
  has n, :mates

end


class Mate
  include DataMapper::Resource
  property :id, Serial
  property :name, String, :nullable => false
  has n, :messages
  belongs_to :room

  def to_json(*a)
    {
      'id' => id.to_s,
      'name' => name
    }.to_json(*a)
  end
end


class Message
  include DataMapper::Resource
  property :id, Serial
  property :text, String
  property :created_at, DateTime
  belongs_to :mate
end
