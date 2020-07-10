module RSAF
  module Phases
    class BuildInheritance
      def self.run(model)
        phase = BuildInheritance.new(model)
        phase.run
      end

      def initialize(model)
        @model = model
      end

      def run
        build_includes
        build_inheritance
      end

      def build_includes
        @model.scopes.values.each do |scope|
          includes = scope.defs.map { |d| d.includes }.flatten
          includes.each do |inc|
            mod = @model.lookup_scope(inc.name, scope)
            unless mod
              # TODO print error
              puts "error can't find superclass `#{superclass_name}` for `#{klass}`"
            end
            unless mod.is_a?(Model::Module)
              # TODO print error
              puts "error can only include modules included #{mod}"
              next
            end
            scope.includes << Model::Include.new(mod, inc.kind)
          end
        end
      end

      def build_inheritance
        @model.classes.each do |klass|
          parents = klass.defs.map { |d| d.superclass_name }.compact
          next if parents.empty?
          if parents.size > 1
            # TODO print error
            puts "error multiple parents for class #{kclass}"
            next
          end
          superclass_name = parents.first
          parent = @model.lookup_scope(superclass_name, klass)
          unless parent
            # TODO print error
            puts "error can't find superclass `#{superclass_name}` for `#{klass}`"
          end
          klass.superclass = parent
        end
      end
    end
  end
end
