require "test_helper"

class TasksControllerTest < ActionDispatch::IntegrationTest
  setup do
    client = Client.create!(full_name: "Cliente Task", cpf_cnpj: "44444444444")
    district = District.create!(name: "Bacabal/MA")
    court = Court.create!(name: "3a Vara Civel", district: district)
    legal_area = LegalArea.create!(name: "Trabalhista", justice_branch: "labor")
    process_type = ProcessType.create!(name: "Reclamacao Trabalhista", legal_area: legal_area)

    @legal_case = LegalCase.create!(
      internal_number: "PROC-TASK-001",
      phase: "analise_juridica",
      status: "ativo",
      responsible_name: "Advogado da carteira",
      next_action: "Conferir despacho inicial",
      next_deadline_on: Date.current + 4.days,
      client: client,
      legal_area_id: legal_area.id,
      process_type_id: process_type.id,
      district_id: district.id,
      court_id: court.id
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
