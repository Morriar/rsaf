# typed: strict

module RSAF
  class SourceFile < T::Struct
    const :path, T.nilable(String)
    const :tree, T.nilable(AST::Node)
    prop :root_def, T.nilable(Model::ModuleDef)
  end
end
