# frozen_string_literal: true

module Anony
  require_relative "anony/anonymisable"
  require_relative "anony/config"
  require_relative "anony/field_exception"
  require_relative "anony/strategies/anonymised_email"
  require_relative "anony/strategies/anonymised_phone_number"
  require_relative "anony/strategies/constant"
  require_relative "anony/strategies/current_datetime"
  require_relative "anony/strategies/nilable"
  require_relative "anony/strategies/no_op"
  require_relative "anony/strategies/overwrite_hex"
  require_relative "anony/strategy_exception"
end
