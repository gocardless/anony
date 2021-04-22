# frozen_string_literal: true

module Anony
  module AnonymisableModels
    require 'set'

    @models = Set.new

    def add(klass)
      @models << klass
    end

    def list
      @models.dup
    end

    module_function :add, :list
  end
end
