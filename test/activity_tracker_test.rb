require 'test/unit'
require 'lib/comet-chat'

class Activity_tracker_test < Test::Unit::TestCase
  
  # test that activity fires block after timeout
  def test_simple
    test_flag=false
    at=Activity_tracker.new do
      test_flag=true
    end
    at.active nil
    sleep at.timeout+at.tick_time
    assert test_flag, 'Activity tracker do not work at all'
  end

  # test that quantity of events equals times different id passed
  def test_several_active
    result=[]
    at=Activity_tracker.new do
      result.push nil
    end
    3.times do |i|
      at.active i
    end
    sleep at.timeout+at.tick_time
    assert result.size==3, 'result size is '+result.size.to_s
  end

  # tests that block is triggered only when needed time was passed
  def test_time_added
    result=[]
    at=Activity_tracker.new do |id|
      result.push id
    end
    at.active 1
    sleep at.tick_time
    at.active 2
    sleep at.tick_time
    at.active 1
    sleep at.timeout
    assert result==[2], 'result was: '+result.join(',')
  end

  # tests that block is triggered with id's in correct order
  def test_sequence
    result=[]
    at=Activity_tracker.new do |id|
      result.push id
    end
    at.active 1
    sleep at.tick_time
    at.active 2
    sleep at.tick_time
    at.active 1
    sleep at.tick_time
    at.active 3
    sleep at.timeout+at.tick_time
    assert result==[2,1,3], "result was: "+result.join(", ")
  end

  # test that accuracy is matching required
  def test_max_accuracy
    result=Array.new
    at=Activity_tracker.new do |id|
      result[id]=Time.now-result[id]
    end
    10.times do |i|
      result[i]=Time.now
      at.active i
      sleep at.tick_time
    end
    sleep at.timeout+at.tick_time
    accuracy=result.max-at.timeout
    expected_accuracy=at.tick_time-
      at.timeout%at.tresholds
    assert((accuracy-expected_accuracy).abs>0.02, 'bad accuracy: '+accuracy.to_s)
  end

  # tests that activity tracker control thread
  # do not start if number of active id's reduced to 1
  def test_start_stop
    start_time_for={}
    stop_time=nil
    at=Activity_tracker.new do |id|
      assert((Time.now-start_time_for[id]-at.timeout).to_f.abs<at.tick_time)
    end
    if at.tresholds<3
      puts "Warning: this test supposed to run successfully"+
        "only wich tresholds>3"
    end
    4.times do
      start_time_for[1]=Time.now      
      at.active 1
      sleep at.timeout.to_f/2
      start_time_for[2]=Time.now      
      at.active 2
      sleep at.timeout.to_f/2
      start_time_for[2]=Time.now      
      at.active 2
    end
  end
end
