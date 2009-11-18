require 'monitor' 

#Thread.abort_on_exception=true

# activity tracker is a class used to generate events when mate is
# not active for some time. Class recieve triggers when something is
# active and after specific timeout chxoecks if someone idle long
# enough. Accuracy is timeout/tresholds

class Activity_tracker
  # number of tresholds that should pass before trigger will be active
  attr :tresholds
  # is timeout in seconds after which trigger should arise
  attr :timeout
  
  def initialize(&action)
    @action=action
    @hash=Hash.new
    @hash.extend(MonitorMixin)
    @cv=@hash.new_cond
    # default values
    @tresholds=10
    @timeout=40
  end

  def tick_time
    @timeout.to_f/@tresholds
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

  def active(id)
    # debug output
    puts Time.now.to_s+' key '+id.to_s+' now active'
    need_to_launch=false
    @hash.synchronize do
      if @hash.size==0
        need_to_launch=true
      end
      @hash[id]=1
    end
    if need_to_launch
      launch
    end
  end

  protected
  # debug output
  # call block if enough tresholds passed
  def checker
    @hash.each_pair do |key, value|
      @hash[key]=value+1
      puts Time.now.to_s+" key "+key.to_s+" has value "+@hash[key].to_s
      if value>=@tresholds
        @hash.delete key
        @action.call key
      end
    end
  end
end
