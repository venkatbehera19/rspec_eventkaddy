# run all tests in minitest folder
#
# Deprecated; this was only used briefly to try out tests
# while avoiding the errors in rake test
Dir.glob('./app/**/*_test.rb').each { |file| require file }
