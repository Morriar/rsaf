# typed: true
# frozen_string_literal: true

require "json"
require 'thor'
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
require_relative 'rsaf/source_file'

module RSAF
  class CLI < Thor
    extend T::Sig

    class_option :color, desc: "Use colors", type: :boolean, default: true
    class_option :timers, desc: "Display timers", type: :boolean, default: false

    desc "print *FILES", "print model"
    sig { params(files: String).void }
    def print(*files)
      config = parse_config
      model = parse_files(*T.unsafe(files))
      Model::ModelPrinter.new(colors: config.colors).print_model(model)
    end

    no_commands do
      def parse_config
        @config ||= Config.new(
          colors: options[:color],
          timers: options[:timers],
        )
      end

      def parse_files(*files)
        if files.empty?
          $stderr.puts "Error: no files given."
          help
          exit 1
        end
        compiler = Compiler.new(parse_config)
        files = compiler.list_files(*T.unsafe(files))
        compiler.compile(*files)
      end
    end

    sig { returns(T::Boolean) }
    def self.exit_on_failure?
      false
    end
  end
end
