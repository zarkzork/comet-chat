require 'digest/md5'

# as current activity tests takes signigicant amount of time they will
# be done only if file or test will be changed
current_activity_md5=
  Digest::MD5.hexdigest(IO.read('activity_tracker.rb'))
current_activity_tests_md5=
  Digest::MD5.hexdigest(IO.read('activity_tracker_test.rb'))
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
  require 'activity_tracker_test'
  this_file.sub!(activity_pattern, '###activity'+
                 '_md5:'+current_activity_md5)
  this_file.sub!(test_pattern, '###activity'+
                 '_test_md5:'+current_activity_tests_md5)
  File.open(__FILE__, 'w+') do |f|
    f.write this_file
  end
end
# this values are part of the test suite do not delete
###activity_md5:b47d6c3ae3fbbf63564823041346b4c2
###activity_test_md5:bdc238722d81db891e3796740843f1bf
