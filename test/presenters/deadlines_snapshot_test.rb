require "test_helper"

class DeadlinesSnapshotTest < ActiveSupport::TestCase
  include Rails.application.routes.url_helpers

  test "serializes deadline listing, filters and options" do
    legal_case = create_full_legal_case(internal_number: "PROC-DEAD-SNAP-001")
    deadline = Deadline.create!(
      legal_case: legal_case,
      title: "Prazo snapshot",
      deadline_type: "judicial",
      due_date: Date.current,
      status: "pending",
      priority: "medium",
      responsible_name: "Marina"
    )

    snapshot = DeadlinesSnapshot.new(
      office: default_office,
      unit: nil,
      deadlines: [ deadline ],
      filters: { q: "snapshot", due_state: "today" }
    ).as_json

    assert_equal default_office.name, snapshot.dig(:meta, :office_name)
    assert_equal 1, snapshot.dig(:meta, :total_count)
    assert_equal "snapshot", snapshot.dig(:filters, :q)
    assert_equal "today", snapshot.dig(:filters, :due_state)
    assert_includes snapshot.dig(:filter_options, :statuses).map { |entry| entry.fetch(:value) }, "pending"
    assert_equal deadlines_path, snapshot.dig(:actions, :index)
    assert_equal new_deadline_path, snapshot.dig(:actions, :new)

    entry = snapshot.fetch(:deadlines).sole
    assert_equal deadline.id, entry.fetch(:id)
    assert_equal deadline_path(deadline), entry.fetch(:path)
    assert_equal edit_deadline_path(deadline), entry.fetch(:edit_path)
    assert_equal legal_case_path(legal_case), entry.fetch(:legal_case_path)
    assert_equal "PROC-DEAD-SNAP-001", entry.fetch(:process_number)
    assert_equal "Prazo snapshot", entry.fetch(:title)
    assert_equal "today", entry.fetch(:due_state)
    assert_equal "Hoje", entry.fetch(:due_state_label)
    assert_equal "Marina", entry.fetch(:responsible_name)
    assert_equal "manual", entry.fetch(:origin)
    assert_nil entry.fetch(:legal_state)
    assert_nil entry.fetch(:science_date)
    assert_nil entry.fetch(:expediente)
  end

  test "serializes legal state, origin, science and expediente details" do
    legal_case = create_full_legal_case(internal_number: "PROC-DEAD-SNAP-LEGAL")
    expediente = legal_case.expedientes.create!(
      tipo: :intimacao,
      descricao: "Intimação para manifestação",
      data_disponibilizacao: Date.current - 2.days,
      quantidade_dias: 5,
      contagem: :uteis,
      prazo_em_dobro: false,
      origem: :pje,
      referencia_externa: "PJE-#{SecureRandom.hex(3)}"
    )
    ciencia = expediente.create_ciencia!(tipo: :expressa, data_ciencia: Date.current - 1.day)
    deadline = expediente.deadline
    deadline.update!(start_date: Date.current, due_date: Date.current + 3.days, status: :in_progress)

    entry = DeadlinesSnapshot.new(
      office: default_office,
      unit: nil,
      deadlines: [ deadline.reload ],
      filters: {}
    ).as_json.fetch(:deadlines).sole

    assert_equal "in_progress", entry.fetch(:legal_state)
    assert_equal "pje", entry.fetch(:origin)
    assert_equal "Pje", entry.fetch(:origin_label)
    assert_equal ciencia.data_ciencia.iso8601, entry.fetch(:science_date)
    assert_equal I18n.l(ciencia.data_ciencia, format: :short), entry.fetch(:science_date_label)
    assert_equal expediente.id, entry.dig(:expediente, :id)
    assert_equal "Intimação para manifestação", entry.dig(:expediente, :description)
    assert_equal "Intimacao", entry.dig(:expediente, :type_label)
  end
end
