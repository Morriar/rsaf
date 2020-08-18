# typed: strict
# frozen_string_literal: true

module RSAF
  class Model
    class ModelPrinter
      extend T::Sig

      sig { returns(T::Boolean) }
      attr_reader :print_defs, :print_properties

      sig do
        params(
          default_indent: Integer,
          colors: T::Boolean,
          out: T.any(IO, StringIO),
          print_defs: T::Boolean,
          print_properties: T::Boolean
        ).void
      end
      def initialize(default_indent: 0, colors: true, out: $stdout, print_defs: true, print_properties: true)
        @current_indent = default_indent
        @out = out
        @colors = colors
        @print_defs = print_defs
        @print_properties = print_properties
      end

      sig { params(model: Model).void }
      def print_model(model)
        visit(model.root)
      end

      sig { params(object: Model::MObject).void }
      def print_object(object)
        visit(object)
      end

      # Internals (but not private)

      sig { params(string: String, color: Symbol).returns(String) }
      def colorize(string, color)
        return string unless @colors
        string.colorize(color)
      end

      sig { void }
      def indent
        @current_indent += 2
      end

      sig { void }
      def dedent
        @current_indent -= 2
      end

      sig { params(string: String).void }
      def print(string)
        @out.print(string)
      end

      sig { params(string: T.nilable(String)).void }
      def printn(string = nil)
        print(string) if string
        print("\n")
      end

      sig { params(string: T.nilable(String)).void }
      def printt(string = nil)
        print(" " * @current_indent)
        print(string) if string
      end

      sig { params(string: String).void }
      def printl(string)
        printt
        printn(string)
      end

      sig { params(object: MObject).void }
      def visit(object)
        object.accept_printer(self)
      end

      sig { params(array: T::Array[MObject]).void }
      def visit_all(array)
        array.each { |object| visit(object) }
      end
    end

    class MObject
      extend T::Sig

      sig { abstract.params(v: Model::ModelPrinter).void }
      def accept_printer(v); end
    end

    class Scope
      extend T::Sig

      sig { override.params(v: Model::ModelPrinter).void }
      def accept_printer(v)
        if v.print_defs
          v.indent
          defs.each do |d|
            v.printl(v.colorize("defined at #{d.loc}", :light_black))
          end
          v.dedent
        end
        v.indent
        v.visit_all(includes)
        v.dedent
        if v.print_properties
          v.indent
          v.visit_all(consts)
          v.visit_all(attrs)
          v.visit_all(methods)
          v.dedent
        end
        unless children.empty?
          v.indent
          v.visit_all(children)
          v.dedent
        end
        # TODO: visit nesting
      end
    end

    class Module
      extend T::Sig

      sig { override.params(v: Model::ModelPrinter).void }
      def accept_printer(v)
        v.printl("module #{qname}")
        super(v)
      end
    end

    class Class
      extend T::Sig

      sig { override.params(v: Model::ModelPrinter).void }
      def accept_printer(v)
        v.printt("class #{qname}")
        v.print(" < #{superclass}") if superclass
        v.printn
        super(v)
      end
    end

    class Property
      extend T::Sig

      sig { override.params(v: Model::ModelPrinter).void }
      def accept_printer(v)
        return unless v.print_defs
        v.indent
        defs.each do |d|
          v.printl(v.colorize("defined at #{d.loc}", :light_black))
          if d.is_a?(MethodDef)
            v.indent
            v.printt(v.colorize("signature: #{d.name}", :light_black))
            v.print(v.colorize("(#{d.params.map(&:name).join(', ')})", :light_black)) unless d.params.empty?
            v.printn
            if d.sorbet_sig
              v.printt(v.colorize("sig: #{true}", :light_black))
              v.printn
            end
            v.dedent
          end
        end
        v.dedent
      end
    end

    class Attr
      extend T::Sig

      sig { override.params(v: Model::ModelPrinter).void }
      def accept_printer(v)
        v.printl("#{kind} #{name}")
        super(v)
      end
    end

    class Const
      extend T::Sig

      sig { override.params(v: Model::ModelPrinter).void }
      def accept_printer(v)
        v.printl(name)
        super(v)
      end
    end

    class Method
      extend T::Sig

      sig { override.params(v: Model::ModelPrinter).void }
      def accept_printer(v)
        v.printl("def #{is_singleton ? 'self.' : ''}#{name}")
        super(v)
      end
    end

    class Include
      extend T::Sig

      sig { override.params(v: Model::ModelPrinter).void }
      def accept_printer(v)
        v.printl("#{kind} #{mod.qname}")
      end
    end

    # Defs

    class ScopeDef
      extend T::Sig

      sig { override.params(v: Model::ModelPrinter).void }
      def accept_printer(v)
        return unless v.print_defs
        v.indent
        v.printl(v.colorize("defined at #{loc}", :light_black))
        v.visit_all(includes)
        v.dedent
        if v.print_properties
          v.indent
          v.visit_all(consts)
          v.visit_all(attrs)
          v.visit_all(methods)
          v.dedent
        end
        unless children.empty?
          v.indent
          v.visit_all(children)
          v.dedent
        end
      end
    end

    class ModuleDef
      extend T::Sig

      sig { override.params(v: Model::ModelPrinter).void }
      def accept_printer(v)
        v.printl("module #{qname}")
        super(v)
      end
    end

    class ClassDef
      extend T::Sig

      sig { override.params(v: Model::ModelPrinter).void }
      def accept_printer(v)
        v.printt("class #{qname}")
        v.print(" < #{superclass_name}") if superclass_name
        v.printn
        super(v)
      end
    end

    class PropertyDef
      extend T::Sig

      sig { override.params(v: Model::ModelPrinter).void }
      def accept_printer(v)
        v.indent
        v.printl(v.colorize("defined at #{loc}", :light_black))
        v.dedent
      end
    end

    class AttrDef
      extend T::Sig

      sig { override.params(v: Model::ModelPrinter).void }
      def accept_printer(v)
        v.printl("#{kind} #{name}")
        super(v)
      end
    end

    class ConstDef
      extend T::Sig

      sig { override.params(v: Model::ModelPrinter).void }
      def accept_printer(v)
        v.printl(name)
        super(v)
      end
    end

    class MethodDef
      extend T::Sig

      sig { override.params(v: Model::ModelPrinter).void }
      def accept_printer(v)
        v.printl("def #{is_singleton ? 'self.' : ''}#{name}")
        super(v)
        v.indent
        v.indent
        v.printt(v.colorize("signature: #{name}", :light_black))
        v.print(v.colorize("(#{params.map(&:name).join(', ')})", :light_black)) unless params.empty?
        v.printn
        if sorbet_sig
          v.printt(v.colorize("sig: #{true}", :light_black))
          v.printn
        end
        v.dedent
        v.dedent
      end
    end

    class IncludeDef
      extend T::Sig

      sig { override.params(v: Model::ModelPrinter).void }
      def accept_printer(v); end
    end

    class Param
      extend T::Sig

      sig { override.params(v: Model::ModelPrinter).void }
      def accept_printer(v); end
    end

    class Sig
      extend T::Sig

      sig { override.params(v: Model::ModelPrinter).void }
      def accept_printer(v); end
    end
  end
end
