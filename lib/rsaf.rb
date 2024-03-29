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
require_relative 'rsaf/parsing/base'
require_relative 'rsaf/parsing/whitequark'
require_relative 'rsaf/parser'
require_relative 'rsaf/phases/build_scopes'
require_relative 'rsaf/phases/build_inheritance'
require_relative 'rsaf/source_file'
require_relative 'rsaf/source_tree'

module RSAF
  class CLI < Thor
    extend T::Sig

    class_option :global, desc: "Run global analysis phases (like inheritance)", type: :boolean, default: true
    class_option :color, desc: "Use colors", type: :boolean, default: true
    class_option :timers, desc: "Display timers", type: :boolean, default: false

    desc "print *FILES", "print model"
    sig { params(files: String).void }
    option :ignore, desc: "Ignored directories", type: :array, default: []
    def print(*files)
      config = parse_config
      ignore = options[:ignore]
      model = parse_files(*T.unsafe(files), ignore: ignore)
      Model::ModelPrinter.new(colors: config.colors).print_model(model)
    end

    desc "files *FILES", "print files tree"
    sig { params(files: String).void }
    option :ignore, desc: "Ignored directories", type: :array, default: []
    def files(*files)
      config = parse_config
      ignore = options[:ignore]
      compiler = Compiler.new(config)
      sources = compiler.list_files(*T.unsafe(files), ignore: ignore)
      tree = SourceTree.new(*sources)
      tree.show()
    end

    no_commands do
      def parse_config
        @config ||= Config.new(
          colors: options[:color],
          timers: options[:timers],
          global: options[:global],
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
