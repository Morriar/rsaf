module RSAF
  class ModelBuilder
    def initialize(model)
      @model = model
    end

    def build(*trees)
      trees.each do |tree|
        Phases::BuildScopes.new(@model).visit(tree)
        # TODO inheritance
        # TODO includes
        # build_inheritance
      end
    end

    def build_inheritance
      @model.classes.values.each do |cla|
        with_superclass = cla.scope_defs { |class_def| class_def.superclass_name }
        next if with_superclass.empty?
        # puts cla
        puts with_superclass.map(&:name)
      end
    end
  end
end
