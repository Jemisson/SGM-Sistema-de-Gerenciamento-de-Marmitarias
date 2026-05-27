module Reports
  class FinancialReportService
    def self.call(...)
      new(...).call
    end

    def initialize(params = {})
      @period = PeriodRange.call(params)
    end

    def call
      {
        period: period_payload,
        incomes: incomes.to_s,
        expenses: expenses.to_s,
        balance: (incomes - expenses).to_s,
        totals_by_payment_method: totals_by_payment_method
      }
    end

    private

    attr_reader :period

    def incomes
      confirmed_sales.sum(:total_amount) + financial_entries.income.sum(:amount)
    end

    def expenses
      financial_entries.expense.sum(:amount)
    end

    def totals_by_payment_method
      totals = Hash.new { |hash, key| hash[key] = BigDecimal("0") }

      confirmed_sales.group(:payment_method).sum(:total_amount).each do |payment_method, amount|
        totals[payment_method] += amount
      end

      financial_entries.group(:payment_method).sum(:amount).each do |payment_method, amount|
        totals[payment_method] += amount
      end

      totals.transform_values(&:to_s)
    end

    def confirmed_sales
      Sale.confirmed.where(sold_at: period.start_date..period.end_date)
    end

    def financial_entries
      scope = FinancialEntry.active.where(occurred_at: period.start_date..period.end_date)

      scope.where(source_type: nil).or(scope.where.not(source_type: "Sale"))
    end

    def period_payload
      {
        start_date: period.start_date.iso8601,
        end_date: period.end_date.iso8601
      }
    end
  end
end
