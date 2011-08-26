class Ghostbuster
  module Shell
    def sh(cmd, &block)
      out, code = sh_with_code(cmd, &block)
      code == 0 ? out : raise(out.empty? ? "Running `#{cmd}' failed. Run this command directly for more detailed output." : out)
    end

    def sh_with_code(cmd, &block)
      outbuf = `#{cmd}`
      block.call(outbuf) if block && $? == 0
      [outbuf, $?]
    end
  end
end
