module RSAF
  class Model
    # TODO scope_defs?
    attr_reader :root, :modules, :classes, :module_defs, :class_defs

    def initialize
      @modules = {}
      @classes = {}
      @root = make_root
      @module_defs = []
      @class_defs = []
    end

    def add_module(mod)
      @modules[mod.qname] = mod
    end

    def add_class(klass)
      @classes[klass.qname] = klass
    end

    def add_module_def(mdef)
      @module_defs << mdef
    end

    def add_class_def(cdef)
      @class_defs << cdef
    end

    def entries
      [*module_defs, *class_defs]
    end

    private

    def make_root
      root = Model::Module.new(nil, "<root>")
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

      def initialize(parent, name)
        qname = "::#{name}"
        qname = "#{parent.qname}#{qname}" if parent && !parent.root?
        qname = "<root>" unless parent # TODO remove after printer?
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
    end

    class Module < Scope
    end

    class Class < Scope
      attr_reader :attrs

      def initialize(parent, name)
        super(parent, name)
        @attrs = []
      end
    end

    class Property < Entity
      attr_reader :scope

      def initialize(scope, name, qname)
        super(name, qname)
        @scope = scope
      end
    end

    class Attr < Property
      attr_reader :kind

      def initialize(scope, name, kind)
        super(scope, name, "#{scope ? scope.qname : ""}##{name}")
        @kind = kind
      end
    end

    class Const < Property
      def initialize(scope, name)
        super(scope, name, "#{scope ? scope.qname : ""}::#{name}")
      end
    end

    class Method < Property
      attr_reader :params, :is_singleton

      def initialize(scope, name, is_singleton)
        super(scope, name, "#{scope ? scope.qname : ""}##{name}")
        @is_singleton = is_singleton
      end
    end

    # Definitions

    class ScopeDef
      attr_reader :scope, :consts, :includes, :methods

      def initialize(scope)
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

      def initialize(scope, superclass_name = nil)
        super(scope)
        @superclass_name = superclass_name
        @attrs = []
      end
    end

    class PropertyDef
      attr_reader :scope_def, :property

      def initialize(scope_def, property)
        @scope_def = scope_def
        @property = property
      end

      def name
        @property.name
      end
    end

    class AttrDef < PropertyDef
      attr_reader :kind

      def initialize(scope_def, property, kind)
        super(scope_def, property)
        @kind = kind
        scope_def.attrs << self
      end
    end

    class ConstDef < PropertyDef
      def initialize(scope_def, property)
        super(scope_def, property)
        scope_def.consts << self
      end
    end

    class MethodDef < PropertyDef
      attr_reader :is_singleton, :params

      def initialize(scope_def, property, is_singleton, params)
        super(scope_def, property)
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
