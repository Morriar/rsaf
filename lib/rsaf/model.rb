# typed: strict
# frozen_string_literal: true

module RSAF
  class Model
    extend T::Sig

    sig { returns(Model::Module) }
    attr_reader :root

    sig { returns(T::Hash[String, Model::Scope]) }
    attr_reader :scopes

    sig { returns(T::Hash[String, Model::Property]) }
    attr_reader :properties

    sig { void }
    def initialize
      @scopes = T.let({}, T::Hash[String, Model::Scope])
      @properties = T.let({}, T::Hash[String, Model::Property])
      @root = T.let(make_root, Model::Module) # TODO: move to builder?
    end

    sig { params(mod: Model::Module).void }
    def add_module(mod)
      @scopes[mod.qname] = mod
    end

    sig { params(klass: Model::Class).void }
    def add_class(klass)
      @scopes[klass.qname] = klass
    end

    sig { returns(T::Array[Model::Module]) }
    def modules
      T.cast(@scopes.values.filter { |scope| scope.is_a?(Model::Module) }, T::Array[Model::Module])
    end

    sig { returns(T::Array[Model::Class]) }
    def classes
      T.cast(@scopes.values.filter { |scope| scope.is_a?(Model::Class) }, T::Array[Model::Class])
    end

    sig { params(name: String, scope: T.nilable(Scope)).returns(T.nilable(Model::Scope)) }
    def lookup_scope(name, scope = nil)
      fully_qualified = /^::/.match?(name)
      return @scopes[name] if fully_qualified
      return @scopes.values.filter { |s| s.name == name }.first unless scope

      # TODO: semi-qualified
      # TODO lookup children
      # TODO lookup parents

      @scopes.values.filter { |s| s.name == name }.first
    end

    private

    # TODO: move to builder?
    sig { returns(Model::Module) }
    def make_root
      root = Model::Module.new(nil, "<root>", "<root>")
      add_module(root)
      root
    end

    class MObject
      extend T::Helpers

      abstract!
    end

    # Gloabal entities

    class Entity < MObject
      extend T::Sig
      extend T::Helpers

      abstract!

      sig { returns(String) }
      attr_reader :name, :qname

      sig { params(name: String, qname: String).void }
      def initialize(name, qname)
        @name = name
        @qname = qname
      end
    end

    class Scope < Entity
      extend T::Sig

      sig { returns(T.nilable(Scope)) }
      attr_reader :parent

      sig { returns(T::Array[Scope]) }
      attr_reader :children

      sig { returns(T::Array[ScopeDef]) }
      attr_reader :defs

      sig { returns(T::Array[Include]) }
      attr_reader :includes

      sig { returns(T::Array[Const]) }
      attr_reader :consts

      sig { returns(T::Array[Method]) }
      attr_reader :methods

      sig { params(parent: T.nilable(Scope), name: String, qname: String).void }
      def initialize(parent, name, qname)
        super(name, qname)
        @parent = parent
        @children = T.let([], T::Array[Scope])
        @defs = T.let([], T::Array[ScopeDef])
        @includes = T.let([], T::Array[Include])
        @consts = T.let([], T::Array[Const])
        @methods = T.let([], T::Array[Method])
        parent.children << self if parent
      end

      sig { returns(T::Boolean) }
      def root?
        @parent.nil?
      end

      sig { returns(String) }
      def to_s
        qname
      end

      sig { params(parent: T.nilable(Scope), name: String).returns(String) }
      def self.qualify_name(parent, name)
        return "<root>" if !parent && name == "<root>" # TODO: yakk..
        return "#{parent.qname}::#{name}" if parent && !parent.root?
        "::#{name}"
      end
    end

    class Include < MObject
      extend T::Sig

      sig { returns(Model::Module) }
      attr_reader :mod

      sig { returns(Symbol) }
      attr_reader :kind

      sig { params(mod: Model::Module, kind: Symbol).void }
      def initialize(mod, kind)
        @mod = mod
        @kind = kind
      end
    end

    class Module < Scope
    end

    class Class < Scope
      extend T::Sig

      sig { returns(T::Array[Attr]) }
      attr_reader :attrs

      sig { returns(T.nilable(Model::Class)) }
      attr_accessor :superclass

      sig { params(parent: T.nilable(Scope), name: String, qname: String).void }
      def initialize(parent, name, qname)
        super(parent, name, qname)
        @attrs = T.let([], T::Array[Attr])
      end
    end

    class Property < Entity
      extend T::Sig

      sig { returns(Scope) }
      attr_reader :scope

      sig { returns(T::Array[PropertyDef]) }
      attr_reader :defs

      sig { params(scope: Scope, name: String, qname: String).void }
      def initialize(scope, name, qname)
        super(name, qname)
        @scope = scope
        @defs = T.let([], T::Array[PropertyDef])
      end
    end

    class Attr < Property
      extend T::Sig

      sig { returns(Symbol) }
      attr_reader :kind

      sig { params(scope: Model::Class, name: String, qname: String, kind: Symbol).void }
      def initialize(scope, name, qname, kind)
        super(scope, name, qname)
        @kind = kind
        scope.attrs << self
      end

      sig { params(scope: T.nilable(Scope), name: String).returns(String) }
      def self.qualify_name(scope, name)
        return "@#{name}" unless scope
        "#{scope.qname}@#{name}"
      end
    end

    class Const < Property
      extend T::Sig

      sig { params(scope: Scope, name: String, qname: String).void }
      def initialize(scope, name, qname)
        super(scope, name, qname)
        scope.consts << self
      end

      sig { params(scope: T.nilable(Scope), name: String).returns(String) }
      def self.qualify_name(scope, name)
        return "::#{name}" unless scope
        "#{scope.qname}::#{name}"
      end
    end

    class Method < Property
      extend T::Sig

      sig { returns(T::Boolean) }
      attr_reader :is_singleton

      # sig { returns(T::Array[Param]) }
      # attr_reader :params

      sig { params(scope: Scope, name: String, qname: String, is_singleton: T::Boolean).void }
      def initialize(scope, name, qname, is_singleton)
        super(scope, name, qname)
        @is_singleton = is_singleton
        scope.methods << self
      end

      sig { params(scope: T.nilable(Scope), name: String, is_singleton: T::Boolean).returns(String) }
      def self.qualify_name(scope, name, is_singleton)
        label = is_singleton ? "::" : "#"
        return "#{label}#{name}" unless scope
        "#{scope.qname}#{label}#{name}"
      end
    end

    # Definitions

    class ScopeDef < MObject
      extend T::Sig

      sig { returns(Location) }
      attr_reader :loc

      sig { returns(Scope) }
      attr_reader :scope

      sig { returns(T::Array[ConstDef]) }
      attr_reader :consts

      sig { returns(T::Array[IncludeDef]) }
      attr_reader :includes

      sig { returns(T::Array[MethodDef]) }
      attr_reader :methods

      sig { params(loc: Location, scope: Scope).void }
      def initialize(loc, scope)
        @loc = loc
        @scope = scope
        @consts = T.let([], T::Array[ConstDef])
        @includes = T.let([], T::Array[IncludeDef])
        @methods = T.let([], T::Array[MethodDef])
        scope.defs << self
      end

      sig { returns(String) }
      def name
        @scope.name
      end

      sig { returns(String) }
      def qname
        @scope.qname
      end

      sig { returns(String) }
      def to_s
        qname
      end
    end

    class ModuleDef < ScopeDef
    end

    class ClassDef < ScopeDef
      extend T::Sig

      sig { returns(T.nilable(String)) }
      attr_reader :superclass_name

      sig { returns(T::Array[AttrDef]) }
      attr_reader :attrs

      sig { params(loc: Location, scope: Scope, superclass_name: T.nilable(String)).void }
      def initialize(loc, scope, superclass_name = nil)
        super(loc, scope)
        @superclass_name = superclass_name
        @attrs = T.let([], T::Array[AttrDef])
      end
    end

    class PropertyDef < MObject
      extend T::Sig

      sig { returns(Location) }
      attr_reader :loc

      sig { returns(ScopeDef) }
      attr_reader :scope_def

      sig { returns(Property) }
      attr_reader :property

      sig { params(loc: Location, scope_def: ScopeDef, property: Property).void }
      def initialize(loc, scope_def, property)
        @loc = loc
        @scope_def = scope_def
        @property = property
        property.defs << self
      end

      sig { returns(String) }
      def name
        @property.name
      end
    end

    class AttrDef < PropertyDef
      extend T::Sig

      sig { returns(Symbol) }
      attr_reader :kind

      sig { params(loc: Location, scope_def: ClassDef, property: Property, kind: Symbol).void }
      def initialize(loc, scope_def, property, kind)
        super(loc, scope_def, property)
        @kind = kind
        scope_def.attrs << self
      end
    end

    class ConstDef < PropertyDef
      extend T::Sig

      sig { params(loc: Location, scope_def: ScopeDef, property: Property).void }
      def initialize(loc, scope_def, property)
        super(loc, scope_def, property)
        scope_def.consts << self
      end
    end

    class MethodDef < PropertyDef
      extend T::Sig

      sig { returns(T::Boolean) }
      attr_reader :is_singleton

      sig { returns(T::Array[Param]) }
      attr_reader :params

      sig do
        params(
          loc: Location,
          scope_def: ScopeDef,
          property: Property,
          is_singleton: T::Boolean,
          params: T::Array[Param]
        ).void
      end
      def initialize(loc, scope_def, property, is_singleton, params)
        super(loc, scope_def, property)
        @is_singleton = is_singleton
        @params = params
        scope_def.methods << self
      end
    end

    class IncludeDef < MObject
      extend T::Sig

      sig { returns(ScopeDef) }
      attr_reader :scope_def

      sig { returns(Symbol) }
      attr_reader :kind

      sig { returns(String) }
      attr_reader :name

      sig { params(scope_def: ScopeDef, name: String, kind: Symbol).void }
      def initialize(scope_def, name, kind)
        @scope_def = scope_def
        @name = name
        @kind = kind
        scope_def.includes << self
      end
    end

    # Misc

    class Param < MObject
      extend T::Sig

      sig { returns(String) }
      attr_reader :name

      sig { params(name: String).void }
      def initialize(name)
        @name = name
      end

      sig { returns(String) }
      def to_s
        @name
      end
    end
  end
end
