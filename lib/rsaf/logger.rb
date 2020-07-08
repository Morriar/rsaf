require "colorize"

class Logger
  def initialize(err: $stderr, colors: true)
    @err = err
    @colors = colors
  end

  def error(message)
    @err.puts "#{"Error".colorize(error_color)}: #{message}"
  end

  def warn(message)
    @err.puts "#{"Warning".colorize(warn_color)}: #{message}"
  end

  def log(message)
    @err.puts "Log: #{message}"
  end

  private

  def error_color
    @colors ? :red : :uncolored
  end

  def warn_color
    @colors ? :yellow : :uncolored
  end
end
