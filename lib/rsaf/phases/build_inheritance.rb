# typed: strict
# frozen_string_literal: true

module RSAF
  module Phases
    class BuildInheritance
      extend T::Sig

      sig { params(model: Model).void }
      def self.run(model)
        phase = BuildInheritance.new(model)
        phase.run
      end

      sig { params(model: Model).void }
      def initialize(model)
        @model = model
      end

      sig { void }
      def run
        build_includes
        build_inheritance
      end

      sig { void }
      def build_includes
        @model.scopes.values.each do |scope|
          includes = scope.defs.map(&:includes).flatten
          includes.each do |inc|
            mod = @model.lookup_scope(inc.name, scope)
            unless mod
              # TODO: print error
              # puts "error can't find superclass `#{inc.name}` for `#{scope}`"
              next
            end
            unless mod.is_a?(Model::Module)
              # TODO: print error
              puts "error can only include modules included #{mod}"
              next
            end
            scope.includes << Model::Include.new(mod, inc.kind)
          end
        end
      end

      sig { void }
      def build_inheritance
        @model.classes.each do |klass|
          parents = T.cast(klass.defs, T::Array[Model::ClassDef]).map(&:superclass_name).compact
          next if parents.empty?
          if parents.size > 1
            # TODO: print error
            puts "error multiple parents for class #{klass}"
            next
          end
          superclass_name = T.must(parents.first)
          parent = @model.lookup_scope(superclass_name, klass)
          unless parent
            # TODO check scope is a module
            # TODO: print error
            # puts "error can't find superclass `#{superclass_name}` for `#{klass}`"
            next
          end
          unless parent.is_a?(Model::Class)
            # TODO check scope is a module
            # TODO: print error
            puts "error using module `#{parent.qname}` as superclass for `#{klass}`"
            next
          end
          klass.superclass = parent
        end
      end
    end
  end
end
