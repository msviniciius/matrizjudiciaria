require "erb"

class GoogleCalendarLinkBuilder
  GOOGLE_SUBSCRIBE_URL = "https://calendar.google.com/calendar/r".freeze

  def self.subscribe_url(calendar_feed_url)
    encoded_feed_url = ERB::Util.url_encode(calendar_feed_url)
    "#{GOOGLE_SUBSCRIBE_URL}?cid=#{encoded_feed_url}"
  end
end
