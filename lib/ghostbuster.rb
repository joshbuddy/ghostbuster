require 'ghostbuster/version'
require 'ghostbuster/shell'
require 'ghostbuster/config'

class Ghostbuster
  include Shell
  autoload :Rake,  'ghostbuster/rake'
  autoload :Runner, 'ghostbuster/runner'

  def initialize(path)
    @path = File.exist?(path) ? path : '.'
    @dir = File.directory?(@path) ? @path : File.basename(@path)
    @file = File.directory?(@dir) ? File.join(@dir, 'Ghostfile') : @dir
    @ghost_lib = File.expand_path(File.join(File.dirname(__FILE__), "ghostbuster.coffee"))
    @phantom_bin = File.join(ENV['HOME'], '.ghostbuster', 'phantomjs')
    @config = Config.new(@file)
    STDOUT.sync = true
  end

  def run
    status = 1
    Dir.chdir(@dir) do
      spinner "Starting server" do
        sh "./start.sh"
        sleep 2
      end
      begin
        _, status = Process.waitpid2 fork { exec("#{@phantom_bin} #{@ghost_lib} #{@config.screenshots?} #{@config.screenshot_x} #{@config.screenshot_y} #{File.expand_path(@config.screenshot_dir)} #{Dir[@config.pattern].to_a.join(' ')}") }
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