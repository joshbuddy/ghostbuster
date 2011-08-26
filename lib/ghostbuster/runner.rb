class Ghostbuster
  class Runner
    def initialize(args)
      @args = args
    end

    def run
      if @args.size == 0
        puts "ghostbuster <path/to/tests>"
        puts "  Version #{VERSION}"
        exit(1)
      else
        Ghostbuster.new(@args).run
      end
    end
  end
end
