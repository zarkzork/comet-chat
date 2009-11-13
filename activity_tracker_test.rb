require 'test/unit'
require 'activity_tracker'

class Activity_tracker_test < Test::Unit::TestCase

  # test that activity fires block after timeout
  def test_simple
    test_flag=false
    at=Activity_tracker.new do
      test_flag=true
    end
    at.active nil
    sleep 9
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
    sleep 11
    assert result.size==3, 'result size is '+result.size.to_s
  end

  # tests that block is triggered only when needed time was passed
  def test_time_added
    result=[]
    at=Activity_tracker.new do |id|
      result.push id
    end
    at.active 1
    sleep 3
    at.active 2
    sleep 3
    at.active 1
    sleep 7
    assert result==[2], 'result was: '+result.join(',')
  end

  # tests that block is triggered with id's in correct order
  def test_sequence
    result=[]
    at=Activity_tracker.new do |id|
      result.push id
    end
    at.active 1
    sleep 3
    at.active 2
    sleep 3
    at.active 1
    sleep 2
    at.active 3
    sleep 10
    assert result==[2,1,3]
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
      sleep 1
    end
    sleep 11
    accuracy=result.max-at.timeout
    expected_accuracy=at.timeout/at.tresholds-
      at.timeout%at.tresholds
    assert(accuracy-expected_accuracy<0.1, 'bad accuracy')
  end
end
