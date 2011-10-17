require 'bundler/gem_tasks'

STDOUT.sync = true

namespace :test do
  [:working_via_bin, :working_via_rake].each do |task_name|
    desc "Run test for `working' test suite (#{task_name})"
    task task_name do
      print "#{task_name} ... "
      Dir.chdir("test/working_ghost") do
        matcher = [/13 success, 0 failure, 1 pending/]
        fork {
          ENV['BUNDLE_GEMFILE'] = File.expand_path("./Gemfile")
          `bundle install`
          out = case task_name
          when :working_via_rake then `bundle exec rake test:ghostbuster 2>&1`
          when :working_via_bin  then `bundle exec ghostbuster . 2>&1`
          end
          begin
            matcher.each{|m| out[m] or raise("Couldn't match for #{m.inspect}")}
            real_size = Dir['*.png'].to_a.size
            expected_size = 20
            raise("There are a weird number of screenshots, expected #{expected_size}, got #{real_size}") unless expected_size == real_size
            exit
          rescue
            puts $!.message
            puts out
            exit(1)
          end
        }
        _, status = Process.wait2
        puts status.success? ? "PASSED" : "FAILED"
      end
    end
  end

  desc "Run test for `non_working' test suite"
  task :non_working do
    print "non_working_ghost ... "
    Dir.chdir("test/non_working_ghost") do
      matcher = [/0 success, 10 failure, 1 pending/, /Bad link traversal\s+Assert location failed: Excepted http:\/\/127\.0\.0\.1:4567\/not-correct, got http:\/\/127\.0\.0\.1:4567\//, /Form input not equal\s+Assert first for selector #out did not meet expectations/, /To an invalid URL\s+The request for http:\/\/127\.0\.0\.1:this-url-is-invalid failed/, /This test will explode!\s+I hate you!/, /This test has no succeed\s+This test took too long/, /This test has a custom assertion name\s+Assert first "custom assertion name" did not meet expectations/, /Bad click selector\s+Couldn't find element 0 for selector i-just-made-this-up/, /Bad click follow\s+Assert not location failed: Excepted not http:\/\/127\.0\.0\.1:4567\/, got http:\/\/127\.0\.0\.1:4567\//]
      fork {
        ENV['BUNDLE_GEMFILE'] = File.expand_path("./Gemfile")
        `bundle install`
        out = `bundle exec ghostbuster . 2>&1`
        begin
          matcher.each{|m| out[m] or raise("Couldn't match for #{m.inspect}")}
          exit
        rescue
          puts $!.message
          puts out
          exit(1)
        end
      }
      _, status = Process.wait2
      puts status.success? ? "PASSED" : "FAILED"
    end
  end
end
  
task :test => [:'test:working_via_bin', :'test:working_via_rake', :'test:non_working']
