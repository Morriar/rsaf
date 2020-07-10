require_relative "../../test_helper"

module RSAF
  module Phases
    class BuildScopeDefsTest < Minitest::Test
      def test_build_scopes_empty
        assert_equal(<<~EXP, compile(""))
          module <root>
            defined at :0:0
        EXP
      end

      def test_build_scopes_simple
        rb = <<~RB
          module A; end

          class A::B
          end
        RB
        assert_equal(<<~EXP, compile(rb))
          module <root>
            defined at :0:0
            module ::A
              defined at :1:0-1:13
            class ::A::B
              defined at :3:0-4:3
        EXP
      end

      def test_build_scope_nested
        rb = <<~RB
          module A
            module B
              class C; end
            end
          end

          class D
            module E; end
          end
        RB
        assert_equal(<<~EXP, compile(rb))
          module <root>
            defined at :0:0
            module ::A
              defined at :1:0-5:3
              module ::A::B
                defined at :2:2-4:5
                class ::A::B::C
                  defined at :3:4-3:16
            class ::D
              defined at :7:0-9:3
              module ::D::E
                defined at :8:2-8:15
        EXP
      end

      def test_build_scope_mixed
        rb = <<~RB
          module A
            module B::C
              class D; end
            end
          end

          class D::E
            module F::G; end
          end
        RB
        assert_equal(<<~EXP, compile(rb))
          module <root>
            defined at :0:0
            module ::A
              defined at :1:0-5:3
              module ::A::B::C
                defined at :2:2-4:5
                class ::A::B::C::D
                  defined at :3:4-3:16
            class ::D::E
              defined at :7:0-9:3
              module ::D::E::F::G
                defined at :8:2-8:18
        EXP
      end

      def test_build_scope_reopened
        rb = <<~RB
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
        assert_equal(<<~EXP, compile(rb))
          module <root>
            defined at :0:0
            module ::A
              defined at :1:0-5:3
              defined at :7:0-10:3
              module ::A::B::C
                defined at :2:2-4:5
                class ::A::B::C::D
                  defined at :3:4-3:16
              module ::A::B::C::D::E
                defined at :8:2-8:24
              class ::A::F::G
                defined at :9:2-9:17
        EXP
      end

      # Inheritance

      def test_build_scopes_includes
        rb = <<~RB
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
        # TODO
        assert_equal(<<~EXP, compile(rb))
          module <root>
            defined at :0:0
            module ::A
              defined at :1:0-1:13
            module ::B
              defined at :3:0-7:3
            class ::C
              defined at :9:0-13:3
        EXP
      end

      def test_build_scope_superclass_simple
        rb = <<~RB
          class A; end
          class B < A; end
        RB
        # TODO
        assert_equal(<<~EXP, compile(rb))
          module <root>
            defined at :0:0
            class ::A
              defined at :1:0-1:12
            class ::B
              defined at :2:0-2:16
        EXP
      end

      def test_build_scope_defs_superclass_nested
        rb = <<~RB
          class A
            class B < A; end
          end
        RB
        assert_equal(<<~EXP, compile(rb))
          module <root>
            defined at :0:0
            class ::A
              defined at :1:0-3:3
              class ::A::B
                defined at :2:2-2:18
        EXP
      end

      # Properties

      def test_build_scopes_attrs
        rb = <<~RB
          class A; end

          class B
            attr_reader :a
            attr_writer :b, :c
            attr_accessor :d, :e
          end
        RB
        assert_equal(<<~EXP, compile(rb))
          module <root>
            defined at :0:0
            class ::A
              defined at :1:0-1:12
            class ::B
              defined at :3:0-7:3
              attr_reader a
                defined at :4:2-4:16
              attr_writer b
                defined at :5:2-5:20
              attr_writer c
                defined at :5:2-5:20
              attr_accessor d
                defined at :6:2-6:22
              attr_accessor e
                defined at :6:2-6:22
        EXP
      end

      def test_build_scopes_consts
        rb = <<~RB
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
        assert_equal(<<~EXP, compile(rb))
          module <root>
            defined at :0:0
            ROOT
              defined at :1:0-1:8
            module ::A
              defined at :3:0-10:3
              A
                defined at :4:2-4:7
              B
                defined at :9:2-9:7
              module ::A::B
                defined at :5:2-8:5
                C
                  defined at :7:4-7:9
                class ::A::B::C
                  defined at :6:4-6:16
        EXP
      end

      def test_build_scopes_methods
        rb = <<~RB
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
        assert_equal(<<~EXP, compile(rb))
          module <root>
            defined at :0:0
            def root
              defined at :1:0-1:13
                signature: root
            module ::A
              defined at :3:0-10:3
              def a
                defined at :4:2-4:12
                  signature: a
              def z
                defined at :9:2-9:12
                  signature: z
              module ::A::B
                defined at :5:2-8:5
                def b
                  defined at :7:4-7:14
                    signature: b
                class ::A::B::C
                  defined at :6:4-6:16
        EXP
      end

      def test_build_scope_methods_singleton
        rb = <<~RB
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
        assert_equal(<<~EXP, compile(rb))
          module <root>
            defined at :0:0
            def self.root
              defined at :1:0-1:18
                signature: root
            module ::A
              defined at :3:0-10:3
              def self.a
                defined at :4:2-4:17
                  signature: a
              def self.z
                defined at :9:2-9:17
                  signature: z
              module ::A::B
                defined at :5:2-8:5
                def self.b
                  defined at :7:4-7:19
                    signature: b
                class ::A::B::C
                  defined at :6:4-6:16
        EXP
      end

      def test_build_scopes_method_params
        rb = <<~RB
          def f0; end
          def f1(); end
          def f2(a, b, c); end
          def f3(a = 1, *b, c:); end
          def f4(&blk); end
        RB
        assert_equal(<<~EXP, compile(rb))
          module <root>
            defined at :0:0
            def f0
              defined at :1:0-1:11
                signature: f0
            def f1
              defined at :2:0-2:13
                signature: f1
            def f2
              defined at :3:0-3:20
                signature: f2(a, b, c)
            def f3
              defined at :4:0-4:26
                signature: f3(a, b, c)
            def f4
              defined at :5:0-5:17
                signature: f4(blk)
        EXP
      end

      private

      def compile(code)
        config = Config.new(colors: false)
        compiler = Compiler.new(config)
        model = compiler.compile_code(code)
        out = StringIO.new
        Model::ModelPrinter.new(colors: false, out: out).print_model(model)
        out.string
      end

      def names(array)
        array.map(&:to_s).sort
      end
    end
  end
end
