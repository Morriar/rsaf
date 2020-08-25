# typed: strict
# frozen_string_literal: true

module RSAF
  class Treemap
    extend T::Sig

    HEADER =  T.let(["Name", "Parent", "Size", "Value"], [String, String, String, String])

    sig { returns(T::Array[[String, T.nilable(String), Integer, Integer]]) }
    attr_reader :rows

    sig { void }
    def initialize
      @rows = T.let([], T::Array[[String, T.nilable(String), Integer, Integer]])
    end

    sig { params(id: String, parent_id: T.nilable(String), size: Integer, value: Integer).void }
    def add_row(id, parent_id, size, value)
      @rows << [id, parent_id, size, value]
    end

    sig { params(out: T.any(IO, StringIO)).void }
    def to_google_treemap(out: $stdout)
      data = [
        HEADER,
        *@rows
      ].to_json
      out.puts("var raw_data = #{data}")
    end

    class TreemapBuilder
      extend T::Sig
      extend T::Helpers

      abstract!

      sig { returns(Treemap) }
      attr_reader :tree

      sig { void }
      def initialize
        @tree = T.let(RSAF::Treemap.new, RSAF::Treemap)
      end

      sig { params(model: Model).void }
      def visit_model(model)
        enter_visit(model.source_tree.root)
      end

      sig { params(node: SourceTree::Node).void }
      def enter_visit(node)
        visit(node)
        node.children.values.each { |snode| enter_visit(snode) }
      end

      sig { params(node: SourceTree::Node).void }
      def visit(node)
        tree.add_row(node.path, node.parent&.path, node_size(node), node_value(node))
      end

      sig { abstract.params(node: SourceTree::Node).returns(Integer) }
      def node_size(node); end

      sig { abstract.params(node: SourceTree::Node).returns(Integer) }
      def node_value(node); end
    end

    class TypedTreemapBuilder < TreemapBuilder
      extend T::Sig

      sig { override.params(node: SourceTree::Node).void }
      def visit(node)
        return unless node.children?
        super(node)
      end

      sig { override.params(node: SourceTree::Node).returns(Integer) }
      def node_size(node)
        node.count_files
      end

      sig { override.params(node: SourceTree::Node).returns(Integer) }
      def node_value(node)
        files = node.count_files
        return 100 if files == 0
        node.count_typed * 100 / files
      end
    end

    class SigsTreemapBuilder < TreemapBuilder
      extend T::Sig

      sig { override.params(node: SourceTree::Node).returns(Integer) }
      def node_size(node)
        node.count_scope_defs + node.count_prop_defs
      end

      sig { override.params(node: SourceTree::Node).returns(Integer) }
      def node_value(node)
        defs = node.count_prop_defs
        return 100 if defs == 0
        node.count_sigs * 100 / defs
      end
    end
  end

  class Model
    extend T::Sig

    sig { returns(Treemap) }
    def sigs_treemap
      v = Treemap::TypedTreemapBuilder.new
      v.visit_model(self)
      v.tree
    end
  end
end
