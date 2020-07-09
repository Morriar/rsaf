require_relative "../test_helper"

module RSAF
  module Tests
    class ModelizeTest < Minitest::Test
      def test_modelize_scopes_empty
        model = compile("")
        assert_equal(1, model.entries.size)
        assert_equal("<root>", model.entries.first.name)
      end

      def test_modelize_scopes_simple
        model = compile(<<~RB)
          module A; end

          class B
          end
        RB

        assert_equal(["::A", "::B", "<root>"], names(model.entries))
        assert_equal(["::A", "<root>"], names(model.module_defs))
        assert_equal(["::B"], names(model.class_defs))
      end

      def test_modelize_scopes_qualified
        model = compile(<<~RB)
          module A::A
          end

          class B::B; end
        RB

        assert_equal(["::A::A", "::B::B", "<root>"], names(model.entries))
      end

      def test_modelize_scopes_nested
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

      def test_modelize_scopes_mixed
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

      def test_modelize_scopes_reopened
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

      def test_modelize_scopes_superclass_simple
        model = compile(<<~RB)
          class A; end
          class B < A; end
        RB

        classes = model.class_defs.sort_by(&:name)
        assert_equal(["::A", "::B"], names(classes))
        assert_nil(classes.first.superclass_name)
        assert_equal("A", classes.last.superclass_name)
      end

      def test_modelize_scopes_superclass_nested
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

      def test_modelize_defs
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
        assert_equal(:a, entries[0].method_defs[0].name)
        assert_equal(:z, entries[0].method_defs[1].name)
        assert_equal(:b, entries[1].method_defs[0].name)
        assert_empty(entries[2].method_defs)
      end

      def test_modelize_sdefs
        model = compile(<<~RB)
          def root; end

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
      end

      def test_modelize_sdefs_nested
        model = compile(<<~RB)
          def self.root; end
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
        assert_equal(:a, entries[0].singleton_method_defs[0].name)
        assert_equal(:z, entries[0].singleton_method_defs[1].name)
        assert_equal(:b, entries[1].singleton_method_defs[0].name)
        assert_empty(entries[2].singleton_method_defs)
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
