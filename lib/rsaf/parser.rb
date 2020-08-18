# typed: strict
# frozen_string_literal: true

require 'parser/current'

module RSAF
  class Parser
    extend T::Sig

    sig { void }
    def self.init
      # opt-in to most recent AST format:
      ::Parser::Builders::Default.emit_lambda   = true
      ::Parser::Builders::Default.emit_procarg0 = true
      ::Parser::Builders::Default.emit_encoding = true
      ::Parser::Builders::Default.emit_index    = true
    end

    sig { params(string: T.nilable(String)).returns(T.nilable(::AST::Node)) }
    def self.parse_string(string)
      return nil unless string
      ::Parser::CurrentRuby.parse(string)
    end

    sig { params(path: T.nilable(String)).returns(T.nilable(::AST::Node)) }
    def self.parse_file(path)
      return nil unless path
      ::Parser::CurrentRuby.parse_file(path)
    end
  end
end
