require "test_helper"

class ProcessMovementsSnapshotTest < ActiveSupport::TestCase
  include Rails.application.routes.url_helpers

  test "serializes movement listing, filters and reports" do
    create_case_dependencies
    client = create_client(full_name: "Cliente Andamento")
    legal_case = create_full_legal_case(client: client, internal_number: "PROC-MOV-001", responsible_name: "Marina")
    phase = ProcessPhase.find_or_create_by!(code: "mov-snapshot-phase") { |record| record.name = "Fase Snapshot"; record.order = 10 }
    movement_type = MovementType.find_or_create_by!(code: "mov-snapshot-type") { |record| record.name = "Tipo Snapshot" }
    movement = ProcessMovement.create!(
      process: legal_case,
      phase: phase,
      movement_type: movement_type,
      event_date: Time.zone.local(2026, 7, 30, 10, 0, 0),
      display_title: "Petição juntada",
      nature: "fato_processual",
      impact: "sem_impacto_de_fase",
      origin: "manual",
      administrative_situation: "em_analise"
    )

    snapshot = ProcessMovementsSnapshot.new(
      process_movements: [ movement ],
      reports: {
        por_fase: { phase.name => 1 },
        por_tipo: { movement_type.name => 1 },
        por_natureza: { "fato_processual" => 1 },
        por_impacto: { "sem_impacto_de_fase" => 1 },
        por_origem: { "manual" => 1 }
      },
      filters: { q: "petição" },
      office: default_office
    ).as_json

    assert_equal 1, snapshot.dig(:meta, :total_count)
    assert_equal "petição", snapshot.dig(:filters, :q)
    assert_includes snapshot.dig(:filter_options, :phases).map { |entry| entry.fetch(:label) }, phase.name
    assert_equal "Por fase", snapshot.dig(:reports, :por_fase, :title)
    assert_equal "Fato processual", snapshot.dig(:reports, :por_natureza, :entries).sole.fetch(:label)

    entry = snapshot.fetch(:process_movements).sole
    assert_equal movement.id, entry.fetch(:id)
    assert_equal process_movement_path(movement), entry.fetch(:path)
    assert_equal edit_process_movement_path(movement), entry.fetch(:edit_path)
    assert_equal legal_case_path(legal_case), entry.fetch(:legal_case_path)
    assert_equal "PROC-MOV-001", entry.fetch(:process_number)
    assert_equal "Cliente Andamento", entry.fetch(:client_name)
    assert_equal "Em análise", entry.fetch(:administrative_situation_label)
  end
end
