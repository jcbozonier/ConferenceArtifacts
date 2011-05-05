task :default => [:test]

task :test do
  ruby 'tests/screen_name_extraction_tests.rb'
end