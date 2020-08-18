 # typed: strict
# frozen_string_literal: true

module RSAF
  module Parser
    module Base
      extend T::Sig
      extend T::Helpers
      interface!

      sig { abstract.params(string: T.nilable(String)).returns(T.nilable(::AST::Node)) }
      def parse_string(string); end

      sig { abstract.params(path: T.nilable(String)).returns(T.nilable(::AST::Node)) }
      def parse_file(path); end
    end
  end
end
