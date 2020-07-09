require_relative "../../test_helper"

# TODO use a model printer

module RSAF
  module Tests
    class BuildScopesTest < Minitest::Test
      def test_build_scopes_empty
        model = compile("")
        assert_equal(1, model.entries.size)
        assert_equal("<root>", model.entries.first.name)
      end

      def test_build_scopes_simple
        model = compile(<<~RB)
          module A; end

          class B
          end
        RB

        assert_equal(["::A", "::B", "<root>"], names(model.entries))
        assert_equal(["::A", "<root>"], names(model.module_defs))
        assert_equal(["::B"], names(model.class_defs))
      end

      def test_build_scopes_qualified
        model = compile(<<~RB)
          module A::A
          end

          class B::B; end
        RB

        assert_equal(["::A::A", "::B::B", "<root>"], names(model.entries))
      end

      def test_build_scopes_nested
        model = compile(<<~RB)
          module A
            module B
              class C; end
            end
          end

          class D
            module E; end
          end
        RB

        assert_equal(["::A", "::A::B", "::A::B::C", "::D", "::D::E", "<root>"], names(model.entries))
        assert_equal(["::A", "::A::B", "::D::E", "<root>"], names(model.module_defs))
        assert_equal(["::A::B::C", "::D"], names(model.class_defs))
      end

      def test_build_scopes_mixed
        model = compile(<<~RB)
          module A
            module B::C
              class D; end
            end
          end

          class D::E
            module F::G; end
          end
        RB

        assert_equal(["::A", "::A::B::C", "::A::B::C::D", "::D::E", "::D::E::F::G", "<root>"], names(model.entries))
        assert_equal(["::A", "::A::B::C", "::D::E::F::G", "<root>"], names(model.module_defs))
        assert_equal(["::A::B::C::D", "::D::E"], names(model.class_defs))
      end

      def test_build_scopes_reopened
        model = compile(<<~RB)
          module A
            module B::C
              class D; end
            end
          end

          module A
            module B::C::D::E; end
            class F::G; end
          end
        RB

        assert_equal(["::A", "::A", "::A::B::C", "::A::B::C::D", "::A::B::C::D::E", "::A::F::G", "<root>"], names(model.entries))
        assert_equal(["::A", "::A", "::A::B::C", "::A::B::C::D::E", "<root>"], names(model.module_defs))
        assert_equal(["::A::B::C::D", "::A::F::G"], names(model.class_defs))
      end

      def test_build_scopes_superclass_simple
        model = compile(<<~RB)
          class A; end
          class B < A; end
        RB

        classes = model.class_defs.sort_by(&:name)
        assert_equal(["::A", "::B"], names(classes))
        assert_nil(classes.first.superclass_name)
        assert_equal("A", classes.last.superclass_name)
      end

      def test_build_scopes_superclass_nested
        model = compile(<<~RB)
          class A
            class B < A; end
          end
        RB

        classes = model.class_defs.sort_by(&:name)
        assert_equal(["::A", "::A::B"], names(classes))
        assert_nil(classes.first.superclass_name)
        assert_equal("A", classes.last.superclass_name)
      end

      def test_build_defs
        model = compile(<<~RB)
          def root; end

          module A
            def a; end
            module B
              class C; end
              def b; end
            end
            def z; end
          end
        RB

        entries = model.entries.sort_by(&:qname)
        assert_equal(["::A", "::A::B", "::A::B::C", "<root>"], names(entries))
        assert_equal(:a, entries[0].method_defs[0].name)
        assert_equal(:z, entries[0].method_defs[1].name)
        assert_equal(:b, entries[1].method_defs[0].name)
        assert_empty(entries[2].method_defs)
        assert_equal(:root, entries[3].method_defs[0].name)
      end

      def test_build_sdefs
        model = compile(<<~RB)
          def self.root; end

          module A
            def self.a; end
            module B
              class C; end
              def self.b; end
            end
            def self.z; end
          end
        RB

        entries = model.entries.sort_by(&:qname)
        assert_equal(:a, entries[0].singleton_method_defs[0].name)
        assert_equal(:z, entries[0].singleton_method_defs[1].name)
        assert_equal(:b, entries[1].singleton_method_defs[0].name)
        assert_empty(entries[2].singleton_method_defs)
        assert_equal(:root, entries[3].singleton_method_defs[0].name)
      end

      def test_build_sdefs_nested
        model = compile(<<~RB)
          def A.root; end

          module A
            def A.a; end
            module B
              class C; end
              def C.b; end
            end
            def B.z; end
          end
        RB

        entries = model.entries.sort_by(&:qname)
        assert_equal("A", entries[0].singleton_method_defs[0].recv)
        assert_equal("B", entries[0].singleton_method_defs[1].recv)
        assert_equal("C", entries[1].singleton_method_defs[0].recv)
        assert_empty(entries[2].singleton_method_defs)
        assert_equal("A", entries[3].singleton_method_defs[0].recv)
      end

      def test_build_def_params
        model = compile(<<~RB)
          def f0; end
          def f1(); end
          def f2(a, b, c); end
          def f3(a = 1, *b, c:); end
          def f4(&blk); end
        RB

        root = model.entries.first
        assert_empty(root.method_defs[0].params)
        assert_empty(root.method_defs[1].params)
        assert_equal([:a, :b, :c], root.method_defs[2].params.map(&:name))
        assert_equal([:a, :b, :c], root.method_defs[3].params.map(&:name))
        assert_equal(:blk, root.method_defs[4].params.first.name)
      end

      def test_build_consts
        model = compile(<<~RB)
          ROOT = 1

          module A
            A = 1
            module B
              class C; end
              C = 1
            end
            B = 1
          end
        RB

        entries = model.entries.sort_by(&:qname)
        assert_equal(["::A", "::A::B", "::A::B::C", "<root>"], names(entries))
        assert_equal(:A, entries[0].const_defs[0].name)
        assert_equal(:B, entries[0].const_defs[1].name)
        assert_equal(:C, entries[1].const_defs[0].name)
        assert_empty(entries[2].const_defs)
        assert_equal(:ROOT, entries[3].const_defs[0].name)
      end

      def test_build_attrs
        model = compile(<<~RB)
          class A; end

          class B
            attr_reader :a
            attr_writer :b, :c
            attr_accessor :d, :e
          end
        RB

        entries = model.entries.sort_by(&:qname)
        assert_equal(["::A", "::B", "<root>"], names(entries))
        assert_empty(entries[0].attrs)
        assert_equal([:a, :b, :c, :d, :e], entries[1].attrs.map(&:name))
        assert_equal(:attr_reader, entries[1].attrs[0].kind)
        assert_equal(:attr_writer, entries[1].attrs[1].kind)
        assert_equal(:attr_accessor, entries[1].attrs[4].kind)
      end

      def test_build_includes
        model = compile(<<~RB)
          module A; end

          module B
            include A
            prepend A
            extend A
          end

          class C
            include A
            prepend A
            extend A
          end
        RB

        entries = model.entries.sort_by(&:qname)
        assert_equal(["::A", "::B", "::C", "<root>"], names(entries))
        assert_empty(entries[0].includes)
        assert_equal(["A", "A", "A"], entries[1].includes.map(&:name))
        assert_equal(["A", "A", "A"], entries[2].includes.map(&:name))
        assert_equal(:include, entries[1].includes[0].kind)
        assert_equal(:prepend, entries[1].includes[1].kind)
        assert_equal(:extend, entries[1].includes[2].kind)
      end

      private

      def compile(code)
        config = Config.new(colors: false)
        compiler = Compiler.new(config)
        tree = compiler.parse_string(code)
        compiler.modelize(tree)
      end

      def names(array)
        array.map(&:to_s).sort
      end
    end
  end
end
