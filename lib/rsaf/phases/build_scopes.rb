module RSAF
  module Phases
    class BuildScopes
      def initialize(model)
        @model = model
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
        root_def = Model::ModuleDef.new(@model.root)
        @model.add_module_def(root_def)
        root_def
      end

      def visit_module(node)
        name = visit_name(node.children.first)

        mod = @model.modules["#{@stack.last.qname}::#{name}"]
        unless mod
          mod = Model::Module.new(@stack.last.scope, name)
          @model.add_module(mod)
        end

        mod_def = Model::ModuleDef.new(mod)
        @model.add_module_def mod_def

        @stack << mod_def
        visit_all node.children
        @stack.pop
      end

      def visit_class(node)
        name = visit_name(node.children.first)

        klass = @model.classes["#{@stack.last.qname}::#{name}"]
        unless klass
          klass = Model::Class.new(@stack.last.scope, name)
          @model.add_class(klass)
        end

        superclass = visit_name(node.children[1]) if node.children[1]
        class_def = Model::ClassDef.new(klass, superclass)
        @model.add_class_def class_def

        @stack << class_def
        visit_all node.children
        @stack.pop
      end

      def visit_def(node)
        name = node.children.first

        prop = @model.classes["#{@stack.last.qname}##{name}"]
        unless prop
          prop = Model::Method.new(@stack.last.scope, name, [])
        end

        # TODO better parse params
        params = node.children[1].children.map { |n| Model::Param.new(n.children.first) } if node.children[1]
        Model::MethodDef.new(@stack.last, prop, false, params)
      end

      def visit_defs(node)
        name = node.children[1]

        prop = @model.classes["#{@stack.last.qname}::#{name}"]
        unless prop
          prop = Model::Method.new(@stack.last.scope, name, [])
        end

        # TODO better parse params
        params = node.children[2].children.map { |n| Model::Param.new(n.children.first) } if node.children[2]
        Model::MethodDef.new(@stack.last, prop, true, params)
      end

      def visit_const_assign(node)
        name = node.children[1]

        prop = @model.classes["#{@stack.last.qname}##{name}"]
        unless prop
          prop = Model::Const.new(@stack.last.scope, name)
        end

        Model::ConstDef.new(@stack.last, prop)
      end

      def visit_send(node)
        case node.children[1]
        when :attr_reader, :attr_writer, :attr_accessor
          visit_attr(node)
        when :include, :prepend,  :extend
          visit_include(node)
        end
      end

      def visit_attr(node)
        kind = node.children[1]

        node.children[2..-1].each do |child|
          name = child.children.first

          prop = @model.classes["#{@stack.last.qname}##{name}"]
          unless prop
            prop = Model::Attr.new(@stack.last.scope, name, kind)
          end
          Model::AttrDef.new(@stack.last, prop, kind)
        end
      end

      def visit_include(node)
        name = visit_name(node.children[2])
        kind = node.children[1]
        Model::Include.new(@stack.last, name, kind)
      end

      # Utils

      def visit_name(node)
        v = ScopeNameVisitor.new
        v.visit(node)
        v.names.join("::")
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
end
