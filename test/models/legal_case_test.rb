require "test_helper"

class LegalCaseTest < ActiveSupport::TestCase
  setup do
    create_case_dependencies

    @client = create_client(full_name: "Cliente LegalCase", cpf_cnpj: "12121212121")
  end

  test "valida presenca de campos obrigatorios" do
    legal_case = build_case(process_type_id: nil, legal_area_id: nil)

    assert_not legal_case.valid?
    assert_includes legal_case.errors[:legal_area_id], "não pode ficar em branco"
    assert_includes legal_case.errors[:process_type_id], "não pode ficar em branco"
  end

  test "proxima providencia em branco gera alerta sem bloquear" do
    legal_case = build_case(
      next_action: nil,
      next_deadline_on: Date.current + 2.days
    )

    assert legal_case.valid?
    assert legal_case.next_action_warning?
  end

  test "caso encerrado pode ficar sem snapshot operacional" do
    legal_case = build_case(
      phase: "encerrado",
      status: "encerrado",
      responsible_name: nil,
      next_action: nil,
      next_deadline_on: nil
    )

    assert legal_case.valid?
  end

  test "health score sinaliza critico em caso vencido" do
    legal_case = build_case(
      next_action: "Executar providência urgente",
      next_deadline_on: Date.current + 1.day
    )
    legal_case.save!

    legal_case.update_columns(
      next_deadline_on: Date.yesterday,
      last_movement_at: 20.days.ago,
      next_action: ""
    )

    assert legal_case.reload.health_status_vermelho?
    assert_operator legal_case.health_score, :<, 50
    assert_includes legal_case.health_issues, "Prazo vencido"
  end

  test "persiste pericia via nested attributes no create" do
    legal_case = build_case(
      tem_pericia: true,
      process_exams_attributes: {
        "0" => {
          "exam_nature" => "medica",
          "exam_scope" => "judicial",
          "status" => "designada",
          "scheduled_at" => "2026-05-28T14:00",
          "location" => "Forum Teste",
          "expert_name" => "Perito Teste",
          "notes" => "Observacoes da pericia",
          "active" => "1"
        }
      }
    )

    assert_difference("ProcessExam.count", 1) do
      assert legal_case.save!, legal_case.errors.full_messages.join(", ")
    end

    exam = legal_case.reload.process_exams.first
    assert_equal "medica", exam.exam_nature
    assert_equal "judicial", exam.exam_scope
    assert_equal "designada", exam.status
    assert_equal "Perito Teste", exam.expert_name
  end

  private

  def build_case(attrs = {})
    LegalCase.new(
      {
        internal_number: "PROC-TEST-#{SecureRandom.hex(4).upcase}",
        phase: "analise_juridica",
        status: "em_analise",
        responsible_name: "Advogado responsável",
        next_action: "Revisar petição inicial",
        next_deadline_on: Date.current + 3.days,
        client: @client,
        office: default_office,
        legal_area: @test_legal_area,
        process_type: @test_process_type,
        district: @test_district,
        court: @test_court
      }.merge(attrs)
    )
  end
end
