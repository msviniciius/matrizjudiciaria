require "test_helper"

class ProcessMovementShowSnapshotTest < ActiveSupport::TestCase
  include Rails.application.routes.url_helpers

  test "serializes process movement detail, linked case, automations and audits" do
    create_case_dependencies
    client = create_client(full_name: "Cliente Detalhe")
    legal_case = create_full_legal_case(client: client, internal_number: "PROC-MOV-SHOW-001", responsible_name: "Marina")
    phase = ProcessPhase.find_or_create_by!(code: "mov-show-phase") { |record| record.name = "Fase Show"; record.order = 12 }
    next_phase = ProcessPhase.find_or_create_by!(code: "mov-show-next") { |record| record.name = "Próxima Show"; record.order = 13 }
    movement_type = MovementType.find_or_create_by!(code: "mov-show-type") { |record| record.name = "Tipo Show" }
    movement = ProcessMovement.create!(
      process: legal_case,
      phase: phase,
      next_phase: next_phase,
      movement_type: movement_type,
      event_date: Time.zone.local(2026, 7, 30, 10, 0, 0),
      display_title: "Andamento Show",
      complementary_description: "Descrição show",
      nature: "fato_processual",
      impact: "altera_fase",
      origin: "manual",
      administrative_situation: "em_analise",
      updates_phase: true,
      creates_deadline: true
    )

    snapshot = ProcessMovementShowSnapshot.new(process_movement: movement.reload).as_json

    assert_equal movement.id, snapshot.dig(:movement, :id)
    assert_equal "Andamento Show", snapshot.dig(:movement, :display_title)
    assert_equal "PROC-MOV-SHOW-001", snapshot.dig(:legal_case, :internal_number)
    assert_equal legal_case_path(legal_case), snapshot.dig(:legal_case, :path)
    assert_equal client_path(client), snapshot.dig(:legal_case, :client_path)
    assert_equal "Próxima Show", snapshot.dig(:automation, :next_phase_name)
    assert_equal true, snapshot.dig(:automation, :updates_phase)
    assert_equal true, snapshot.dig(:automation, :creates_deadline)
    assert_equal "Descrição show", snapshot.fetch(:description)
    assert_equal edit_process_movement_path(movement), snapshot.dig(:actions, :edit)
    assert_equal process_movement_path(movement), snapshot.dig(:actions, :delete)
    assert_equal "create", snapshot.fetch(:audits).first.fetch(:action)
  end
end
