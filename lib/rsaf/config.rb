module RSAF
  class Config
    attr_reader :colors

    def initialize(colors: true)
      @colors = colors
    end
  end
end
