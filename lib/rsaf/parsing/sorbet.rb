# typed: strict
# frozen_string_literal: true

require "open3"
require "sexpistol"

module RSAF
  module Parser
    class Sorbet
      extend T::Sig
      include Base

      sig { override.params(string: T.nilable(String)).returns(T.nilable(::AST::Node)) }
      def parse_string(string)
        Open3.popen3("bundle exec srb tc --no-config --stop-after desugarer --print parse-tree-whitequark -e \"#{string}\"") do |i, o, e, t|
          # TODO handle errors
          parser = Sexpistol.new
          array = parser.parse_string(o.read)
          # puts array
          AST::Node.new(array.first, array.last)
        end
      end

      sig { override.params(path: T.nilable(String)).returns(T.nilable(::AST::Node)) }
      def parse_file(path)
        Open3.popen3("bundle exec srb tc --no-config --stop-after desugarer --print parse-tree-whitequark #{path}") do |i, o, e, t|
          # TODO handle errors
          # sexp = o.read
          # puts sexp
          parser = Sexpistol.new
          array = parser.parse_string(o.read)
          # puts array
          AST::Node.new(array.first, array.last)
          # nil
        end
      end

      private

    end
  end
end
