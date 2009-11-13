require 'monitor' 

# activity tracker is a class used to generate events when mate is
# not active for some time. Class recieve triggers when something is
# active and after specific timeout chxoecks if someone idle long
# enough. Accuracy is timeout/tresholds+timeout%tresholds.

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
    @tresholds=4
    @timeout=8
  end

  # start waiting for event to be triggered
  def launch
    Thread.new do
      i=0
      while !@hash.empty?
        adjust= i%@tresholds==0?@timeout%@tresholds:0
        i+=1
        @hash.synchronize do
          checker
          @cv.wait(@timeout/@tresholds+adjust)
        end
      end
    end
  end

  def active(id)
    # debug output
    # puts Time.now.to_s+' key '+id.to_s+' now active'
    need_to_launch=false
    @hash.synchronize do
      @hash[id]=0
      if @hash.size==1
        need_to_launch=true
      end
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
      # puts Time.now.to_s+" key "+key.to_s+" has value "+@hash[key].to_s
      if value>=@tresholds
        @hash.delete key
        @action.call key
      end
    end
  end
end
