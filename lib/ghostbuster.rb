require 'ghostbuster/version'
require 'ghostbuster/shell'

class Ghostbuster
  include Shell
  autoload :Rake,  'ghostbuster/rake'
  autoload :Runner, 'ghostbuster/runner'

  def initialize(path)
    @path = path
    @dir = File.directory?(path) ? path : File.dirname(path)
    @ghost_lib = File.expand_path(File.join(File.dirname(__FILE__), "ghostbuster.coffee"))
    @phantom_bin = File.join(ENV['HOME'], '.ghostbuster', 'phantomjs')
  end

  def run
    files = Dir[@path].to_a.map{|f| File.expand_path(f)}
    status = 1
    Dir.chdir(@dir) do
      sh "./start.sh"
      sleep 2
      begin
        _, status = Process.waitpid2 fork { exec("#{@phantom_bin} #{@ghost_lib} #{files.join(' ')}") }
      ensure
        sh "./stop.sh"
      end
    end
    exit(status)
  end

  def self.run(path)
    new(path).run
  end
end