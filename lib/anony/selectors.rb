# frozen_string_literal: true

require_relative "./selector_not_found_exception"

module Anony
  class Selectors
    def initialize(model_class, &block)
      @model_class = model_class
      @selectors = {}
      instance_exec(&block) if block
    end

    attr_reader :selectors

    def for_subject(subject, &block)
      selectors[subject] = block
    end

    def select(subject, subject_id, &block)
      selector = selectors[subject]
      raise SelectorNotFoundException.new(subject.to_s, @model_class.name) if selector.nil?

      matching = @model_class.instance_exec(subject_id, &selector)
      matching.map(&block)
    end
  end
end
