# typed: true

module RSAF
  class SourceTree

    def initialize(sources)
      @roots = {}
      sources.each { |p| add_source(p) }
    end

    def add_source(source)
      path = source.path
      parts = path.split("/")
      name = parts.first
      node = @roots[name] ||= Node.new(name)
      (1...parts.length).each do |i|
        name = parts[i]
        node = node.children[name] ||= Node.new(name)
      end
      node.source = source
    end

    def print_tree(out = $stdout)
      v = Visitor.new(out)
      v.visit_all(@roots.values)
    end

    class Node
      attr_reader :name
      attr_accessor :source
      attr_reader :children

      def initialize(name)
        @name = name
        @children = {}
      end

      def accept(v)
        v.printt
        v.print(name)
        if source
          strictness = source.strictness
          v.print(" (typed: #{strictness})") if strictness
        end
        v.printn
        v.indent
        v.visit_all(@children.values)
        v.dedent
      end
    end

    class Visitor
      def initialize(out = $stderr)
        @out = out
        @current_indent = 0
      end

      def visit(node)
        node.accept(self)
      end

      def visit_all(nodes)
        nodes.each { |n| visit(n) }
      end

      def printt
        @out.print(' ' * @current_indent)
      end

      def print(str)
        @out.print(str)
      end

      def printn
        @out.print("\n")
      end

      def indent
        @current_indent += 2
      end

      def dedent
        @current_indent -= 2
      end
    end
  end
end
