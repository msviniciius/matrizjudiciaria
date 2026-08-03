require "test_helper"

class DjmaPublicationImporterTest < ActiveSupport::TestCase
  setup do
    create_case_dependencies
    default_office.update!(oab_registration: "18727", oab_state: "MA")
    @client = create_client(full_name: "Cliente DJMA")
    @legal_case = create_full_legal_case(
      client: @client,
      external_number: "0800466-41.2025.8.10.0030"
    )
  end

  test "imports matched daily journal publications and links to legal case" do
    source = fake_source(<<~TEXT)
      PROCEDIMENTO DO JUIZADO ESPECIAL CIVEL
      MANDADO DE INTIMACAO PROCESSO CIVEL No 0800466-41.2025.8.10.0030
      INTIMADO: Advogado(s) do reclamado: WASHINGTON LUIZ (OAB 18727-MA)
      FINALIDADE: Intimar para tomar ciencia da sentenca.
    TEXT

    result = Integrations::Djma::PublicationImporter.new(
      office: default_office,
      published_on: Date.new(2026, 1, 22),
      source: source
    ).call

    assert_equal({ imported: 1, skipped: 0 }, result)
    publication = LegalPublication.last
    assert_equal "djma", publication.source
    assert_equal "djma_publication", publication.event_name
    assert_equal @legal_case, publication.legal_case
    assert_equal "Diário de Justiça do Estado do Maranhão (DJMA)", publication.journal_name
    assert_equal Date.new(2026, 1, 22), publication.published_at.to_date
    assert_includes publication.content, "FINALIDADE"
  end

  test "does not duplicate already imported publication" do
    source = fake_source("Processo 0800466-41.2025.8.10.0030 OAB 18727-MA Intimacao.")
    importer = Integrations::Djma::PublicationImporter.new(
      office: default_office,
      published_on: Date.new(2026, 1, 22),
      source: source
    )

    assert_difference -> { LegalPublication.count }, 1 do
      importer.call
    end
    assert_no_difference -> { LegalPublication.count } do
      importer.call
    end
  end

  private

  def fake_source(text)
    Struct.new(:text, :url).new(text, "https://tjma.example/djma-2026-01-22.pdf")
  end
end
