require 'ghostbuster/version'
require 'ghostbuster/shell'

class Ghostbuster
  include Shell
  autoload :Rake,  'ghostbuster/rake'
  autoload :Runner, 'ghostbuster/runner'

  def initialize(*paths)
    @paths = paths
    @paths.flatten!
    @dir = File.directory?(@paths[0]) ? @paths[0] : File.dirname(@paths[0])
    @ghost_lib = File.expand_path(File.join(File.dirname(__FILE__), "ghostbuster.coffee"))
    @phantom_bin = File.join(ENV['HOME'], '.ghostbuster', 'phantomjs')
    STDOUT.sync = true
  end

  def run
    files = Array(@paths).map{|path| Dir[path].to_a}.flatten.map{|f| File.expand_path(f)}
    status = 1
    Dir.chdir(@dir) do
      spinner "Starting server" do
        sh "./start.sh"
        sleep 2
      end
      begin
        _, status = Process.waitpid2 fork { exec("#{@phantom_bin} #{@ghost_lib} #{files.join(' ')}") }
      ensure
        spinner "Stopping server" do
          sh "./stop.sh"
        end
      end
    end
    exit(status)
  end

  def self.run(path)
    new(path).run
  end

  private
  def spinner(msg, &blk)
    STDOUT.sync = true
    print msg
    print " "
    spin = Thread.new do
      i = 0
      loop do
        s = '/-\\|'
        print s[i % 4].chr
        i += 1
        sleep 0.1
        print "\b"
      end
    end
    yield
    spin.kill
    puts
  end
end