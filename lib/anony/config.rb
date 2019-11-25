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

    # @!attribute email_template
    #   @!scope class
    #   The email template that will be used when using the :email strategy. If you
    #   optionally define a `%s` inside a string, it will be replaced with
    #   `SecureRandom.uuid`.
    #   @see Strategies::AnonymisedEmail
    #
    #   @example With string substitution
    #     Anony::Config.email_template = "anonymised-%s@example.com"
    #
    #   @example Static string
    #     Anony::Config.email_template = "nobody@example.net"
    mattr_accessor :email_template

    # @!attribute phone_number
    #   @!scope class
    #   The phone number that will be used when using the :phone_number strategy.
    #   @see Strategies::AnonymisedPhoneNumber
    #   @example
    #     Anony::Config.phone_number = "+44 1632 960670"
    mattr_accessor :phone_number

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
    # By default, this is an empty collection (i.e. no fields are ignored).
    #
    # @param [Array<Symbol>] fields A list of fields names to ignore.
    # @example Ignoring common Rails fields
    #   Anony::Config.ignore_fields(:id, :created_at, :updated_at)
    def self.ignore_fields(*fields)
      self.ignores = Array(fields)
    end

    self.ignores = []

    self.email_template = "%s@example.com"
    self.phone_number = "+1 617 555 1294"
  end
end
