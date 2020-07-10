module RSAF
  class Model
    class ModelPrinter
      attr_reader :print_defs, :print_properties

      def initialize(default_indent: 0, colors: true, out: $stdout, print_defs: true, print_properties: true)
        @current_indent = default_indent
        @out = out
        @colors = colors
        @print_defs = print_defs
        @print_properties = print_properties
        # TODO location
      end

      def print_model(model)
        visit(model.root)
      end

      def print_object(object)
        visit(object)
      end

      # Internals (but not private)

      def colorize(string, color)
        return string unless @colors
        string.colorize(color)
      end

      def indent
        @current_indent += 2
      end

      def dedent
        @current_indent -= 2
      end

      def print(string)
        @out.print string
      end

      def printn(string = nil)
        print string
        print "\n"
      end

      def printt(string = nil)
        print " " * @current_indent
        print string
      end

      def printl(string)
        printt
        printn string
      end

      def visit(object)
        object.accept_printer(self)
      end

      def visit_all(array)
        array.each { |object| visit(object) }
      end
    end

    class Module
      def accept_printer(v)
        v.printl "module #{qname}"
        if v.print_defs
          v.indent
          v.visit_all(defs)
          v.dedent
        end
        if v.print_properties
          v.indent
          v.visit_all(consts)
          v.visit_all(methods)
          v.dedent
        end
        unless children.empty?
          v.indent
          v.visit_all(children)
          v.dedent
        end
        # TODO visit nesting
      end
    end

    class Class
      def accept_printer(v)
        v.printt "class #{qname}"
        # TODO v.print " < #{superclass_name}" if superclass_name
        v.printn
        if v.print_defs
          v.indent
          v.visit_all(defs)
          v.dedent
        end
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

    class Attr
      def accept_printer(v)
        v.printl "#{kind} #{name}"
        if v.print_defs
          v.indent
          v.visit_all(defs)
          v.dedent
        end
      end
    end

    class Const
      def accept_printer(v)
        v.printl name
        if v.print_defs
          v.indent
          v.visit_all(defs)
          v.dedent
        end
      end
    end

    class Method
      def accept_printer(v)
        v.printl "def #{is_singleton ? "self." : ""}#{name}"
        if v.print_defs
          v.indent
          v.visit_all(defs)
          v.dedent
        end
      end
    end

    # Defs

    class ModuleDef
      def accept_printer(v)
        v.printl v.colorize("defined at #{loc}", :light_black)
      end
    end

    class ClassDef
      def accept_printer(v)
        v.printl v.colorize("defined at #{loc}", :light_black)
      end
    end

    class AttrDef
      def accept_printer(v)
        v.printl v.colorize("defined at #{loc}", :light_black)
      end
    end

    class ConstDef
      def accept_printer(v)
        v.printl v.colorize("defined at #{loc}", :light_black)
      end
    end

    class MethodDef
      def accept_printer(v)
        v.printl v.colorize("defined at #{loc}", :light_black)
        v.indent
        v.printt v.colorize("signature: #{name}", :light_black)
        v.print v.colorize("(#{params.map(&:name).join(", ")})", :light_black) unless params.empty?
        v.printn
        v.dedent
      end
    end
  end
end
