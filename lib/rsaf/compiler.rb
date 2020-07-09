module RSAF
  # Main pipeline orchestrating all the steps
  class Compiler
    def initialize(config)
      @config = config
      @logger = Logger.new(colors: config.colors)
    end

    def modelize(*trees)
      model = Model.new
      builder = ModelBuilder.new(model)
      builder.build(*trees)
      model
    end

    def parse_string(string)
      Parser.parse_string(string)
    end

    def parse_file(file)
      Parser.parse_file(file)
    end

    def parse_files(*files)
      files.map { |file| parse_file(file) }
    end

    def list_files(*paths)
      files = []
      paths.each do |path|
        unless File.exists?(path)
          @logger.warn "can't find `#{path}`."
          next
        end
        if File.directory?(path)
          files.push(*Dir.glob(Pathname.new("#{path}/**/*.rb").cleanpath))
        else
          files << path
        end
      end
      files.uniq.sort
    end
  end
end
