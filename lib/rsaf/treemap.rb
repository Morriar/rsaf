# typed: true
# frozen_string_literal: true

module RSAF
  class Treemap
    extend T::Sig

    class Generator

      attr_reader :root

      def initialize
        @root  = {
          name: "root",
          value: 1,
          size: 1,
          children: []
        }
        @current_node = [@root]
      end

      def visit_tree(tree)
          visit_node(tree.root)
          # @object[:children] << @current_node.last
      end

      def visit_node(node)
        # puts node.name
        subnode = { name: node.name, value: node_value(node), size: node_size(node), children: [] }
        @current_node.last[:children] << subnode
        @current_node << subnode
        node.children.values.each do |child|
          # puts child
          visit_node(child)
        end
        @current_node.pop
      end

      def node_size(node)
        node.count_files
      end

      def node_value(node)
        files = node.count_files
        return 100 if files == 0
        node.count_typed * 100 / files
      end
    end
  end

  class Model
    extend T::Sig

    # sig { returns(Treemap) }
    def sigs_treemap
      v = Treemap::Generator.new
      v.visit_tree(self.source_tree)
      puts v.root.to_json
    end
  end
end
