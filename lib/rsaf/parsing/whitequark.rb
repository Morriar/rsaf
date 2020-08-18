# typed: strict
# frozen_string_literal: true

require 'parser/current'

module RSAF
  module Parser
    class Whitequark
      extend T::Sig
      include Base

      sig { void }
      def initialize
        # opt-in to most recent AST format:
        ::Parser::Builders::Default.emit_lambda   = true
        ::Parser::Builders::Default.emit_procarg0 = true
        ::Parser::Builders::Default.emit_encoding = true
        ::Parser::Builders::Default.emit_index    = true
      end

      sig { override.params(string: T.nilable(String)).returns(T.nilable(::AST::Node)) }
      def parse_string(string)
        return nil unless string
        ::Parser::CurrentRuby.parse(string)
      end

      sig { override.params(path: T.nilable(String)).returns(T.nilable(::AST::Node)) }
      def parse_file(path)
        return nil unless path
        ::Parser::CurrentRuby.parse_file(path)
      end
    end
  end
end
