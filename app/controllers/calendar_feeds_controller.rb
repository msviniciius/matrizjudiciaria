class CalendarFeedsController < ActionController::Base
  def legal_case
    legal_case = LegalCase.find_by_calendar_feed_token!(params[:token].to_s)
    exporter = LegalCaseCalendarExporter.new(legal_case)

    expires_in 5.minutes, public: true
    render plain: exporter.to_ics, content_type: "text/calendar; charset=utf-8"
  rescue ActiveSupport::MessageVerifier::InvalidSignature, ActiveRecord::RecordNotFound
    head :not_found
  end

  def office
    office = Office.find_by_calendar_feed_token!(params[:token].to_s)
    exporter = OfficeCalendarExporter.new(office)

    expires_in 5.minutes, public: true
    render plain: exporter.to_ics, content_type: "text/calendar; charset=utf-8"
  rescue ActiveSupport::MessageVerifier::InvalidSignature, ActiveRecord::RecordNotFound
    head :not_found
  end
end
