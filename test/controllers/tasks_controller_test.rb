require "test_helper"

class TasksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @legal_case = create_full_legal_case(
      internal_number: "PROC-TASK-001",
      responsible_name: "Advogado da carteira",
      next_action: "Conferir despacho inicial"
    )

    @task = Task.create!(
      legal_case: @legal_case,
      title: "Tarefa teste",
      status: "pending",
      priority: "medium",
      due_date: Date.current + 3.days,
      responsible_name: "Assistente"
    )
  end

  test "should get index" do
    get tasks_url
    assert_response :success
  end

  test "should get new" do
    get new_task_url
    assert_response :success
  end

  test "should create task" do
    assert_difference("Task.count") do
      post tasks_url, params: { task: {
        legal_case_id: @legal_case.id,
        title: "Nova tarefa",
        status: "in_progress",
        priority: "high",
        due_date: Date.current + 2.days,
        responsible_name: "Equipe"
      } }
    end

    assert_redirected_to task_url(Task.last)
  end

  test "should show task" do
    get task_url(@task)
    assert_response :success
  end

  test "should get edit" do
    get edit_task_url(@task)
    assert_response :success
  end

  test "should update task" do
    patch task_url(@task), params: { task: { title: "Tarefa atualizada", status: "completed" } }
    assert_redirected_to task_url(@task)
  end

  test "should destroy task" do
    assert_difference("Task.count", -1) do
      delete task_url(@task)
    end

    assert_redirected_to tasks_url
  end
end
