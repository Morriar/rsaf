# typed: strict
# frozen_string_literal: true

require "colorize"

module RSAF
  class Logger
    extend T::Sig

    sig { params(err: IO, colors: T::Boolean).void }
    def initialize(err: $stderr, colors: true)
      @err = err
      @colors = colors
    end

    sig { params(message: String).void }
    def error(message)
      @err.puts "#{'Error'.colorize(error_color)}: #{message}"
    end

    sig { params(message: String).void }
    def warn(message)
      @err.puts "#{'Warning'.colorize(warn_color)}: #{message}"
    end

    sig { params(message: String).void }
    def log(message)
      @err.puts "Log: #{message}"
    end

    private

    sig { returns(Symbol) }
    def error_color
      @colors ? :red : :uncolored
    end

    sig { returns(Symbol) }
    def warn_color
      @colors ? :yellow : :uncolored
    end
  end
end
