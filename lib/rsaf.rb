# typed: strict
# frozen_string_literal: true

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

module RSAF
  class CLI < Thor
    extend T::Sig

    default_task :parse

    class_option :color, desc: "Use colors", type: :boolean, default: true


    desc "run FILE *FILES", "parses files"
    sig { params(files: String).void }
    def parse(*files)
      if files.empty?
        $stderr.puts "Error: no files given."
        help
        exit 1
      end
      config = Config.new(colors: options[:color]) # TODO: option
      compiler = Compiler.new(config)
      files = compiler.list_files(*T.unsafe(files))
      model = compiler.compile(*files)
      Model::ModelPrinter.new(colors: config.colors).print_model(model)
    end

    sig { returns(T::Boolean) }
    def self.exit_on_failure?
      false
    end
  end
end
