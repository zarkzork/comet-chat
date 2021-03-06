require 'monitor' 

#Thread.abort_on_exception=true

# activity tracker is a class used to generate events when mate is
# not active for some time. Class recieve triggers when something is
# active and after specific timeout checks if someone idle long
# enough. Accuracy is timeout/tresholds

class Activity_tracker
  # :tresholds -- number of tresholds that should pass before trigger will be active
  # :timoeout -- is timeout in seconds after which trigger should arise
  attr_accessor :tresholds, :timeout

  def tick_time
    @timeout.to_f/@tresholds
  end

  def initialize(&on_expire)
    @on_expire=on_expire # action to do when session is expired
    @hash=Hash.new
    @hash.extend(MonitorMixin)
    @cv=@hash.new_cond
    # default values
    @tresholds=10
    @timeout=80
  end

  def done(key)
    @hash.synchronize do
      @hash.delete key
      @on_expire.call key
    end
  end

  def active(key)
    need_to_launch=false
    @hash.synchronize do
      if @hash.size==0
        need_to_launch=true
      end
      @hash[key]=1
    end
    if need_to_launch
      launch
    end
  end

  protected
  # call block if enough tresholds passed to call on expire action 
  def checker
    @hash.each_pair do |key, value|
      @hash[key]=value+1
      if value>=@tresholds
        @hash.delete key
        @on_expire.call key
      end
    end
  end

  # start waiting for event to be triggered
  def launch
    Thread.new do
      start_time=nil
      finish_time=nil
      adjust=tick_time
      while !@hash.empty?
        @hash.synchronize do
          start_time=Time.now
          @cv.wait(adjust)
          checker
          finish_time=Time.now
          adjust=2*tick_time-(finish_time-start_time).to_f
          adjust=0 if adjust<0
        end
      end
    end
  end

end
