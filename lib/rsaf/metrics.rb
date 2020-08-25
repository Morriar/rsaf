# typed: strict
# frozen_string_literal: true

module RSAF
  class SourceTree
    class Node
      extend T::Sig

      sig { returns(Integer) }
      def count_scope_defs
        if children?
          children.values.sum(&:count_scope_defs)
        else
          source = self.source
          return 0 unless source
          source.count_scope_defs
        end
      end

      sig { returns(Integer) }
      def count_prop_defs
        if children?
          children.values.sum(&:count_prop_defs)
        else
          source = self.source
          return 0 unless source
          source.count_prop_defs
        end
      end

      sig { returns(Integer) }
      def count_sigs
        if children?
          children.values.sum(&:count_sigs)
        else
          source = self.source
          return 0 unless source
          source.count_sigs
        end
      end

      sig { returns(Integer) }
      def count_typed
        if children?
          children.values.sum(&:count_typed)
        else
          strictness = source&.strictness
          return 1 if ["true", "strict", "strong"].include?(strictness)
          0
        end
      end

      sig { returns(Integer) }
      def count_files
        if children?
          children.values.sum(&:count_files)
        else
          1
        end
      end
    end
  end

  class SourceFile
    extend T::Sig

    sig { returns(Integer) }
    def count_scope_defs
      root = self.root_def
      return 0 unless root
      root.count_scope_defs
    end

    sig { returns(Integer) }
    def count_prop_defs
      root = self.root_def
      return 0 unless root
      root.count_prop_defs
    end

    sig { returns(Integer) }
    def count_sigs
      root = self.root_def
      return 0 unless root
      root.count_sigs
    end
  end

  class Model
    class Scope
      extend T::Sig

      sig { returns(Integer) }
      def count_scopes
        children.length + children.sum(&:count_scopes)
      end

      sig { returns(Integer) }
      def count_modules
        children.count { |s| s.is_a?(Module) } + children.sum(&:count_modules)
      end

      sig { returns(Integer) }
      def count_classes
        children.count { |s| s.is_a?(Class) } + children.sum(&:count_classes)
      end

      sig { returns(Integer) }
      def count_attrs
        attrs.length + children.sum(&:count_attrs)
      end

      sig { returns(Integer) }
      def count_methods
        methods.length + children.sum(&:count_methods)
      end

      sig { returns(Integer) }
      def count_sigs
        attrs.count { |d| d.defs.any?(&:sorbet_sig) } +
          methods.count { |d| d.defs.any?(&:sorbet_sig) } +
          children.sum(&:count_sigs)
      end

      def show_metrics(out = $stdout)
        out.print("Metrics for #{qname}:\n")
        out.print(" * Modules: #{count_modules}\n")
        out.print(" * Classes: #{count_classes}\n")
        out.print(" * Attributes: #{count_attrs}\n")
        out.print(" * Methods: #{count_methods}\n")
        out.print(" * Signatures: #{count_sigs}\n")
      end
    end

    class ScopeDef
      extend T::Sig

      sig { returns(Integer) }
      def count_scope_defs
        children.length + children.sum(&:count_scope_defs)
      end

      sig { returns(Integer) }
      def count_prop_defs
        attrs.length + methods.length + children.sum(&:count_prop_defs)
      end

      sig { returns(Integer) }
      def count_sigs
        attrs.count(&:sorbet_sig) + methods.count(&:sorbet_sig) + children.sum(&:count_sigs)
      end
    end
  end
end
