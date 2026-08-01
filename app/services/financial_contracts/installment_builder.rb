module FinancialContracts
  class InstallmentBuilder
    MINIMUM_COUNT = 1
    MAXIMUM_COUNT = 12
    MINIMUM_INSTALLMENT_AMOUNT = 0.01.to_d

    def self.call(contract:, count:, first_due_date:)
      new(contract: contract, count: count, first_due_date: first_due_date).call
    end

    def initialize(contract:, count:, first_due_date:)
      @contract = contract
      @count = normalize_count(count)
      @first_due_date = first_due_date.to_date
    end

    def call
      validate_contract!
      total = total_amount
      validate_total!(total)

      @contract.transaction do
        @contract.update!(installment_count: @count)
        amounts(total).each_with_index.map do |amount, index|
          @contract.installments.create!(
            number: index + 1,
            amount: amount,
            due_date: @first_due_date >> index
          )
        end
      end
    end

    private

    def normalize_count(value)
      raise ArgumentError, "installment count must be a whole number between 1 and 12" unless value.to_d.frac.zero?

      count = integer_count(value)
      return count if count.between?(MINIMUM_COUNT, MAXIMUM_COUNT)

      raise ArgumentError, "installment count must be between 1 and 12"
    end

    def integer_count(value)
      Integer(value)
    rescue ArgumentError, TypeError
      raise ArgumentError, "installment count must be a whole number between 1 and 12"
    end

    def validate_contract!
      raise ArgumentError, "financial contract must be persisted" unless @contract.persisted?
      raise ArgumentError, "financial contract already has installments" if @contract.installments.exists?
    end

    def total_amount
      @contract.total_amount.to_d.round(2)
    end

    def validate_total!(total)
      return if total >= (@count * MINIMUM_INSTALLMENT_AMOUNT)

      raise ArgumentError, "total amount must allow at least R$0.01 per installment"
    end

    def amounts(total)
      base_amount = (total / @count).round(2, BigDecimal::ROUND_DOWN)
      final_amount = total - (base_amount * (@count - 1))

      Array.new(@count - 1, base_amount) + [ final_amount ]
    end
  end
end
