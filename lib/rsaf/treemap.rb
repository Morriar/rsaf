# typed: true
# frozen_string_literal: true

module RSAF
  class Model
    class Treemap
      extend T::Sig

      sig { returns(T::Array[Row]) }
      attr_reader :rows

      def initialize
        @rows = T.let([], T::Array[Row])
      end

      sig { params(model: Model).void }
      def print_model(model)
        visit(model.root)

        data = [
          ["Name", "Parent", "Size", "Value"],
          *@rows
        ]
        json = data.to_json
        puts json
        File.write("data.js", "var raw_data = #{json}")
      end

      sig { params(object: MObject).void }
      def visit(object)
        object.accept_treemap(self)
      end

      sig { params(array: T::Array[MObject]).void }
      def visit_all(array)
        array.each { |object| visit(object) }
      end

      class Row < T::Struct
        const :qname, String
        const :parent, T.nilable(String)
        const :size, Integer
        const :value, Integer

        def to_json(*args)
          [qname, parent, size, value].to_json(*T.unsafe(args))
        end
      end
    end

    class MObject
      extend T::Sig

      sig { params(v: Model::Treemap).void }
      def accept_treemap(v); end
    end

    class Scope
      extend T::Sig

      sig { override.params(v: Model::Treemap).void }
      def accept_treemap(v)
        defs = count_defs
        sigs = count_sigs
        color = defs > 0 ? sigs * 100 / defs : 100
        v.rows << Treemap::Row.new(qname: qname, parent: parent&.qname, size: defs, value: color)
        v.visit_all(children)
      end

      def count_defs
        methods.length + children.sum(&:count_defs)
      end

      def count_sigs
        methods.count { |m| m.defs.any?(&:sorbet_sig) } + children.sum(&:count_sigs)
      end
    end

    class Class
      extend T::Sig

      def count_defs
        methods.length + attrs.length + children.sum(&:count_defs)
      end

      def count_sigs
        methods.count { |m| m.defs.any?(&:sorbet_sig) } +
          attrs.count { |m| m.defs.any?(&:sorbet_sig) } +
          children.sum(&:count_sigs)
      end
    end
  end
end
