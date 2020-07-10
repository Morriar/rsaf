# typed: strict
# frozen_string_literal: true

module RSAF
  class Config
    extend T::Sig

    sig { returns(T::Boolean) }
    attr_reader :colors

    sig { params(colors: T::Boolean).void }
    def initialize(colors: true)
      @colors = colors
    end
  end
end
