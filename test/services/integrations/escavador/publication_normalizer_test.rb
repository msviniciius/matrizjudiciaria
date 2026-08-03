require "test_helper"

class EscavadorPublicationNormalizerTest < ActiveSupport::TestCase
  test "normalizes a daily publication payload" do
    payload = {
      "evento" => "diario_movimentacao_nova",
      "uuid" => "evt-123",
      "movimentacao" => {
        "conteudo" => "Publicacao do processo 0000001-00.2026.8.10.0001",
        "data" => "2026-08-03",
        "tribunal" => "TJMA",
        "diario" => "DJE MA"
      }
    }

    attributes = Integrations::Escavador::PublicationNormalizer.new(payload).call

    assert_equal "evt-123", attributes[:external_id]
    assert_equal "diario_movimentacao_nova", attributes[:event_name]
    assert_equal "0000001-00.2026.8.10.0001", attributes[:process_number]
    assert_equal "TJMA", attributes[:court_name]
    assert_equal "DJE MA", attributes[:journal_name]
    assert_equal Date.new(2026, 8, 3), attributes[:published_at].to_date
  end

  test "ignores nova movimentacao when it is not a publication" do
    payload = {
      "evento" => "nova_movimentacao",
      "movimentacao" => {
        "tipo" => "ANDAMENTO",
        "conteudo" => "Andamento processual"
      }
    }

    assert_not Integrations::Escavador::PublicationNormalizer.new(payload).supported?
  end
end
