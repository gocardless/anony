# frozen_string_literal: true

module Anony
  class DSL
    def initialize
      @anonymisable_fields = {}
      @destroy_on_anonymise = false
    end

    attr_reader :anonymisable_fields, :destroy_on_anonymise

    def with_strategy(strategy, *fields, &block)
      if block_given?
        fields.unshift(strategy)
        strategy = block
      end

      fields = fields.flatten

      raise ArgumentError, "Block or Strategy object required" unless strategy
      raise ArgumentError, "One or more fields required" unless fields.any?
      raise ArgumentError, "Can't specify destroy and strategies for fields" if destroy_on_anonymise

      fields.each { |field| anonymisable_fields[field] = strategy }
    end

    def hex(*fields, max_length: 36)
      with_strategy(Strategies::OverwriteHex.new(max_length), *fields)
    end

    def email(*fields)
      with_strategy(Strategies::AnonymisedEmail, *fields)
    end

    def phone_number(*fields)
      with_strategy(Strategies::AnonymisedPhoneNumber, *fields)
    end

    def nilable(*fields)
      with_strategy(Strategies::Nilable, *fields)
    end

    def current_datetime(*fields)
      with_strategy(Strategies::CurrentDatetime, *fields)
    end

    def ignore(*fields)
      already_ignored = fields.select { |field| Config.ignore?(field) }

      if already_ignored.any?
        raise ArgumentError, "Cannot ignore #{already_ignored.inspect} " \
                             "(fields already ignored in Anony::Config)"
      end

      with_strategy(Strategies::NoOp, *fields)
    end

    def destroy
      unless anonymisable_fields.empty?
        raise ArgumentError, "Can't specify destroy and strategies for fields"
      end

      @destroy_on_anonymise = true
    end
  end
end
