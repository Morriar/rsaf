module RSAF
  module Phases
    class BuildScopes
      def self.run(model, file, node)
        phase = BuildScopes.new(model, file)
        phase.visit(node)
      end

      def initialize(model, file)
        @model = model
        @file = file
        @stack = [ make_root_def ]
      end

      def visit(node)
        return unless node.is_a?(::Parser::AST::Node)

        case node.type
        when :module
          visit_module(node)
        when :class
          visit_class(node)
        when :def
          visit_def(node)
        when :defs
          visit_defs(node)
        when :casgn
          visit_const_assign(node)
        when :send
          visit_send(node)
        else
          visit_all(node.children)
        end
      end

      def visit_all(nodes)
        nodes.each { |node| visit(node) }
      end

      private

      def make_root_def
        Model::ModuleDef.new(Location.new(@file, Position.new(0, 0)), @model.root)
      end

      # Scopes

      def visit_module(node)
        last = @stack.last
        name = visit_name(node.children.first)
        qname = Model::Scope.qualify_name(last.scope, name)

        mod = @model.scopes[qname]
        unless mod
          mod = Model::Module.new(last.scope, name, qname)
          @model.add_module(mod)
        end

        loc = Location.from_node(@file, node)
        mod_def = Model::ModuleDef.new(loc, mod)

        @stack << mod_def
        visit_all node.children
        @stack.pop
      end

      def visit_class(node)
        last = @stack.last
        name = visit_name(node.children.first)
        qname = Model::Scope.qualify_name(last.scope, name)

        klass = @model.scopes[qname]
        unless klass
          klass = Model::Class.new(last.scope, name, qname)
          @model.add_class(klass)
        end

        loc = Location.from_node(@file, node)
        superclass = visit_name(node.children[1]) if node.children[1]
        class_def = Model::ClassDef.new(loc, klass, superclass)

        @stack << class_def
        visit_all node.children
        @stack.pop
      end

      # Properties

      def visit_attr(node)
        last = @stack.last
        kind = node.children[1]

        node.children[2..-1].each do |child|
          name = child.children.first.to_s
          qname = Model::Attr.qualify_name(last.scope, name)

          prop = @model.properties[qname]
          unless prop
            prop = Model::Attr.new(last.scope, name, qname, kind)
          end
          loc = Location.from_node(@file, node)
          Model::AttrDef.new(loc, last, prop, kind)
        end
      end

      def visit_const_assign(node)
        last = @stack.last
        name = node.children[1].to_s
        qname = Model::Const.qualify_name(last.scope, name)

        prop = @model.properties[qname]
        unless prop
          prop = Model::Const.new(last.scope, name, qname)
        end

        loc = Location.from_node(@file, node)
        Model::ConstDef.new(loc, last, prop)
      end

      def visit_def(node)
        last = @stack.last
        name = node.children.first
        qname = Model::Method.qualify_name(last.scope, name, false)

        prop = @model.properties[qname]
        unless prop
          prop = Model::Method.new(last.scope, name, qname, false)
        end

        loc = Location.from_node(@file, node)
        params = node.children[1].children.map { |n| Model::Param.new(n.children.first) } if node.children[1]
        Model::MethodDef.new(loc, last, prop, false, params)
      end

      def visit_defs(node)
        last = @stack.last
        name = node.children[1]
        qname = Model::Method.qualify_name(last.scope, name, true)

        prop = @model.properties[qname]
        unless prop
          prop = Model::Method.new(last.scope, name, qname, true)
        end

        loc = Location.from_node(@file, node)
        params = node.children[2].children.map { |n| Model::Param.new(n.children.first) } if node.children[2]
        Model::MethodDef.new(loc, last, prop, true, params)
      end

      def visit_send(node)
        case node.children[1]
        when :attr_reader, :attr_writer, :attr_accessor
          visit_attr(node)
        when :include, :prepend,  :extend
          visit_include(node)
        end
      end

      def visit_include(node)
        name = visit_name(node.children[2])
        kind = node.children[1]
        Model::IncludeDef.new(@stack.last, name, kind)
      end

      # Utils

      def visit_name(node)
        v = ScopeNameVisitor.new
        v.visit(node)
        v.names.join("::")
      end

      def current_namespace
        @stack.last.qname
      end
    end

    class ScopeNameVisitor
      attr_accessor :names

      def initialize
        @names = []
      end

      def visit(node)
        return unless node.is_a?(::Parser::AST::Node)
        node.children.each { |child| visit(child) }
        names << node.location.name.source if node.type == :const
      end
    end
  end

  class Location
    def self.from_node(file, node)
      loc = node.location
      Location.new(file, Range.new(Position.new(loc.line, loc.column), Position.new(loc.last_line, loc.last_column)))
    end
  end
end
