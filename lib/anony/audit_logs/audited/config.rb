# frozen_string_literal: true

require 'audited'

require_relative './overwrite'

module Anony
  module AuditLogs
    module Audited
      class Config

        # @api private
        class UndefinedStrategy
          def valid?
            false
          end

          def validate!
            raise ArgumentError, "Must specify either :delete_all or :overwrite strategy"
          end

          def skip_auditing
            yield
          end
        end

        # @!visibility private
        def initialize(model_class, &block)
          @model_class = model_class
          @strategy = UndefinedStrategy.new
          instance_eval(&block) if block
        end

        delegate :valid?, :validate!, :skip_auditing, to: :@strategy


        # Apply the Overwrite strategy on the model instance, which applies each of the
        # configured transformations and updates the :anonymised_at field if it exists.
        #
        # @param [ActiveRecord::Base] instance An instance of the model
        def apply(instance)
          @strategy.apply(instance)
        end

        def overwrite(&block)
          unless @strategy.is_a?(UndefinedStrategy)
            raise ArgumentError, "Cannot specify :overwrite when another strategy already defined"
          end

          @strategy = Overwrite.new(@model_class, &block)
        end
      end
    end
  end
end
