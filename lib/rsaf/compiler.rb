module RSAF
  # Main pipeline orchestrating all the steps
  class Compiler
    def initialize(config)
      @config = config
      @logger = Logger.new(colors: config.colors)
    end

    def compile
    end

    def parse(*file)
      puts list_files(*file)
    end

    def list_files(*paths)
      files = []

      paths.each do |path|
        unless File.exists?(path)
          # TODO logging and errors
          @logger.warn "can't find `#{path}`."
          next
        end
        if File.directory?(path)
          glob = Pathname.new("#{path}/**/*.rb").cleanpath
          Dir.glob(glob).each do |file|
            files << file.strip
          end
        else
          files << path
        end
      end

      files.uniq.sort
    end
  end
end
