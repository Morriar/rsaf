module RSAF
  class Model
    # TODO scope_defs?
    attr_reader :root, :modules, :classes, :properties, :module_defs, :class_defs

    def initialize
      @modules = {}
      @classes = {}
      @properties = {}
      @root = make_root # TODO move to builder?
      @module_defs = [] # TODO remove
      @class_defs = []
    end

    def add_module(mod)
      @modules[mod.qname] = mod
    end

    def add_class(klass)
      @classes[klass.qname] = klass
    end

    # TODO remove
    def add_module_def(mdef)
      @module_defs << mdef
    end

    # TODO remove
    def add_class_def(cdef)
      @class_defs << cdef
    end

    # TODO remove
    def entries
      [*module_defs, *class_defs]
    end

    private

    # TODO move to builder?
    def make_root
      root = Model::Module.new(nil, "<root>", "<root>")
      add_module(root)
      root
    end

    # Gloabal entities

    class Entity
      attr_reader :name, :qname

      def initialize(name, qname)
        @name = name
        @qname = qname
      end
    end

    class Scope < Entity
      attr_reader :parent, :children, :defs, :consts, :methods

      def initialize(parent, name, qname)
        super(name, qname)
        @parent = parent
        @children = []
        @defs = []
        @includes = []
        @consts = []
        @methods = []
        parent.children << self if parent
      end

      def root?
        @parent == nil
      end

      def to_s
        qname
      end

      def self.qualify_name(parent, name)
        return "<root>" if !parent && name == "<root>" # TODO yakk..
        return "#{parent.qname}::#{name}" if parent && !parent.root?
        "::#{name}"
      end
    end

    class Module < Scope
    end

    class Class < Scope
      attr_reader :attrs

      def initialize(parent, name, qname)
        super(parent, name, qname)
        @attrs = []
      end
    end

    class Property < Entity
      attr_reader :scope, :defs

      def initialize(scope, name, qname)
        super(name, qname)
        @scope = scope
        @defs = []
      end
    end

    class Attr < Property
      attr_reader :kind

      def initialize(scope, name, qname, kind)
        super(scope, name, qname)
        @kind = kind
        scope.attrs << self
      end

      def self.qualify_name(scope, name)
        return "@#{name}" unless scope
        "#{scope.qname}@#{name}"
      end
    end

    class Const < Property
      def initialize(scope, name, qname)
        super(scope, name, qname)
        scope.consts << self
      end

      def self.qualify_name(scope, name)
        return "::#{name}" unless scope
        "#{scope.qname}::#{name}"
      end
    end

    class Method < Property
      attr_reader :is_singleton, :params

      def initialize(scope, name, qname, is_singleton)
        super(scope, name, qname)
        @is_singleton = is_singleton
        scope.methods << self
      end

      def self.qualify_name(scope, name, is_singleton)
        label = is_singleton ? "::" : "#"
        return "#{label}#{name}" unless scope
        "#{scope.qname}#{label}#{name}"
      end
    end

    # Definitions

    class ScopeDef
      attr_reader :loc, :scope, :consts, :includes, :methods

      def initialize(loc, scope)
        @loc = loc
        @scope = scope
        @consts = []
        @includes = []
        @methods = []
        scope.defs << self
      end

      def name
        @scope.name
      end

      def qname
        @scope.qname
      end

      def to_s
        qname
      end
    end

    class ModuleDef < ScopeDef
    end

    class ClassDef < ScopeDef
      attr_reader :superclass_name, :attrs

      def initialize(loc, scope, superclass_name = nil)
        super(loc, scope)
        @superclass_name = superclass_name
        @attrs = []
      end
    end

    class PropertyDef
      attr_reader :loc, :scope_def, :property

      def initialize(loc, scope_def, property)
        @loc = loc
        @scope_def = scope_def
        @property = property
        property.defs << self
      end

      def name
        @property.name
      end
    end

    class AttrDef < PropertyDef
      attr_reader :kind

      def initialize(loc, scope_def, property, kind)
        super(loc, scope_def, property)
        @kind = kind
        scope_def.attrs << self
      end
    end

    class ConstDef < PropertyDef
      def initialize(loc, scope_def, property)
        super(loc, scope_def, property)
        scope_def.consts << self
      end
    end

    class MethodDef < PropertyDef
      attr_reader :is_singleton, :params

      def initialize(loc, scope_def, property, is_singleton, params)
        super(loc, scope_def, property)
        @is_singleton = is_singleton
        @params = params
        scope_def.methods << self
      end
    end

    class Include
      attr_reader :scope_def, :kind, :name

      def initialize(scope_def, name, kind)
        @scope_def = scope_def
        @name = name
        @kind = kind
        scope_def.includes << self
      end
    end

    class Param
      attr_reader :name

      def initialize(name)
        @name = name
      end

      def to_s
        @name
      end
    end
  end
end
