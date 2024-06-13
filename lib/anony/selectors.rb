# frozen_string_literal: true

require_relative "selector_not_found_exception"

module Anony
  class Selectors
    def initialize(model_class, &block)
      @model_class = model_class
      @selectors = {}
      @associations = nil
      instance_exec(&block) if block
    end

    attr_reader :selectors, :associations

    def for_subject(subject, &block)
      selectors[subject] = block
    end

    def for_associations(*associations)
      raise ArgumentError, "One or more associations required" unless associations.any?

      @associations = associations
    end

    def select(subject, subject_id)
      selector = selectors[subject]
      raise SelectorNotFoundException.new(subject.to_s, @model_class.name) if selector.nil?

      @model_class.instance_exec(subject_id, &selector)
    end
  end
end
