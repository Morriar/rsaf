# typed: strict
# frozen_string_literal: true

module RSAF
  class Config
    extend T::Sig

    sig { returns(T::Boolean) }
    attr_reader :colors

    sig { returns(T::Boolean) }
    attr_reader :timers

    sig { params(colors: T::Boolean, timers: T::Boolean).void }
    def initialize(colors: true, timers: false)
      @colors = colors
      @timers = timers
    end
  end
end
