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
end
