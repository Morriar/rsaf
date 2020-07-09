module RSAF
  module Modelize
    class ScopeDefs
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
        args = []
        # TODO Parse def args
        # node.children[1].children.each do |n|
          # args << RSAF::Model::RArg.new(n, n.children.first)
        # end

        name = node.children.first
        @stack.last.method_defs << Model::MethodDef.new(@stack.last, name, args)
      end

      def visit_defs(node)
        puts node

        # Parse recv
        recv_node = node.children.first
        recv = nil
        if not recv_node.nil?
          # We have a receiver.
          #
          # This means the const is defined on some other namespace like:
          #   ::A::B::C = 10
          # Here, `::A::B` is the receiver and `C` the constant to be defined.
          recv = visit_name(recv_node)
        end

        # Parse def args
        args = []
        # node.children[2].children.each do |n|
          # args << RSAF::Model::RArg.new(n, n.children.first)
        # end

        name = node.children[1]
        @stack.last.singleton_method_defs << Model::SingletonMethodDef.new(@stack.last, name, args, recv)
      end

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
