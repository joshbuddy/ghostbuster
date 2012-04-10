class Ghostbuster
  class Runner
    def initialize(args)
      @args = args
    end

    def run
      if @args.size == 1 && @args.first == /^--?[\?h](|elp)$/i or @args.size > 1
        puts "ghostbuster [path/to/Ghostfile]"
        puts "  Version #{VERSION}"
        exit(0)
      else
        exit Ghostbuster.new(@args.first).run
      end
    end
  end
end
