require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    @office = default_office
    @unit = Unit.create!(office: @office, name: "Contencioso")
    @other_unit = Unit.create!(office: @office, name: "Consultivo")
    @admin = User.create!(
      office: @office,
      name: "Admin Dashboard",
      email: "admin-dashboard@example.com",
      role: "admin",
      password: "segredo123",
      password_confirmation: "segredo123"
    )
    sign_in_and_select(@unit)
  end

  test "loads the React dashboard entrypoint on the panel route" do
    get painel_path

    assert_response :success
    assert_select "script[src*='dashboard']"
  end

  test "returns the dashboard snapshot as JSON" do
    get painel_path(format: :json)

    assert_response :success
    assert_includes response.parsed_body, "kpis"
    assert_includes response.parsed_body, "critical_queues"
  end

  test "returns no dashboard data when no unit is active outside all-units mode" do
    create_full_legal_case(unit: @unit, responsible_name: "", external_number: "0000001-00.2026.8.10.0001")
    post login_path, params: { email: @admin.email, password: "segredo123" }

    get painel_path(format: :json)

    assert_response :success
    assert_nil response.parsed_body.dig("meta", "unit_name")
    assert_equal 0, response.parsed_body.dig("meta", "syncable_count")
    assert_empty response.parsed_body.dig("critical_queues", "without_responsible")
    assert_empty response.parsed_body.dig("distribution", "phase")
  end

  test "returns only the active unit in the dashboard JSON" do
    create_full_legal_case(unit: @unit, responsible_name: "")
    create_full_legal_case(unit: @other_unit, responsible_name: "")

    get painel_path(format: :json)

    assert_response :success
    assert_equal @unit.name, response.parsed_body.dig("meta", "unit_name")
    assert_equal 1, response.parsed_body.dig("critical_queues", "without_responsible").size
    assert_equal 1, response.parsed_body.dig("distribution", "phase").sum { |item| item.fetch("count") }
  end

  test "mounts the React application in the dashboard content area" do
    get painel_path

    assert_select "#react-dashboard-root"
  end

  test "shows imported movements and unread publications in navbar notifications" do
    legal_case = create_full_legal_case(
      unit: @unit,
      internal_number: "PROC-NOTIF-001",
      external_number: "0000001-00.2026.8.10.0001"
    )
    imported_event = CaseEvent.create!(
      legal_case: legal_case,
      description: "Movimentação importada do tribunal",
      entry_kind: "andamento",
      event_date: Time.current,
      pje_external_id: "navbar-event-#{SecureRandom.hex(4)}",
      source_tribunal: "TJMA"
    )
    legal_case.update_column(:last_viewed_events_at, imported_event.created_at - 1.minute)
    LegalPublication.create!(
      office: @office,
      legal_case: legal_case,
      source: "djma",
      external_id: "navbar-publication-#{SecureRandom.hex(4)}",
      event_name: "djma_publication",
      title: "Publicação nova no DJMA",
      content: "Intimação disponibilizada no diário"
    )

    get painel_path

    assert_response :success
    assert_select ".navbar-notifications__badge" do |badges|
      assert_operator badges.first.text.to_i, :>=, 2
    end
    assert_select ".navbar-notifications__title", text: "Andamentos"
    assert_select ".navbar-notifications__item-link[href='#{legal_case_path(legal_case)}']" do
      assert_select "strong", text: legal_case.internal_number
      assert_select "span", text: /Movimentação importada do tribunal/
    end
    assert_select ".navbar-notifications__title", text: "Publicações"
    assert_select ".navbar-notifications__item-link[href='#{legal_publications_path(status: "unread")}']" do
      assert_select "strong", text: "Publicação nova no DJMA"
    end
  end

  test "updates a responsible person through JSON" do
    legal_case = create_full_legal_case(unit: @unit, responsible_name: "")

    patch quick_update_case_responsible_path(legal_case, format: :json), params: { responsible_name: "Marina" }, as: :json

    assert_response :success
    assert_equal "Responsável do processo atualizado.", response.parsed_body.fetch("message")
    assert_equal "Marina", legal_case.reload.responsible_name
  end

  test "returns a JSON validation error for a blank responsible person" do
    legal_case = create_full_legal_case(unit: @unit, responsible_name: "")

    patch quick_update_case_responsible_path(legal_case, format: :json), params: { responsible_name: "" }, as: :json

    assert_response :unprocessable_content
    assert_equal "Informe o responsável para atualizar o processo.", response.parsed_body.fetch("error")
  end

  test "does not update the responsible person of a case from another unit" do
    legal_case = create_full_legal_case(unit: @other_unit, responsible_name: "Outra pessoa")

    patch quick_update_case_responsible_path(legal_case, format: :json), params: { responsible_name: "Marina" }, as: :json

    assert_response :not_found
    assert_equal "Outra pessoa", legal_case.reload.responsible_name
  end

  test "does not update the next action of a case from another unit" do
    legal_case = create_full_legal_case(unit: @other_unit, next_action: "Providência original")

    patch quick_update_case_next_action_path(legal_case, format: :json), params: { next_action: "Nova providência" }, as: :json

    assert_response :not_found
    assert_equal "Providência original", legal_case.reload.next_action
  end

  test "does not update a deadline from another unit" do
    legal_case = create_full_legal_case(unit: @other_unit)
    deadline = Deadline.create!(
      legal_case: legal_case,
      title: "Prazo externo",
      due_date: Date.current - 1.day,
      status: "pending",
      delay_reason: ""
    )

    patch quick_update_deadline_reason_path(deadline, format: :json), params: { delay_reason: "Justificativa indevida" }, as: :json

    assert_response :not_found
    assert_equal "", deadline.reload.delay_reason
  end

  test "does not update a task from another unit" do
    legal_case = create_full_legal_case(unit: @other_unit)
    task = Task.create!(
      legal_case: legal_case,
      title: "Tarefa externa",
      status: "pending",
      responsible_name: "Outra pessoa"
    )

    patch quick_update_task_responsible_path(task, format: :json), params: { responsible_name: "Marina" }, as: :json

    assert_response :not_found
    assert_equal "Outra pessoa", task.reload.responsible_name
  end

  test "enqueues synchronization only for syncable cases in the active unit" do
    @office.update!(enabled_tribunals: [ "tjma" ])
    selected_case = create_full_legal_case(
      unit: @unit,
      external_number: "0000001-00.2026.8.10.0001"
    )
    create_full_legal_case(
      unit: @other_unit,
      external_number: "0000002-00.2026.8.10.0001"
    )

    assert_enqueued_with(
      job: Pje::Ma::ImportCaseEventsJob,
      args: [ { office_id: @office.id, legal_case_ids: [ selected_case.id ], limit: 1 } ]
    ) do
      post sync_all_cases_path(format: :json), as: :json
    end

    assert_response :accepted
    assert_includes response.parsed_body.fetch("message"), "1 processo(s)"
  end

  private

  def sign_in_and_select(unit)
    post login_path, params: { email: @admin.email, password: "segredo123" }
    post unit_session_path, params: { unit_id: unit.id }
  end
end
