# typed: strict
# frozen_string_literal: true

module RSAF
  module Phases
    class BuildScopes
      extend T::Sig

      sig { params(model: Model, file: T.nilable(String), node: T.nilable(AST::Node)).void }
      def self.run(model, file, node)
        phase = BuildScopes.new(model, file)
        phase.visit(node)
      end

      sig { params(model: Model, file: T.nilable(String)).void }
      def initialize(model, file)
        @model = model
        @file = file
        @stack = T.let([make_root_def], T::Array[Model::ScopeDef])
        @last_sig = T.let(nil, T.nilable(Model::Sig))
      end

      sig { params(node: T.nilable(Object)).void }
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

      sig { params(nodes: T::Array[AST::Node]).void }
      def visit_all(nodes)
        nodes.each { |node| visit(node) }
      end

      private

      sig { returns(Model::ModuleDef) }
      def make_root_def
        Model::ModuleDef.new(Location.new(@file, Position.new(0, 0)), @model.root)
      end

      # Scopes

      sig { params(node: AST::Node).void }
      def visit_module(node)
        last = T.must(@stack.last)
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
        visit_all(node.children)
        @stack.pop
        @last_sig = nil
      end

      sig { params(node: AST::Node).void }
      def visit_class(node)
        last = T.must(@stack.last)
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
        visit_all(node.children)
        @stack.pop
        @last_sig = nil
      end

      # Properties

      sig { params(node: AST::Node).void }
      def visit_attr(node)
        last = T.must(@stack.last)
        kind = node.children[1]

        unless last.scope.is_a?(Model::Class)
          # TODO: print error
          puts "error: adding attributes to module #{last.scope}"
          return
        end

        node.children[2..-1].each do |child|
          name = child.children.first.to_s
          qname = Model::Attr.qualify_name(last.scope, name)

          prop = @model.properties[qname]
          unless prop
            prop = Model::Attr.new(T.cast(last.scope, Model::Class), name, qname, kind)
          end
          loc = Location.from_node(@file, node)
          Model::AttrDef.new(loc, T.cast(last, Model::ClassDef), prop, kind, @last_sig)
          @last_sig = nil
        end
      end

      sig { params(node: AST::Node).void }
      def visit_const_assign(node)
        last = T.must(@stack.last)
        name = node.children[1].to_s
        qname = Model::Const.qualify_name(last.scope, name)

        prop = @model.properties[qname]
        unless prop
          prop = Model::Const.new(last.scope, name, qname)
        end

        loc = Location.from_node(@file, node)
        Model::ConstDef.new(loc, last, prop)
        @last_sig = nil
      end

      sig { params(node: AST::Node).void }
      def visit_def(node)
        last = T.must(@stack.last)
        name = node.children.first
        qname = Model::Method.qualify_name(last.scope, name.to_s, false)

        prop = @model.properties[qname]
        unless prop
          prop = Model::Method.new(last.scope, name.to_s, qname, false)
        end

        loc = Location.from_node(@file, node)
        params = node.children[1].children.map { |n| Model::Param.new(n.children.first.to_s) } if node.children[1]
        Model::MethodDef.new(loc, last, prop, false, params, @last_sig)
        @last_sig = nil
      end

      sig { params(node: AST::Node).void }
      def visit_defs(node)
        last = T.must(@stack.last)
        name = node.children[1]
        qname = Model::Method.qualify_name(last.scope, name.to_s, true)

        prop = @model.properties[qname]
        unless prop
          prop = Model::Method.new(last.scope, name.to_s, qname, true)
        end

        loc = Location.from_node(@file, node)
        params = node.children[2].children.map { |n| Model::Param.new(n.children.first.to_s) } if node.children[2]
        Model::MethodDef.new(loc, last, prop, true, params, @last_sig)
        @last_sig = nil
      end

      sig { params(node: AST::Node).void }
      def visit_send(node)
        case node.children[1]
        when :attr_reader, :attr_writer, :attr_accessor
          visit_attr(node)
        when :include, :prepend, :extend
          visit_include(node)
        when :sig
          visit_sig(node)
        end
      end

      sig { params(node: AST::Node).void }
      def visit_include(node)
        last = T.must(@stack.last)
        name = visit_name(node.children[2])
        kind = node.children[1]
        Model::IncludeDef.new(last, name, kind)
      end

      sig { params(node: AST::Node).void }
      def visit_sig(node)
        if @last_sig
          # TODO: print error
          puts "error: already in a sig"
        end
        @last_sig = Model::Sig.new
      end

      # Utils

      sig { params(node: AST::Node).returns(String) }
      def visit_name(node)
        v = ScopeNameVisitor.new
        v.visit(node)
        v.names.join("::")
      end

      sig { returns(String) }
      def current_namespace
        T.must(@stack.last).qname
      end
    end

    class ScopeNameVisitor
      extend T::Sig

      sig { returns(T::Array[String]) }
      attr_accessor :names

      sig { void }
      def initialize
        @names = T.let([], T::Array[String])
      end

      sig { params(node: T.nilable(Object)).void }
      def visit(node)
        return unless node.is_a?(::Parser::AST::Node)
        node.children.each { |child| visit(child) }
        names << node.location.name.source if node.type == :const
      end
    end
  end

  class Location
    extend T::Sig

    sig { params(file: T.nilable(String), node: AST::Node).returns(Location) }
    def self.from_node(file, node)
      loc = node.location
      Location.new(file, Range.new(Position.new(loc.line, loc.column), Position.new(loc.last_line, loc.last_column)))
    end
  end
end
