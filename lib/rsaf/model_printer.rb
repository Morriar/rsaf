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

    class Scope
      def accept_printer(v)
        if v.print_defs
          v.indent
          v.visit_all(defs)
          v.dedent
        end
        v.indent
        v.visit_all(includes)
        v.dedent
        if v.print_properties
          v.indent
          print_properties(v)
          v.dedent
        end
        unless children.empty?
          v.indent
          v.visit_all(children)
          v.dedent
        end
        # TODO visit nesting
      end

      def print_properties(v)
        v.visit_all(consts)
        v.visit_all(methods)
      end
    end

    class Module
      def accept_printer(v)
        v.printl "module #{qname}"
        super(v)
      end
    end

    class Class
      def accept_printer(v)
        v.printt "class #{qname}"
        v.print " < #{superclass}" if superclass
        v.printn
        super(v)
      end

      def print_properties(v)
        v.visit_all(consts)
        v.visit_all(attrs)
        v.visit_all(methods)
      end
    end

    class Property
      def accept_printer(v)
        if v.print_defs
          v.indent
          v.visit_all(defs)
          v.dedent
        end
      end
    end

    class Attr
      def accept_printer(v)
        v.printl "#{kind} #{name}"
        super(v)
      end
    end

    class Const
      def accept_printer(v)
        v.printl name
        super(v)
      end
    end

    class Method
      def accept_printer(v)
        v.printl "def #{is_singleton ? "self." : ""}#{name}"
        super(v)
      end
    end

    class Include
      def accept_printer(v)
        v.printl "#{kind} #{mod.qname}"
      end
    end

    # Defs

    class ScopeDef
      def accept_printer(v)
        v.printl v.colorize("defined at #{loc}", :light_black)
      end
    end

    class PropertyDef
      def accept_printer(v)
        v.printl v.colorize("defined at #{loc}", :light_black)
      end
    end

    class MethodDef
      def accept_printer(v)
        super(v)
        v.indent
        v.printt v.colorize("signature: #{name}", :light_black)
        v.print v.colorize("(#{params.map(&:name).join(", ")})", :light_black) unless params.empty?
        v.printn
        v.dedent
      end
    end
  end
end
