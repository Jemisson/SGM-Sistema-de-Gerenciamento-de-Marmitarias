module Reports
  class PeriodRange
    VALID_PERIODS = %w[today week month year custom].freeze

    attr_reader :start_date, :end_date

    def self.call(...)
      new(...).call
    end

    def initialize(params = {})
      @params = params.to_h.symbolize_keys
    end

    def call
      period = params.fetch(:period, "month").presence || "month"
      raise ArgumentError, "period is invalid" unless VALID_PERIODS.include?(period)

      @start_date, @end_date = range_for(period)
      raise ArgumentError, "end_date can't be before start_date" if end_date < start_date

      self
    end

    private

    attr_reader :params

    def range_for(period)
      case period
      when "today"
        [Time.zone.today.beginning_of_day, Time.zone.today.end_of_day]
      when "week"
        [Time.zone.today.beginning_of_week.beginning_of_day, Time.zone.today.end_of_week.end_of_day]
      when "month"
        [Time.zone.today.beginning_of_month.beginning_of_day, Time.zone.today.end_of_month.end_of_day]
      when "year"
        [Time.zone.today.beginning_of_year.beginning_of_day, Time.zone.today.end_of_year.end_of_day]
      when "custom"
        custom_range
      end
    end

    def custom_range
      [
        parse_time(params[:start_date])&.beginning_of_day,
        parse_time(params[:end_date])&.end_of_day
      ].tap do |start_date, end_date|
        raise ArgumentError, "start_date is required for custom period" unless start_date
        raise ArgumentError, "end_date is required for custom period" unless end_date
      end
    end

    def parse_time(value)
      return if value.blank?

      Time.zone.parse(value.to_s)
    end
  end
end
