# typed: strict
# frozen_string_literal: true

module RSAF
  # Main pipeline orchestrating all the steps
  class Compiler
    extend T::Sig

    sig { params(config: Config).void }
    def initialize(config)
      @config = config
      @logger = T.let(Logger.new(colors: config.colors), Logger)
      @lapse = T.let(nil, T.nilable(T.any(Integer, Float)))
    end

    sig { params(files: String).returns(Model) }
    def compile(*files)
      model = Model.new
      start_clock
      couples = files.map do |file|
        [file, parse_file(file)]
      end
      puts "Parsing... (#{stop_clock}s)" if @config.timers
      start_clock
      couples.each do |couple|
        run_local_phases(model, couple.first, couple.last)
      end
      puts "Local phases... (#{stop_clock}s)" if @config.timers
      start_clock
      run_global_phases(model)
      puts "Global phases... (#{stop_clock}s)" if @config.timers
      model
    end

    sig { params(code: String).returns(Model) }
    def compile_code(code)
      model = Model.new
      start_clock
      tree = parse_string(code)
      puts "Parsing... (#{stop_clock}s)" if @config.timers
      start_clock
      run_local_phases(model, nil, tree)
      puts "Local phases... (#{stop_clock}s)" if @config.timers
      start_clock
      run_global_phases(model)
      puts "Global phases... (#{stop_clock}s)" if @config.timers
      model
    end

    sig { params(model: Model, file: T.nilable(String), tree: T.nilable(AST::Node)).void }
    def run_local_phases(model, file, tree)
      Phases::BuildScopes.run(model, file, tree)
    end

    sig { params(model: Model).void }
    def run_global_phases(model)
      Phases::BuildInheritance.run(model)
    end

    sig { params(string: String).returns(T.nilable(AST::Node)) }
    def parse_string(string)
      Parser.parse_string(string)
    end

    sig { params(file: String).returns(T.nilable(AST::Node)) }
    def parse_file(file)
      Parser.parse_file(file)
    end

    sig { params(paths: String).returns(T::Array[String]) }
    def list_files(*paths)
      files = []
      paths.each do |path|
        unless File.exist?(path)
          @logger.warn("can't find `#{path}`.")
          next
        end
        if File.directory?(path)
          files = files.concat(Dir.glob(Pathname.new("#{path}/**/*.rb").cleanpath))
        else
          files << path
        end
      end
      files.uniq.sort
    end

    private

    sig { void }
    def start_clock
      @lapse = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end

    sig { returns(Numeric) }
    def stop_clock
      (Process.clock_gettime(Process::CLOCK_MONOTONIC) - T.must(@lapse)).round(3)
    end
  end
end
