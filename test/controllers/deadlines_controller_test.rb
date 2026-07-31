require "test_helper"

class DeadlinesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @legal_case = create_full_legal_case(
      internal_number: "PROC-DEA-001",
      responsible_name: "Advogado da carteira",
      next_action: "Acompanhar prazo do cliente"
    )

    @deadline = Deadline.create!(
      legal_case: @legal_case,
      title: "Prazo teste",
      deadline_type: "judicial",
      start_date: Date.current,
      due_date: Date.current + 5.days,
      status: "pending",
      priority: "medium",
      responsible_name: "Advogado"
    )
  end

  test "should get index" do
    get deadlines_url
    assert_response :success
  end

  test "index mounts the React deadlines listing" do
    get deadlines_url

    assert_response :success
    assert_select "#react-deadlines-root"
    assert_select "script[src*='deadlines']"
  end

  test "index JSON exposes deadlines snapshot" do
    get deadlines_url(format: :json), params: { q: "teste", status: "pending" }

    assert_response :success
    body = response.parsed_body
    assert_equal 1, body.dig("meta", "total_count")
    assert_equal "teste", body.dig("filters", "q")
    assert_equal "pending", body.dig("filters", "status")
    assert_equal deadlines_path, body.dig("actions", "index")
    assert_equal new_deadline_path, body.dig("actions", "new")

    deadline = body.fetch("deadlines").sole
    assert_equal @deadline.id, deadline.fetch("id")
    assert_equal "PROC-DEA-001", deadline.fetch("process_number")
    assert_equal "Prazo teste", deadline.fetch("title")
    assert_equal deadline_path(@deadline), deadline.fetch("path")
    assert_equal edit_deadline_path(@deadline), deadline.fetch("edit_path")
  end

  test "index only lists deadlines from the active unit" do
    current_unit = Unit.create!(office: default_office, name: "Contencioso prazos")
    other_unit = Unit.create!(office: default_office, name: "Consultivo prazos")
    @legal_case.update!(unit: current_unit)
    other_case = create_full_legal_case(unit: other_unit)
    other_deadline = Deadline.create!(
      legal_case: other_case,
      title: "Prazo de outra unidade",
      due_date: Date.current + 1.day,
      status: "pending"
    )
    sign_in_and_select(current_unit)

    get deadlines_url(format: :json)

    assert_response :success
    deadline_titles = response.parsed_body.fetch("deadlines").map { |deadline| deadline.fetch("title") }
    assert_includes deadline_titles, @deadline.title
    assert_not_includes deadline_titles, other_deadline.title
  end

  test "should get new" do
    get new_deadline_url
    assert_response :success
  end

  test "should create deadline" do
    assert_difference("Deadline.count") do
      post deadlines_url, params: { deadline: {
        legal_case_id: @legal_case.id,
        title: "Novo prazo",
        deadline_type: "appeal",
        start_date: Date.current,
        due_date: Date.current + 7.days,
        status: "pending",
        priority: "high",
        responsible_name: "Equipe"
      } }
    end

    assert_redirected_to deadline_url(Deadline.last)
  end

  test "should show deadline" do
    get deadline_url(@deadline)
    assert_response :success
  end

  test "should get edit" do
    get edit_deadline_url(@deadline)
    assert_response :success
  end

  test "should update deadline" do
    patch deadline_url(@deadline), params: { deadline: { title: "Prazo atualizado", status: "in_progress" } }
    assert_redirected_to deadline_url(@deadline)
  end

  test "should destroy deadline" do
    assert_difference("Deadline.count", -1) do
      delete deadline_url(@deadline)
    end

    assert_redirected_to deadlines_url
  end

  private

  def sign_in_and_select(unit)
    admin = User.create!(
      office: default_office,
      name: "Admin prazos",
      email: "admin-prazos-#{SecureRandom.hex(4)}@example.com",
      role: "admin",
      password: "segredo123",
      password_confirmation: "segredo123"
    )
    post login_path, params: { email: admin.email, password: "segredo123" }
    post unit_session_path, params: { unit_id: unit.id }
  end
end
