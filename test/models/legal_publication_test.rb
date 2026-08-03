require "test_helper"

class LegalPublicationTest < ActiveSupport::TestCase
  setup do
    create_case_dependencies
    @client = create_client(full_name: "Cliente Publicacao")
    @legal_case = create_full_legal_case(
      client: @client,
      external_number: "0000001-00.2026.8.10.0001"
    )
  end

  test "requires unique external id by source" do
    LegalPublication.create!(
      office: default_office,
      source: "escavador",
      external_id: "pub-1",
      event_name: "diario_movimentacao_nova",
      content: "Publicacao original"
    )

    duplicate = LegalPublication.new(
      office: default_office,
      source: "escavador",
      external_id: "pub-1",
      event_name: "diario_movimentacao_nova",
      content: "Publicacao duplicada"
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:external_id], "já está em uso"
  end

  test "links to a legal case by normalized process number in the same office" do
    publication = LegalPublication.new(
      office: default_office,
      source: "escavador",
      external_id: "pub-link",
      event_name: "diario_movimentacao_nova",
      process_number: "00000010020268100001",
      content: "Publicacao do processo"
    )

    publication.link_matching_legal_case

    assert_equal @legal_case, publication.legal_case
  end

  test "does not link to a case from another office" do
    other_office = Office.create!(
      name: "Outro Escritório",
      slug: "outro-escritorio",
      default_phase: "atendimento_inicial",
      default_status: "em_analise",
      default_priority: "medium"
    )
    other_client = create_client(full_name: "Outro Cliente", office: other_office)
    other_case = create_legal_case(
      internal_number: "PROC-OTHER-#{SecureRandom.hex(3)}",
      client: other_client,
      office: other_office,
      legal_area: @test_legal_area,
      process_type: @test_process_type,
      district: @test_district,
      court: @test_court,
      external_number: "0000002-00.2026.8.10.0001"
    )

    publication = LegalPublication.new(
      office: default_office,
      source: "escavador",
      external_id: "pub-other-office",
      event_name: "diario_movimentacao_nova",
      process_number: other_case.external_number,
      content: "Publicacao de outro escritorio"
    )

    publication.link_matching_legal_case

    assert_nil publication.legal_case
  end

  test "tracks read and linked scopes" do
    unread_linked = LegalPublication.create!(
      office: default_office,
      legal_case: @legal_case,
      source: "escavador",
      external_id: "pub-unread-linked",
      event_name: "diario_movimentacao_nova",
      content: "Publicacao vinculada"
    )
    read_unlinked = LegalPublication.create!(
      office: default_office,
      source: "escavador",
      external_id: "pub-read-unlinked",
      event_name: "diario_movimentacao_nova",
      content: "Publicacao lida",
      read_at: Time.current
    )

    assert_includes LegalPublication.unread, unread_linked
    assert_not_includes LegalPublication.unread, read_unlinked
    assert_includes LegalPublication.read, read_unlinked
    assert_includes LegalPublication.linked, unread_linked
    assert_includes LegalPublication.unlinked, read_unlinked
  end
end
