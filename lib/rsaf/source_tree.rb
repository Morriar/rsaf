# typed: strict
# frozen_string_literal: true

module RSAF
  class SourceTree
    extend T::Sig

    sig { returns(Node) }
    attr_reader :root

    sig { params(file: SourceFile).void }
    def initialize(*file)
      @root = T.let(Node.new(parent: nil, name: ".", source: nil), Node)
      add_files(file)
    end

    sig { params(files: T::Array[SourceFile]).void }
    def add_files(files)
      files.each { |file| add_file(file) }
    end

    sig { params(file: SourceFile).void }
    def add_file(file)
      path = file.path
      return unless path

      parts = path.split("/")
      name = T.must(parts.first)
      node = @root.children[name] ||= Node.new(parent: @root, name: name, source: file)
      (1...parts.length).each do |i|
        sname = T.must(parts[i])
        node = node.children[sname] ||= Node.new(parent: node, name: sname, source: file)
      end
    end

    sig { params(colors: T::Boolean, indent: Integer, out: T.any(IO, StringIO)).void }
    def show(colors = true, indent = 0, out = $stdout)
      v = PrintVisitor.new(colors, indent, out)
      v.visit_tree(self)
    end

    class Node < T::Struct
      extend T::Sig

      const :parent, T.nilable(Node)
      const :name, String
      const :source, T.nilable(SourceFile)
      const :children, T::Hash[String, Node], default: {}

      sig { returns(T::Boolean) }
      def root?
        parent.nil?
      end

      sig { returns(T::Boolean) }
      def children?
        !children.empty?
      end

      sig { returns(String) }
      def path
        parent = self.parent
        return name unless parent
        return name if parent.root?
        "#{parent.path}/#{name}"
      end

      sig { params(v: PrintVisitor).void }
      def accept_visitor(v)
        unless root?
          if children?
            v.printl("#{v.dir_color(path)}/")
          else
            strictness = source&.strictness || "none"
            v.printl("#{path} (#{v.strictness_color(strictness)})")
          end
        end
        v.indent unless root?
        v.visit_nodes(@children.values.sort_by(&:name))
        v.dedent unless root?
      end
    end

    class PrintVisitor
      extend T::Sig

      STRICTNESS_COLORS = T.let({
        "ignore" => :grey,
        "false" => :red,
        "true" => :green,
        "strict" => :green,
        "strong" => :green,
        "__STDLIB_INTERNAL" => :green,
      }, T::Hash[String, Symbol])

      sig { params(colors: T::Boolean, indent: Integer, out: T.any(IO, StringIO)).void }
      def initialize(colors = true, indent = 0, out = $stderr)
        @colors = colors
        @current_indent = indent
        @out = out
      end

      sig { params(tree: SourceTree).void }
      def visit_tree(tree)
        visit_node(tree.root)
      end

      sig { params(node: Node).void }
      def visit_node(node)
        node.accept_visitor(self)
      end

      sig { params(nodes: T::Array[Node]).void }
      def visit_nodes(nodes)
        nodes.each { |n| visit_node(n) }
      end

      sig { params(str: String).void }
      def printl(str)
        @out.print(' ' * @current_indent)
        @out.print(str)
        @out.print("\n")
      end

      sig { void }
      def indent
        @current_indent += 2
      end

      sig { void }
      def dedent
        @current_indent -= 2
      end

      sig { params(strictness: String).returns(String) }
      def strictness_color(strictness)
        return strictness unless @colors
        color = STRICTNESS_COLORS.fetch(strictness, :uncolored)
        strictness.colorize(color)
      end

      sig { params(str: String).returns(String) }
      def dir_color(str)
        return str unless @colors
        str.colorize(:blue)
      end
    end
  end

  class Model
    extend T::Sig

    sig { returns(SourceTree) }
    def source_tree
      SourceTree.new(*T.unsafe(files))
    end
  end
end
