# frozen_string_literal: true

require "active_support/core_ext/module/attribute_accessors"

module Anony
  # Configuration which modifies how the gem will behave in your application. It's
  # recommended practice to configure this in an initializer.
  #
  # @example
  #   # config/initializers/anony.rb
  #   require "anony"
  #
  #   Anony::Config.ignore_fields(:id)
  module Config
    mattr_accessor :ignores

    # @!visibility private
    def self.ignore?(field)
      # In this case, we want to support literal matches, regular expressions and blocks,
      # all of which are helpfully handled by Object#===.
      #
      # rubocop:disable Style/CaseEquality
      ignores.any? { |rule| rule === field }
      # rubocop:enable Style/CaseEquality
    end

    # A list of database or model properties to be ignored when anonymising. This is
    # helpful in Rails applications when there are common columns such as `id`,
    # `created_at` and `updated_at`, which we would never want to try and anonymise.
    #
    # By default, common Rails columns are ignored (i.e. id, created_at, updated_at).
    #
    # @param [Array<Symbol>] fields A list of fields names to ignore.
    # @example Ignoring common Rails fields
    #   Anony::Config.ignore_fields(:id, :created_at, :updated_at)
    def self.ignore_fields(*fields)
      self.ignores = Array(fields)
    end

    self.ignores = [:id, :created_at, :updated_at]
  end
end
