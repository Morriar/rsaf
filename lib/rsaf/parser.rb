# typed: strict
# frozen_string_literal: true

module RSAF
  module Parser
    extend T::Sig

    @@default_parser = T.let(RSAF::Parser::Whitequark.new, RSAF::Parser::Base)

    sig { params(string: T.nilable(String)).returns(T.nilable(::AST::Node)) }
    def self.parse_string(string)
      @@default_parser.parse_string(string)
    end

    sig { params(path: T.nilable(String)).returns(T.nilable(::AST::Node)) }
    def self.parse_file(path)
      @@default_parser.parse_file(path)
    end
  end
end
