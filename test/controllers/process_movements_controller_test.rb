require "test_helper"

class ProcessMovementsControllerTest < ActionDispatch::IntegrationTest
  setup do
    create_case_dependencies
    @client = create_client(full_name: "Cliente Andamentos")
    @legal_case = create_full_legal_case(client: @client, internal_number: "PROC-MOV-CTRL-001")
    @phase = ProcessPhase.find_or_create_by!(code: "mov-controller-phase") { |record| record.name = "Fase Controller"; record.order = 11 }
    @movement_type = MovementType.find_or_create_by!(code: "mov-controller-type") { |record| record.name = "Tipo Controller" }
    @movement = ProcessMovement.create!(
      process: @legal_case,
      phase: @phase,
      movement_type: @movement_type,
      event_date: Time.current,
      display_title: "Andamento Controller",
      nature: "fato_processual",
      impact: "sem_impacto_de_fase",
      origin: "manual",
      administrative_situation: "em_analise"
    )
  end

  test "index mounts the React process movements listing" do
    get process_movements_url

    assert_response :success
    assert_select "#react-process-movements-root"
    assert_select "script[src*='process_movements']"
    assert_select "script[src*='process_movement_show']", count: 0
  end

  test "show mounts the React process movement detail" do
    get process_movement_url(@movement)

    assert_response :success
    assert_select "#react-process-movement-show-root"
    assert_select "script[src*='process_movement_show']"
  end

  test "index JSON exposes process movements snapshot with reports" do
    get process_movements_url(format: :json), params: { q: "Controller" }

    assert_response :success
    body = response.parsed_body
    assert_equal 1, body.dig("meta", "total_count")
    assert_equal "Controller", body.dig("filters", "q")
    assert_equal process_movements_path, body.dig("actions", "index")
    assert_equal new_process_movement_path, body.dig("actions", "new")
    assert_includes body.dig("reports", "por_fase", "entries").map { |entry| entry.fetch("label") }, @phase.name

    movement = body.fetch("process_movements").sole
    assert_equal @movement.id, movement.fetch("id")
    assert_equal "PROC-MOV-CTRL-001", movement.fetch("process_number")
    assert_equal "Cliente Andamentos", movement.fetch("client_name")
    assert_equal process_movement_path(@movement), movement.fetch("path")
  end

  test "show JSON exposes process movement detail snapshot" do
    get process_movement_url(@movement, format: :json)

    assert_response :success
    body = response.parsed_body
    assert_equal @movement.id, body.dig("movement", "id")
    assert_equal "Andamento Controller", body.dig("movement", "display_title")
    assert_equal "PROC-MOV-CTRL-001", body.dig("legal_case", "internal_number")
    assert_equal process_movements_path, body.dig("actions", "index")
    assert_equal edit_process_movement_path(@movement), body.dig("actions", "edit")
    assert_equal process_movement_path(@movement), body.dig("actions", "delete")
    assert_equal "create", body.fetch("audits").first.fetch("action")
  end
end
