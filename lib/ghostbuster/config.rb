class Ghostbuster
  class Config
    attr_accessor :pattern, :screenshot_dir, :start_command, :stop_command, :phantom_bin
    attr_reader :screenshot_x, :screenshot_y
    def initialize(path_to_file = nil)
      @config_file = path_to_file || './Ghostfile'
      @screenshot_x, @screenshot_y = 800, 2000
      @pattern = "./test_*.{coffee,js}"
      @phantom_bin = File.join(ENV['HOME'], '.ghostbuster', 'phantomjs')
      @screenshot_dir = "."
      @screenshots = true
      @start_command, @stop_command = "./start.sh", "./stop.sh"
      if File.exist?(@config_file)
        instance_eval File.read(@config_file), @config_file, 1
      end
    end

    def ghost
      self
    end

    def screenshot_dimensions(x, y)
      @screenshot_x, @screenshot_y = x, y
    end

    def do_not_take_screenshots!
      @screenshots = false
    end

    def take_screenshots!
      @screenshots = true
    end

    def screenshots?
      @screenshots
    end
  end
end
    