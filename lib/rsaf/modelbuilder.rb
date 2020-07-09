module RSAF
  class ModelBuilder
    def initialize(model)
      @model = model
    end

    def build(*trees)
      trees.each do |tree|
        Modelize::BuildScopeDefs.new(@model).visit(tree)
        # TODO scopes
        # TODO includes
        # TODO inheritance
      end
    end
  end
end
