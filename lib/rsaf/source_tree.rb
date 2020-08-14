# typed: true

module RSAF
  class SourceTree

    def initialize(files)
      @roots = {}
      add_paths(files)
    end

    def add_paths(paths)
      paths.each { |p| add_path(p) }
    end

    def add_path(path)
      parts = path.split("/")
      name = parts.first
      node = @roots[name] ||= Node.new(name)
      (1...parts.length).each do |i|
        name = parts[i]
        node = node.children[name] ||= Node.new(name)
      end
    end

    def print_tree(out = $stdout)
      v = Visitor.new(out)
      v.visit_all(@roots.values)
    end

    class Node
      attr_reader :name
      attr_reader :children

      def initialize(name)
        @name = name
        @children = {}
      end

      def accept(v)
        v.printn(name)
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

      def printn(str)
        @out.print("#{' ' * @current_indent}#{str}\n")
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
