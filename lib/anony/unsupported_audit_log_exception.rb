# frozen_string_literal: true

module Anony
  # This exception is thrown if you specify an unsupported audit log extension.
  class UnsupportedAuditLogException < StandardError
    def initialize(name)
      super("Unsupported audit log '#{name}'.")
    end
  end
end
