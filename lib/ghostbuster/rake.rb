class Ghostbuster
  module Rake
    def self.included(o)
      o.class_eval do
        include Rake::DSL if defined? Rake::DSL
        Ghostbuster::Rake.include_rake_tasks
      end
    end
    def self.include_rake_tasks(opts = {})
      opts[:path]      ||= './ghost'
      opts[:task_name] ||= :"test:ghostbuster"
      desc "Run ghostbuster tasks"
      task opts[:task_name] do
        Ghostbuster.new(opts[:path]).run
      end
    end
  end
end