module FinancialContracts
  class InstallmentBuilder
    MINIMUM_COUNT = 1
    MAXIMUM_COUNT = 12
    MINIMUM_INSTALLMENT_AMOUNT = 0.01.to_d

    def self.call(contract:, count:, first_due_date:, installments: nil, due_dates: nil)
      new(contract: contract, count: count, first_due_date: first_due_date, installments: installments, due_dates: due_dates).call
    end

    def initialize(contract:, count:, first_due_date:, installments: nil, due_dates: nil)
      @contract = contract
      @count = normalize_count(count)
      @first_due_date = first_due_date.to_date
      @installments = normalize_installments(installments)
      @due_dates = Array(due_dates).map(&:to_date)
    end

    def call
      validate_contract!
      total = total_amount
      validate_total!(total)

      @contract.transaction do
        @contract.update!(installment_count: @count)
        installment_attributes(total).map do |attributes|
          @contract.installments.create!(
            number: attributes.fetch(:number),
            amount: attributes.fetch(:amount),
            due_date: attributes.fetch(:due_date)
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

    def installment_attributes(total)
      return generated_installments(total) if @installments.nil?

      validate_manual_installments!(total)
      @installments
    end

    def generated_installments(total)
      amounts(total).each_with_index.map do |amount, index|
        { number: index + 1, amount: amount, due_date: @due_dates[index] || (@first_due_date >> index) }
      end
    end

    def normalize_installments(installments)
      return nil if installments.blank?

      Array(installments).map do |installment|
        attributes = installment.to_h.symbolize_keys
        {
          number: normalize_manual_number(attributes[:number]),
          amount: normalize_manual_amount(attributes[:amount]),
          due_date: normalize_manual_due_date(attributes[:due_date])
        }
      end
    end

    def normalize_manual_number(value)
      Integer(value)
    rescue ArgumentError, TypeError
      raise ArgumentError, "installment numbers must be whole numbers"
    end

    def normalize_manual_amount(value)
      amount = BigDecimal(value.to_s, exception: false)
      if amount.nil? || !amount.finite? || amount < MINIMUM_INSTALLMENT_AMOUNT || amount != amount.round(2)
        raise ArgumentError, "installment amounts must be positive values with at most two decimal places"
      end

      amount
    end

    def normalize_manual_due_date(value)
      Date.iso8601(value.to_s)
    rescue ArgumentError
      raise ArgumentError, "installment due dates must be valid dates"
    end

    def validate_manual_installments!(total)
      unless @installments.size == @count
        raise ArgumentError, "installment schedule must contain exactly the selected installment count"
      end
      unless @installments.pluck(:number) == (1..@count).to_a
        raise ArgumentError, "installment numbers must be sequential from 1"
      end
      unless @installments.sum { |installment| installment.fetch(:amount) } == total
        raise ArgumentError, "installment amount sum must equal the contract total"
      end
    end

    def amounts(total)
      base_amount = (total / @count).round(2, BigDecimal::ROUND_DOWN)
      final_amount = total - (base_amount * (@count - 1))

      Array.new(@count - 1, base_amount) + [ final_amount ]
    end
  end
end
