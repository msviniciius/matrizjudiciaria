require "test_helper"

class PjeMaImportCaseEventsJobTest < ActiveSupport::TestCase
  setup do
    @office = Office.find_or_create_by!(name: "Test Office", slug: "test-office-import") do |o|
      o.legal_name = "Test Office Import"
    end

    @client = Client.find_or_create_by!(full_name: "Cliente Import", office: @office) do |c|
      c.cpf_cnpj = "98765432100"
    end

    @legal_area = LegalArea.find_or_create_by!(name: "Direito Civil Import", justice_branch: "estadual")
    @process_type = ProcessType.find_or_create_by!(name: "Procedimento Comum Import", legal_area: @legal_area)

    @legal_case = LegalCase.create!(
      office: @office,
      client: @client,
      legal_area: @legal_area,
      process_type: @process_type,
      external_number: "08004664120258100030",
      internal_number: "SEIIMPORT",
      phase: "judicial",
      status: "em_analise",
      responsible_name: "Dr. Import",
      next_action: "Acompanhar sincronização",
      next_deadline_on: Date.current + 5.days
    )

    @movement_type = MovementType.find_or_create_by!(code: "1051") do |mt|
      mt.name = "Decurso de Prazo"
      mt.active = true
    end
  end

  test "legal_case com external_number aparece no scope syncable" do
    assert_includes LegalCase.syncable, @legal_case
  end

  test "legal_case sem external_number nao aparece no scope syncable" do
    @legal_case.update_column(:external_number, nil)
    refute_includes LegalCase.syncable, @legal_case
  end

  test "legal_case encerrado nao aparece no scope syncable" do
    @legal_case.update_column(:phase, "encerrado")
    refute_includes LegalCase.syncable, @legal_case
  end

  test "scope needing_sync inclui casos nunca sincronizados" do
    assert_includes LegalCase.needing_sync, @legal_case
  end

  test "scope needing_sync inclui casos sincronizados ha mais de 1 hora" do
    @legal_case.update_column(:last_synced_at, 2.hours.ago)
    assert_includes LegalCase.needing_sync, @legal_case
  end

  test "scope needing_sync exclui casos sincronizados recentemente" do
    @legal_case.update_column(:last_synced_at, 30.minutes.ago)
    refute_includes LegalCase.needing_sync, @legal_case
  end

  test "sincroniza somente os IDs de processos informados" do
    other_case = LegalCase.create!(
      office: @office,
      client: @client,
      legal_area: @legal_area,
      process_type: @process_type,
      external_number: "0000002-00.2026.8.10.0001",
      internal_number: "SEIIMPORT-OTHER",
      phase: "judicial",
      status: "em_analise",
      responsible_name: "Dr. Outra Unidade",
      next_action: "Não sincronizar",
      next_deadline_on: Date.current + 5.days
    )
    fetched_numbers = []
    fake_client = Object.new
    fake_client.define_singleton_method(:with_persistent_connection) { |&block| block.call(fake_client) }
    fake_client.define_singleton_method(:fetch_case) do |external_number|
      fetched_numbers << external_number
      nil
    end

    client_singleton = Pje::Cnj::Client.singleton_class
    original_constructor = client_singleton.instance_method(:new)
    client_singleton.define_method(:new) { |*, **| fake_client }
    begin
      Pje::Ma::ImportCaseEventsJob.perform_now(
        office_id: @office.id,
        tribunal: "tjma",
        legal_case_ids: [ @legal_case.id ]
      )
    ensure
      client_singleton.define_method(:new, original_constructor)
    end

    assert_equal [ @legal_case.external_number ], fetched_numbers
    assert_nil other_case.reload.last_synced_at
  end

  test "deduplicacao rejeita case_event com mesmo pje_external_id" do
    pje_id = "08004664120258100030_1051_2026-02-07T01:08:49.000Z"

    CaseEvent.create!(
      legal_case: @legal_case,
      pje_external_id: pje_id,
      description: "Decurso de Prazo",
      entry_kind: "andamento",
      event_date: Time.current
    )

    duplicado = CaseEvent.new(
      legal_case: @legal_case,
      pje_external_id: pje_id,
      description: "Decurso de Prazo (duplicado)",
      entry_kind: "andamento",
      event_date: Time.current
    )

    assert_not duplicado.valid?
    assert_includes duplicado.errors[:pje_external_id].to_s, "taken"
  end

  test "permite case_event sem pje_external_id (criado manualmente)" do
    event = CaseEvent.create!(
      legal_case: @legal_case,
      description: "Andamento manual",
      entry_kind: "andamento",
      movement_type: @movement_type,
      event_date: Time.current
    )

    assert event.valid?
    assert_nil event.pje_external_id
  end
end
