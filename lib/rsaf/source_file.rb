# typed: strict

module RSAF
  class SourceFile < T::Struct
    const :path, T.nilable(String)
    prop :tree, T.nilable(AST::Node)
    prop :root_def, T.nilable(Model::ModuleDef)
    prop :strictness, T.nilable(String)
  end
end
