require "test_helper"

class LegalCaseTest < ActiveSupport::TestCase
  setup do
    @client = Client.create!(full_name: "Cliente LegalCase", cpf_cnpj: "12121212121")
    @district = District.create!(name: "Comarca LegalCase")
    @court = Court.create!(name: "Vara LegalCase", district: @district)
    @legal_area = LegalArea.create!(name: "Cível", justice_branch: "state")
    @process_type = ProcessType.create!(name: "Procedimento Comum", legal_area: @legal_area)
  end

  test "validacao operacional exige responsavel e prazo" do
    legal_case = build_case(
      responsible_name: nil,
      next_action: nil,
      next_deadline_on: nil
    )

    assert_not legal_case.valid?
    assert_includes legal_case.errors[:responsible_name], "não pode ficar em branco"
    assert_includes legal_case.errors[:next_deadline_on], "deve ser informado para o acompanhamento operacional"
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
        legal_area: @legal_area,
        process_type: @process_type,
        district: @district,
        court: @court
      }.merge(attrs)
    )
  end
end
