class Ghostbuster
  class Runner
    def initialize(args)
      @args = args
    end

    def run
      if @args.size != 1
        puts "ghostbuster <path/to/tests>"
        puts "  Version #{VERSION}"
        exit(1)
      else
        Ghostbuster.new(@args.first).run
      end
    end
  end
end
