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

    sig { params(sources: SourceFile).returns(Model) }
    def compile(*sources)
      model = Model.new
      start_clock
      sources.each do |source|
        parse_source(source)
      end
      puts "Parsing... (#{stop_clock}s)" if @config.timers
      start_clock
      sources.each do |source|
        run_local_phases(model, source)
      end
      puts "Local phases... (#{stop_clock}s)" if @config.timers
      if @config.global
        start_clock
        run_global_phases(model)
        puts "Global phases... (#{stop_clock}s)" if @config.timers
      end
      model
    end

    sig { params(code: String).returns(Model) }
    def compile_code(code)
      model = Model.new
      start_clock
      source = parse_string(code)
      puts "Parsing... (#{stop_clock}s)" if @config.timers
      start_clock
      run_local_phases(model, source)
      puts "Local phases... (#{stop_clock}s)" if @config.timers
      if @config.global
        start_clock
        run_global_phases(model)
        puts "Global phases... (#{stop_clock}s)" if @config.timers
      end
      model
    end

    sig { params(model: Model, source: SourceFile).void }
    def run_local_phases(model, source)
      Phases::BuildScopes.run(model, source)
    end

    sig { params(model: Model).void }
    def run_global_phases(model)
      Phases::BuildInheritance.run(model)
    end

    sig { params(string: String).returns(SourceFile) }
    def parse_string(string)
      tree = Parser.parse_string(string)
      SourceFile.new(tree: tree)
    rescue ::Parser::SyntaxError
      # TODO add errors to file
      SourceFile.new
    end

    sig { params(source: SourceFile).void }
    def parse_source(source)
      source.tree = Parser.parse_file(source.path)
    rescue ::Parser::SyntaxError
      # TODO add errors to file
    end

    sig { params(paths: String, ignore: T::Array[String]).returns(T::Array[SourceFile]) }
    def list_files(*paths, ignore: [])
      files = T.let([], T::Array[String])
      paths.each do |path|
        unless File.exist?(path)
          @logger.warn("can't find `#{path}`.")
          next
        end
        if File.directory?(path)
          files = files.concat(Dir.glob(Pathname.new("#{path}/**/*.{rb,rbi}").cleanpath.to_s))
        else
          files << path
        end
      end
      ignore.each do |ignored_path|
        files.reject! { |path| path.start_with?(ignored_path) }
      end
      files.uniq.sort.map do |f|
        strictness = File.read(f).match(/#\s*typed\s*:\s*([a-zA-Z_]+)\s*$/)&.[](1)
        SourceFile.new(path: f, strictness: strictness)
      end
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
