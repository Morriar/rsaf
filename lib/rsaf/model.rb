module RSAF
  class Model
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
      attr_reader :parent, :name, :qname, :method_defs, :singleton_method_defs

      def initialize(parent, name, qname)
        @parent = parent
        @name = name
        @qname = qname
        @method_defs = []
        @singleton_method_defs = []
      end

      def to_s
        qname
      end
    end

    class ModuleDef < ScopeDef
    end

    class ClassDef < ScopeDef
      attr_reader :superclass_name

      def initialize(parent, name, qname, superclass_name = nil)
        super(parent, name, qname)
        @superclass_name = superclass_name
      end
    end

    class PropertyDef
      attr_reader :scope_def, :name

      def initialize(scope_def, name)
        @scope_def = scope_def
        @name = name
      end
    end

    class MethodDef < PropertyDef
      attr_reader :args

      def initialize(scope_def, name, args)
        super(scope_def, name)
        @args = args
      end
    end

    class SingletonMethodDef < MethodDef
      attr_reader :recv

      def initialize(scope_def, name, args, recv = nil)
        super(scope_def, name, args)
        @recv = recv
      end
    end
  end
end
