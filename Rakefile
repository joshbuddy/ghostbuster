require 'bundler/gem_tasks'

STDOUT.sync = true

namespace :test do
  desc "Run test for `working' test suite (via binary)"
  task :working_via_bin do
    print "working_ghost via bin ... "
    Dir.chdir("test/working_ghost") do
      matcher = [/9 success, 0 failure, 1 pending/]
      fork {
        ENV['BUNDLE_GEMFILE'] = File.expand_path("./Gemfile")
        `bundle install`
        out = `bundle exec ghostbuster . 2>&1`
        unless matcher.all?{|m|out[m]}
          puts out
          exit(1)
        end
        raise("There are a weird number of screenshots") unless Dir['*.png'].to_a.size == 12
        exit
      }
      _, status = Process.wait2
      puts status.success? ? "PASSED" : "FAILED"
    end
  end

  desc "Run test for `working' test suite (via rake)"
  task :working_via_rake do
    print "working_ghost via rake ... "
    Dir.chdir("test/working_ghost") do
      matcher = [/9 success, 0 failure, 1 pending/]
      fork {
        ENV['BUNDLE_GEMFILE'] = File.expand_path("./Gemfile")
        `bundle install`
        out = `bundle exec rake test:ghostbuster 2>&1`
        unless matcher.all?{|m|out[m]}
          puts out
          exit(1)
        end
        raise("There are a weird number of screenshots") unless Dir['*.png'].to_a.size == 12
        exit
      }
      _, status = Process.wait2
      puts status.success? ? "PASSED" : "FAILED"
    end
  end

  desc "Run test for `non_working' test suite"
  task :non_working do
    print "non_working_ghost ... "
    Dir.chdir("test/non_working_ghost") do
      matcher = [/0 success, 5 failure, 0 pending/, /Bad link traversal\s+Assert location failed: Excepted http:\/\/127\.0\.0\.1:4567\/not-correct, got http:\/\/127\.0\.0\.1:4567\//, /Form input not equal\s+Assert first for selector #out did not meet expectations/, /This test will explode!\s+I hate you!/, /This test has no succeed\s+This test took too long/]
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
