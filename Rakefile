require 'bundler/gem_tasks'
$: << 'lib'
require 'ghostbuster/install_rake'

def test_output
  out = `bundle exec rake test:ghostbuster`
  $?.success? ? out.gsub(/server .*?\n/m, "server\n") : raise("there was a problem")
end

desc "Run tests"
task :test do
  out = test_output
  if File.read(File.join(File.dirname(__FILE__), 'test', 'output')) == out
    puts "Everything is great!"
  else
    puts out
    raise "Things aren't great."
  end
end

desc "Update tests"
task :'test:update' do
  File.open(File.join(File.dirname(__FILE__), 'test', 'output'), 'w') {|f| f << test_output}
  puts "Test output updated"
end

desc "Show output"
task :"test:output" do
  puts test_output
end