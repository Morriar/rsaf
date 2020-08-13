# typed: strict
# frozen_string_literal: true

require 'ruby-graphviz'

module RSAF
  module UML
    extend T::Sig

    sig { params(model: Model, out: String).void }
    def self.draw(model, out)
      uml = Generator.new(model, out)
      uml.draw
    end

    class Generator
      extend T::Sig

      sig { params(model: Model, out: String).void }
      def initialize(model, out)
        @model = model
        @out = out
        @g = T.let(GraphViz.new(:uml, type: :digraph, fontname: :arial, splines: :ortho), GraphViz)
        # TODO: options
        # TODO draw from point
        # TODO add command
      end

      sig { void }
      def draw
        draw_scope(@g, @model.root)
        draw_edges
        @g.output(png: @out)
      end

      sig { params(graph: GraphViz, scope: Model::Scope).void }
      def draw_scope(graph, scope)
        if scope.children.empty?
          label = draw_scope_content(scope)
          graph.add_node(scope.qname, label: label, shape: :record, fontname: :arial)
          return
        end
        graph = graph.add_graph("cluster_#{scope.qname}", label: scope.name)
        # label = draw_scope_content(scope)
        # graph.add_node(scope.qname, label: label, shape: :record, fontname: :arial)
        scope.children.each do |child|
          draw_scope(graph, child)
        end
      end

      sig { params(scope: Model::Scope).void }
      def draw_scope_content(scope)
        str = StringIO.new
        str << "{"
        str << scope.name
        unless scope.consts.empty?
          str << "|"
          str << scope.consts.map(&:name).join("\n")
        end
        if scope.is_a?(Model::Class) && !scope.attrs.empty?
          str << "|"
          str << scope.attrs.map(&:name).join("\n")
        end
        unless scope.methods.empty?
          str << "|"
          str << scope.methods.map(&:name).join("\n")
        end
        str << "}"
        str.string
      end

      sig { void }
      def draw_edges
        @model.scopes.values.each do |scope|
          scope.includes.each do |inc|
            @g.add_edge(inc.mod.qname, scope.qname, dir: :back, arrowtail: :empty, arrowhead: :vee, arrowsize: 1.5)
          end
        end
        @model.classes.each do |scope|
          next unless scope.superclass
          @g.add_edge(scope.superclass&.qname, scope.qname, dir: :back, arrowtail: :empty, arrowsize: 1.5)
        end
      end
    end
  end

  class Model
    class Scope
      extend T::Sig

      sig { params(v: UML::Generator).void }
      def accept_uml(v)
      end
    end

    class Module
      extend T::Sig

      sig { params(v: UML::Generator).void }
      def accept_uml(v)
      end
    end

    class Class
     extend T::Sig

     sig { params(v: UML::Generator).void }
     def accept_uml(v)
     end
    end

    class Property
      extend T::Sig

      sig { params(v: UML::Generator).void }
      def accept_uml(v)
      end
    end

    class Attr
      extend T::Sig

      sig { params(v: UML::Generator).void }
      def accept_uml(v)
      end
    end

    class Const
      extend T::Sig

      sig { params(v: UML::Generator).void }
      def accept_uml(v)
      end
    end

    class Method
      extend T::Sig

      sig { params(v: UML::Generator).void }
      def accept_uml(v)
      end
    end

    class Include
      extend T::Sig

      sig { params(v: UML::Generator).void }
      def accept_uml(v)
      end
    end

    # Defs

    class ScopeDef
      extend T::Sig

      sig { params(v: UML::Generator).void }
      def accept_uml(v)
      end
    end

    class PropertyDef
      extend T::Sig

      sig { params(v: UML::Generator).void }
      def accept_uml(v)
      end
    end

    class MethodDef
      extend T::Sig

      sig { params(v: UML::Generator).void }
      def accept_uml(v)
      end
    end
  end
end
