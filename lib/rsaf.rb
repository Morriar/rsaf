require_relative 'rsaf/compiler'
require_relative 'rsaf/config'
require_relative 'rsaf/logger'

require 'optparse'

module RSAF
  class CLI
    class Options
      attr_reader :args, :colors

      def initialize
        @colors = true

        parser = OptionParser.new
        parser.banner = "Usage: rsaf [options] file..."
        parser.separator ""
        parser.separator "Options:"

        parser.on("--no-color", "Do not colorize output") do
          @colors = false
        end

        parser.on_tail("-h", "--help", "Show this message") do
          puts parser
          exit 0
        end

        parser.parse!

        if ARGV.empty? then
          puts parser
          exit 1
        end

        @args = ARGV
      end
    end

    def self.run
      options = Options.new
      config = Config.new(colors: options.colors) # TODO option
      compiler = Compiler.new(config)
      compiler.parse(*options.args)
    end

    def self.exit_on_failure?
      false
    end
  end
end
