task :default => [:test]

task :test do
  ruby 'tests/screen_name_extraction_tests.rb'
  ruby 'tests/tweet_relation_tests.rb'
end