module RSAF
  class ModelBuilder
    def initialize(model)
      @model = model
    end

    def build(*trees)
      trees.each do |tree|
        Modelize::ScopeDefs.new(@model).visit(tree)
      end
    end
  end
end
