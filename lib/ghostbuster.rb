# encoding: utf-8

require 'fileutils'
require 'digest/md5'

require 'ghostbuster/version'
require 'ghostbuster/shell'
require 'ghostbuster/config'

class Ghostbuster
  include Shell
  autoload :Rake,  'ghostbuster/rake'
  autoload :Runner, 'ghostbuster/runner'

  def initialize(path)
    STDOUT.sync = true
    @path = path && File.exist?(path) ? path : '.'
    if File.directory?(@path)
      @dir = @path
      @file = 'Ghostfile'
    else
      @dir = File.dirname(@path)
      @file = File.basename(@path)
    end
    @ghost_lib = File.expand_path(File.join(File.dirname(__FILE__), "ghostbuster.coffee"))
  end

  def run
    status = 1
    Dir.chdir(@dir) do
      load_config
      spinner "Starting server" do
        if @config.verbose
          puts `#{@config.start_command}`
          raise unless $!.success?
        else
          sh @config.start_command
        end
        sleep 2
      end
      begin
        _, status = Process.waitpid2 fork { 
          exec("#{@config.phantom_bin} #{@ghost_lib} #{@config.screenshots?} #{@config.screenshot_x} #{@config.screenshot_y} #{@temporary_screenshot_dir} #{Dir[@config.pattern].to_a.join(' ')}") 
        }
        if @config.screenshots?
          spinner "Copying screenshots" do
            compress_and_copy_screenshots
          end
        end
      ensure
        spinner "Stopping server" do
          if @config.verbose
            puts `#{@config.stop_command}`
            raise unless $!.success?
          else
            sh @config.stop_command
          end
        end
        if @config.screenshots?
          spinner "Cleaning up temporary screenshots" do
            cleanup_screenshots
          end
        end
      end
    end
    exit(status.to_i)
  end

  def self.run(path)
    new(path).run
  end

  private
  def compress_and_copy_screenshots
    FileUtils.rm_f(File.join(@config.screenshot_dir, "*.png"))
    files = Dir[File.join(@temporary_screenshot_dir, '*.png')].to_a
    files.map{|f| f[/(.*?)-\d+\.png$/, 1]}.uniq.each do |cluster|
      images = files.select{|f| f[cluster]}.sort_by{|f| Integer(f[/\-(\d+)\.png$/, 1])}
      idx = 0
      while idx < (images.size - 1)
        if Digest::MD5.file(images[idx]) == Digest::MD5.file(images[idx + 1])
          images.slice!(idx + 1)
        else
          idx += 1
        end
      end
      images.each_with_index do |f, idx|
        FileUtils.mv(f, File.join(@config.screenshot_dir, "#{File.basename(f)[/(.*?)\-\d+\.png$/, 1]}-%03d.png" % (idx + 1)))
      end
    end
  end

  def cleanup_screenshots
    FileUtils.rm_rf @temporary_screenshot_dir
  end

  def load_config
    @config = Config.new(@file)
    @temporary_screenshot_dir = File.join(@config.temp_dir, "ghost-#{Process.pid}-#{Time.new.to_i}")
    FileUtils.mkdir_p(@temporary_screenshot_dir) if @config.screenshots?
  end

  def spinner(msg, &blk)
    spin = Thread.new do
      i = 0
      s = '/-\\|'
      loop do
        print "\r#{msg} #{s[i % 4].chr}"
        i += 1
        sleep 0.05
      end
    end
    yield
    spin.kill
    puts "\r#{msg} ✓"
  end
end