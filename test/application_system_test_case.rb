require "test_helper"
require "capybara/rails"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  self.use_transactional_tests = false

  browser = ENV.fetch("SYSTEM_TEST_BROWSER", "headless_chrome").to_sym
  driven_by :selenium, using: browser, screen_size: [ 1400, 1400 ]
end
