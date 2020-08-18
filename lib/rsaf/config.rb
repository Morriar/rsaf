# typed: strict
# frozen_string_literal: true

module RSAF
  class Config
    extend T::Sig

    sig { returns(T::Boolean) }
    attr_reader :colors, :timers, :global

    sig { params(colors: T::Boolean, timers: T::Boolean, global: T::Boolean).void }
    def initialize(colors: true, timers: false, global: true)
      @colors = colors
      @timers = timers
      @global = global
    end
  end
end
