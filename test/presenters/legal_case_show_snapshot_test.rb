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

  test "serializes a localized label for the recorded outcome date" do
    @legal_case.update!(outcome: "won", outcome_date: Date.new(2026, 7, 30))

    snapshot = LegalCaseShowSnapshot.new(legal_case: @legal_case).as_json

    assert_equal "2026-07-30", snapshot.fetch(:case).fetch(:outcome_date)
    assert_equal "30/07/2026", snapshot.fetch(:case).fetch(:outcome_date_label)
  end

  test "serializes the populated financial contract with its existing first due date" do
    contract = FinancialContract.create!(
      office: default_office,
      legal_case: @legal_case,
      fixed_amount: 1_200,
      installment_count: 2,
      total_amount: 1_200
    )
    FinancialContracts::InstallmentBuilder.call(
      contract: contract,
      count: 2,
      first_due_date: Date.new(2026, 11, 12)
    )

    snapshot = LegalCaseShowSnapshot.new(legal_case: @legal_case).as_json

    assert_equal "2026-11-12", snapshot.dig(:financial_contract, :first_due_date)
    assert_equal [ "2026-11-12", "2026-12-12" ], snapshot.fetch(:installments).pluck(:due_date)
  end

  test "serializes the recorded outcome metadata and administrator outcome action" do
    administrator = User.create!(
      office: default_office,
      name: "Marina Administradora",
      email: "marina-#{SecureRandom.hex(4)}@example.com",
      role: "admin",
      password: "segredo123",
      password_confirmation: "segredo123"
    )
    confirmed_at = Time.zone.local(2026, 7, 31, 12, 15)
    @legal_case.update!(
      outcome: "won",
      outcome_date: Date.new(2026, 7, 30),
      outcome_notes: "Sentença favorável transitada em julgado.",
      outcome_confirmed_by: administrator,
      outcome_confirmed_at: confirmed_at
    )

    snapshot = LegalCaseShowSnapshot.new(legal_case: @legal_case, current_user: administrator).as_json

    assert_equal "won", snapshot.dig(:case, :outcome)
    assert_equal "Ganho", snapshot.dig(:case, :outcome_label)
    assert_equal "Sentença favorável transitada em julgado.", snapshot.dig(:case, :outcome_notes)
    assert_equal confirmed_at.iso8601, snapshot.dig(:case, :outcome_confirmed_at)
    assert_equal "31/07/2026", snapshot.dig(:case, :outcome_confirmed_at_label)
    assert_equal administrator.name, snapshot.dig(:case, :outcome_confirmed_by_name)
    assert_equal true, snapshot.dig(:permissions, :can_record_outcome)
    assert_equal(
      { path: record_outcome_legal_case_path(@legal_case), method: "patch" },
      snapshot.dig(:actions, :record_outcome)
    )
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

  test "serializes deterministic process intelligence" do
    @legal_case.update!(next_action: "", next_deadline_on: Date.current - 1.day)
    Deadline.create!(
      legal_case: @legal_case,
      title: "Prazo vencido",
      due_date: Date.current - 1.day,
      status: "pending",
      priority: "high"
    )
    Task.create!(
      legal_case: @legal_case,
      title: "Tarefa pendente",
      due_date: Date.current + 1.day,
      status: "pending"
    )
    LegalPublication.create!(
      office: default_office,
      legal_case: @legal_case,
      source: "djma",
      external_id: "intelligence-publication-#{SecureRandom.hex(4)}",
      event_name: "djma_publication",
      title: "Publicação pendente",
      content: "Intimação disponibilizada"
    )

    intelligence = LegalCaseShowSnapshot.new(legal_case: @legal_case).as_json.fetch(:intelligence)

    assert_match @legal_case.internal_number, intelligence.fetch(:summary)
    assert_equal "critical", intelligence.fetch(:status)
    assert_equal "Regularizar prazo vencido", intelligence.dig(:suggested_action, :title)
    assert_includes intelligence.fetch(:attention_points).pluck(:title), "Prazo vencido"
    assert_includes intelligence.fetch(:attention_points).pluck(:title), "Publicações não lidas"
    assert_operator intelligence.dig(:metrics, :overdue_deadlines_count), :>=, 1
    assert_operator intelligence.dig(:metrics, :pending_tasks_count), :>=, 1
    assert_equal 1, intelligence.dig(:metrics, :unread_publications_count)
  end
end
