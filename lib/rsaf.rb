# typed: strict
# frozen_string_literal: true

require 'optparse'
require 'sorbet-runtime'

require_relative 'rsaf/compiler'
require_relative 'rsaf/config'
require_relative 'rsaf/location'
require_relative 'rsaf/logger'
require_relative 'rsaf/model'
require_relative 'rsaf/model_printer'
require_relative 'rsaf/parser'
require_relative 'rsaf/phases/build_scopes'
require_relative 'rsaf/phases/build_inheritance'

module RSAF
  class CLI
    extend T::Sig

    class Options
      extend T::Sig

      sig { returns(T::Array[String]) }
      attr_reader :args

      sig { returns(T::Boolean) }
      attr_reader :colors

      sig { void }
      def initialize
        @colors = T.let(true, T::Boolean)

        parser = OptionParser.new
        parser.banner = "Usage: rsaf [options] file..."
        parser.separator("")
        parser.separator("Options:")

        parser.on("--no-color", "Do not colorize output") do
          @colors = false
        end

        parser.on_tail("-h", "--help", "Show this message") do
          puts parser
          exit 0
        end

        parser.parse!

        if ARGV.empty?
          puts parser
          exit(1)
        end

        @args = T.let(ARGV, T::Array[String])
      end
    end

    sig { void }
    def self.run
      options = Options.new
      config = Config.new(colors: options.colors) # TODO: option
      compiler = Compiler.new(config)
      files = compiler.list_files(*T.unsafe(options.args))
      model = compiler.compile(*files)
      Model::ModelPrinter.new(colors: options.colors).print_model(model)
    end

    sig { returns(T::Boolean) }
    def self.exit_on_failure?
      false
    end
  end
end
