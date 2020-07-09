module RSAF
  module Modelize
    class BuildScopeDefs
      def initialize(model)
        @model = model
        root = Model::ModuleDef.new(nil, "<root>", "<root>")
        model.add_module_def(root)
        @stack = [ root ]
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

      def visit_module(node)
        name = visit_name(node.children.first)
        qname = [@stack.last.qname.sub("<root>", ""), name].join("::")

        mod = Model::ModuleDef.new(@stack.last, name, qname)
        @model.add_module_def mod

        @stack << mod
        visit_all node.children
        @stack.pop
      end

      def visit_class(node)
        name = visit_name(node.children.first)
        qname = [@stack.last.qname.sub("<root>", ""), name].join("::")

        superclass = visit_name(node.children[1]) if node.children[1]

        klass = Model::ClassDef.new(@stack.last, name, qname, superclass)
        @model.add_class_def klass

        @stack << klass
        visit_all node.children
        @stack.pop
      end

      def visit_def(node)
        name = node.children.first
        # TODO better parse params
        params = node.children[1].children.map { |n| Model::Param.new(n.children.first) } if node.children[1]
        @stack.last.method_defs << Model::MethodDef.new(@stack.last, name, params)
      end

      def visit_defs(node)
        recv = nil
        recv_node = node.children.first
        if not recv_node.nil?
          # We have a receiver.
          #
          # This means the const is defined on some other namespace like:
          #   ::A::B::C = 10
          # Here, `::A::B` is the receiver and `C` the constant to be defined.
          recv = visit_name(recv_node)
        end
        name = node.children[1]
        # TODO better parse params
        params = node.children[2].children.map { |n| Model::Param.new(n.children.first) } if node.children[2]
        @stack.last.singleton_method_defs << Model::SingletonMethodDef.new(@stack.last, name, params, recv)
      end

      def visit_const_assign(node)
        name = node.children[1]
        @stack.last.const_defs << Model::ConstDef.new(@stack.last, name)
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
          @stack.last.attrs << Model::AttrDef.new(@stack.last, name, kind)
        end
      end

      def visit_include(node)
        name = visit_name(node.children[2])
        kind = node.children[1]
        @stack.last.includes << Model::Include.new(name, kind)
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
