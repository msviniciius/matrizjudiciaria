require "bigdecimal"

module FinancialContracts
  class Calculator
    HUNDRED = BigDecimal("100")

    def self.call(**attributes)
      new(**attributes).call
    end

    def initialize(fixed_amount:, includes_percentage:, percentage:, percentage_basis:, claim_value:, client_received:)
      @fixed_amount = decimal!(fixed_amount, "fixed amount")
      @includes_percentage = includes_percentage
      @percentage = percentage
      @percentage_basis = percentage_basis&.to_s
      @claim_value = claim_value
      @client_received = client_received
    end

    def call
      validate_fixed_amount!
      return @fixed_amount.round(2) unless @includes_percentage

      (@fixed_amount + percentage_amount).round(2)
    end

    private

    def percentage_amount
      percentage = decimal!(@percentage, "percentage")
      raise ArgumentError, "percentage must be between 0 and 100" unless percentage.positive? && percentage <= HUNDRED

      (percentage_base * percentage / HUNDRED).round(2)
    end

    def percentage_base
      case @percentage_basis
      when "claim_value"
        decimal!(@claim_value, "claim value")
      when "client_received"
        decimal!(@client_received, "client received amount")
      else
        raise ArgumentError, "percentage basis must be claim_value or client_received"
      end
    end

    def validate_fixed_amount!
      raise ArgumentError, "fixed amount must be greater than zero" unless @fixed_amount.positive?
    end

    def decimal!(value, field_name)
      raise ArgumentError, "#{field_name} is required" if value.blank?

      number = BigDecimal(value.to_s, exception: false)
      raise ArgumentError, "#{field_name} must be a valid amount" if number.nil?
      raise ArgumentError, "#{field_name} must be a valid amount" unless number.finite?

      raise ArgumentError, "#{field_name} must be greater than or equal to zero" if number.negative?

      number
    end
  end
end
