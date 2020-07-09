require 'parser/current'

module RSAF
  class Parser
    def self.init
      # opt-in to most recent AST format:
      ::Parser::Builders::Default.emit_lambda   = true
      ::Parser::Builders::Default.emit_procarg0 = true
      ::Parser::Builders::Default.emit_encoding = true
      ::Parser::Builders::Default.emit_index    = true
    end

    def self.parse_string(string)
      ::Parser::CurrentRuby.parse(string)
    end

    def self.parse_file(path)
      ::Parser::CurrentRuby.parse_file(path)
    end
  end
end
