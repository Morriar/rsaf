module RSAF
  class Model
    # TODO scope_defs?
    attr_reader :module_defs, :class_defs

    def initialize
      @module_defs = []
      @class_defs = []
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

    class ScopeDef
      attr_reader :parent, :name, :qname, :method_defs, :singleton_method_defs, :const_defs, :includes

      def initialize(parent, name, qname)
        @parent = parent
        @name = name
        @qname = qname
        @method_defs = []
        @singleton_method_defs = []
        @const_defs = []
        @includes = []
      end

      def to_s
        qname
      end
    end

    class ModuleDef < ScopeDef
    end

    class ClassDef < ScopeDef
      attr_reader :superclass_name, :attrs

      def initialize(parent, name, qname, superclass_name = nil)
        super(parent, name, qname)
        @superclass_name = superclass_name
        @attrs = []
      end
    end

    class PropertyDef
      attr_reader :scope_def, :name

      def initialize(scope_def, name)
        @scope_def = scope_def
        @name = name
      end
    end

    class AttrDef < PropertyDef
      attr_reader :kind

      def initialize(scope_def, name, kind)
        super(scope_def, name)
        @kind = kind
      end
    end

    class ConstDef < PropertyDef; end

    class MethodDef < PropertyDef
      attr_reader :params

      def initialize(scope_def, name, params)
        super(scope_def, name)
        @params = params
      end
    end

    class SingletonMethodDef < MethodDef
      attr_reader :recv

      def initialize(scope_def, name, params, recv = nil)
        super(scope_def, name, params)
        @recv = recv
      end
    end

    class Include
      attr_reader :name, :kind

      def initialize(name, kind)
        @name = name
        @kind = kind
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
