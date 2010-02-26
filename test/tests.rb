require 'digest/md5'
require 'test/json_test'

# as current activity tests takes signigicant amount of time they will
# be done only if file or test will be changed
current_activity_md5=
  Digest::MD5.hexdigest(IO.read('/lib/activity_tracker.rb'))
current_activity_tests_md5=
  Digest::MD5.hexdigest(IO.read('/test/activity_tracker_test.rb'))
this_file=IO.read(__FILE__)
activity_pattern=/##+activity_md5:(.*)$/
test_pattern=/##+activity_test_md5:(.*)$/
this_file =~ activity_pattern
old_activity_md5=$1
this_file =~ test_pattern
old_activity_test_md5=$1
if current_activity_tests_md5!=old_activity_test_md5||
    current_activity_md5!=old_activity_md5
  puts 'Activity class or tests changed so it will be started.'
  puts 'be patient'
  require 'test/activity_tracker_test'
  this_file.sub!(activity_pattern, '###activity'+
                 '_md5:'+current_activity_md5)
  this_file.sub!(test_pattern, '###activity'+
                 '_test_md5:'+current_activity_tests_md5)
  File.open(__FILE__, 'w+') do |f|
    f.write this_file
  end
end
# this values are part of the test suite do not delete
###activity_md5:8fdb910fe5586d61dce1590e755e9e15
###activity_test_md5:dfc652d68df8cf3e7493ede131bbb966
