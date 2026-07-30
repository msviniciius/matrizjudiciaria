require "test_helper"

class LegalCaseShowSnapshotTest < ActiveSupport::TestCase
  include Rails.application.routes.url_helpers

  setup do
    create_case_dependencies

    @legal_case = create_full_legal_case(
      internal_number: "PROC-DETAIL-001",
      external_number: "0000001-00.2026.8.10.0001",
      next_deadline_on: Date.current - 1.day,
      tem_pericia: true
    )
  end

  test "serializes the command-center detail for its case" do
    snapshot = LegalCaseShowSnapshot.new(legal_case: @legal_case).as_json

    assert_equal @legal_case.id, snapshot.fetch(:case).fetch(:id)
    assert_equal @legal_case.internal_number, snapshot.fetch(:case).fetch(:internal_number)
    assert_equal edit_legal_case_path(@legal_case), snapshot.fetch(:actions).fetch(:edit)
    assert_equal "Em análise", snapshot.fetch(:case).fetch(:status_label)
  end

  test "serializes labelled collections in the detail ordering and derived alerts" do
    earlier_deadline = Deadline.create!(
      legal_case: @legal_case,
      title: "Prazo anterior",
      due_date: Date.current + 1.day,
      status: "pending",
      priority: "medium"
    )
    later_deadline = Deadline.create!(
      legal_case: @legal_case,
      title: "Prazo posterior",
      due_date: Date.current + 3.days,
      status: "in_progress",
      priority: "high"
    )
    earlier_task = Task.create!(
      legal_case: @legal_case,
      title: "Tarefa anterior",
      due_date: Date.current + 1.day,
      status: "pending"
    )
    later_task = Task.create!(
      legal_case: @legal_case,
      title: "Tarefa posterior",
      due_date: Date.current + 3.days,
      status: "in_progress"
    )
    unscheduled_exam = ProcessExam.create!(
      legal_case: @legal_case,
      exam_nature: "medica",
      exam_scope: "judicial",
      status: "designada"
    )
    scheduled_exam = ProcessExam.create!(
      legal_case: @legal_case,
      exam_nature: "social",
      exam_scope: "administrativa",
      status: "laudo_pendente",
      scheduled_at: Date.current + 2.days
    )
    old_event = CaseEvent.create!(
      legal_case: @legal_case,
      description: "Andamento anterior",
      entry_kind: "andamento",
      event_date: 2.days.ago,
      pje_external_id: "detail-event-old-#{SecureRandom.hex(4)}"
    )
    recent_event = CaseEvent.create!(
      legal_case: @legal_case,
      description: "Andamento recente",
      entry_kind: "andamento",
      event_date: 1.day.ago,
      pje_external_id: "detail-event-recent-#{SecureRandom.hex(4)}"
    )
    @legal_case.update!(next_deadline_on: Date.current - 1.day)

    snapshot = LegalCaseShowSnapshot.new(legal_case: @legal_case).as_json

    assert_equal [ recent_event.description, old_event.description ], snapshot.fetch(:timeline).pluck(:title)
    assert_equal [ recent_event.id, old_event.id ], snapshot.fetch(:timeline).pluck(:id)
    assert_equal snapshot.fetch(:deadlines).pluck(:due_date).sort, snapshot.fetch(:deadlines).pluck(:due_date)
    assert_includes snapshot.fetch(:deadlines).pluck(:id), earlier_deadline.id
    assert_includes snapshot.fetch(:deadlines).pluck(:id), later_deadline.id
    assert_equal [ earlier_task.id, later_task.id ], snapshot.fetch(:tasks).pluck(:id)
    assert_equal [ scheduled_exam.id, unscheduled_exam.id ], snapshot.fetch(:exams).pluck(:id)
    assert_equal "Pendente", snapshot.fetch(:deadlines).first.fetch(:status_label)
    assert_equal "Médica", snapshot.fetch(:exams).last.fetch(:nature_label)
    assert snapshot.fetch(:alerts).fetch(:deadline_overdue)
    assert snapshot.fetch(:alerts).fetch(:exam_pending)
  end

  test "serializes a stable non-null id for a process movement timeline item" do
    phase = ProcessPhase.create!(
      code: "detail-phase-#{SecureRandom.hex(4)}",
      name: "Fase do detalhe",
      order: 99
    )
    movement_type = MovementType.create!(
      code: "detail-movement-#{SecureRandom.hex(4)}",
      name: "Movimento do detalhe #{SecureRandom.hex(4)}"
    )
    movement = ProcessMovement.create!(
      process: @legal_case,
      phase: phase,
      movement_type: movement_type,
      event_date: Time.current,
      display_title: "Movimento com ID estável",
      nature: "nota_interna",
      impact: "sem_impacto_de_fase",
      origin: "manual"
    )

    timeline_entry = LegalCaseShowSnapshot
      .new(legal_case: @legal_case)
      .as_json
      .fetch(:timeline)
      .find { |item| item.fetch(:source) == "process_movement" }

    assert_equal movement.id, timeline_entry.fetch(:id)
  end
end
