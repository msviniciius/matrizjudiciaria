require "test_helper"

class DjmaImportPublicationsJobTest < ActiveJob::TestCase
  test "imports publications for offices with configured oab" do
    office = default_office
    office.update!(oab_registration: "18727", oab_state: "MA")

    source = Struct.new(:text, :url).new("OAB 18727-MA Processo 0000001-00.2026.8.10.0001", "https://tjma.example/djma.pdf")

    result = Integrations::Djma::ImportPublicationsJob.perform_now(
      office_id: office.id,
      published_on: "2026-01-22",
      source: source
    )

    assert_equal({ imported: 1, skipped: 0, errors: 0 }, result)
  end

  test "logs import progress and totals" do
    office = default_office
    office.update!(oab_registration: "18727", oab_state: "MA")
    source = Struct.new(:text, :url).new("Sem publicacoes compatíveis", "https://tjma.example/diario")
    logs = StringIO.new
    previous_logger = Rails.logger
    Rails.logger = ActiveSupport::TaggedLogging.new(Logger.new(logs))

    result = Integrations::Djma::ImportPublicationsJob.perform_now(
      office_id: office.id,
      published_on: "2026-01-22",
      source: source
    )

    assert_equal({ imported: 0, skipped: 0, errors: 0 }, result)
    assert_includes logs.string, "[DJMA] Iniciando importação de publicações"
    assert_includes logs.string, "fonte=https://tjma.example/diario"
    assert_includes logs.string, "[DJMA] Importação finalizada"
    assert_includes logs.string, "imported=0 skipped=0 errors=0"
  ensure
    Rails.logger = previous_logger
  end
end
