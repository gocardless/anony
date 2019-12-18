# frozen_string_literal: true

module Anony
  # This exception is thrown when validating the anonymisation strategies for all fields.
  # If some are missing, they will be included in the message.
  #
  # @example Missing the first_name field
  #   class Employee
  #     anonymise { fields { ignore :last_name } }
  #   end
  #
  #   Employee.first.valid_anonymisation?
  #   => FieldException, Invalid anonymisation strategy for field(s) [:first_name]
  class FieldException < StandardError
    def initialize(fields)
      fields = Array(fields)
      super("Invalid anonymisation strategy for field(s) #{fields}")
    end
  end
end
