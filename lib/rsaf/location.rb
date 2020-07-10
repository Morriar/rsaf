module RSAF
  class Location
    attr_reader :file, :position

    def initialize(file = nil, position = nil)
      @file = file
      @position = position
    end

    def to_s
      "#{file}:#{position}"
    end
  end

  class Range
    attr_reader :from, :to

    def initialize(from, to)
      @from = from
      @to = to
    end

    def to_s
      "#{from}-#{to}"
    end
  end

  class Position
    attr_reader :line, :column

    def initialize(line, column)
      @line = line
      @column = column
    end

    def to_s
      "#{line}:#{column}"
    end
  end
end
