require "test_helper"

class ProcessMovementTest < ActiveSupport::TestCase
  setup do
    @client = Client.create!(full_name: "Cliente PM", cpf_cnpj: "99999999999")
    @district = District.create!(name: "Comarca PM")
    @court = Court.create!(name: "Vara PM", district: @district)
    @legal_area = LegalArea.create!(name: "Previdenciário", justice_branch: "federal")
    @process_type = ProcessType.create!(name: "Ação Previdenciária", legal_area: @legal_area)

    @phase_judicial = ProcessPhase.create!(code: "judicial", name: "Judicial", order: 1)
    @phase_recurso = ProcessPhase.create!(code: "recurso", name: "Recurso", order: 2)

    @movement_type = MovementType.create!(code: "movimentacao_judicial", name: "Movimentação Judicial")
    @movement_type_exam = MovementType.create!(code: "pericia_designada", name: "Perícia Designada")

    @legal_case = LegalCase.create!(
      internal_number: "PROC-PM-001",
      external_number: "0000001-00.2026.8.10.0001",
      entry_date: Date.current,
      protocol_date: Date.current,
      subarea: "Subárea",
      main_subject: "Assunto",
      phase: "judicial",
      status: "ativo",
      responsible_name: "Advogado PM",
      next_action: "Preparar petição complementar",
      next_deadline_on: Date.current + 4.days,
      claim_value: 1000,
      priority: "medium",
      client: @client,
      legal_area: @legal_area,
      process_type: @process_type,
      district: @district,
      court: @court,
      tem_pericia: true
    )

    @exam = ProcessExam.create!(
      legal_case: @legal_case,
      exam_nature: "medica",
      exam_scope: "judicial",
      status: "nao_designada",
      scheduled_at: 3.days.from_now
    )
  end

  test "andamento que muda fase" do
    movement = ProcessMovement.create!(
      process: @legal_case,
      phase: @phase_judicial,
      next_phase: @phase_recurso,
      movement_type: @movement_type,
      event_date: Time.current,
      display_title: "Recurso interposto",
      nature: "fato_processual",
      impact: "altera_fase",
      origin: "manual",
      updates_phase: true
    )

    assert movement.persisted?
    assert_equal "recurso", @legal_case.reload.phase
  end

  test "andamento que gera tarefa" do
    assert_difference "Task.count", 1 do
      ProcessMovement.create!(
        process: @legal_case,
        phase: @phase_judicial,
        movement_type: @movement_type,
        event_date: Time.current,
        display_title: "Providência urgente",
        nature: "fato_processual",
        impact: "exige_providencia_imediata",
        origin: "manual",
        creates_task: true,
        administrative_situation: "em_analise"
      )
    end
  end

  test "andamento que gera prazo" do
    assert_difference "Deadline.count", 1 do
      ProcessMovement.create!(
        process: @legal_case,
        phase: @phase_judicial,
        movement_type: @movement_type,
        event_date: Time.current,
        display_title: "Abrir prazo interno",
        nature: "fato_processual",
        impact: "sem_impacto_de_fase",
        origin: "manual",
        creates_deadline: true,
        administrative_situation: "em_analise"
      )
    end
  end

  test "andamento com pericia atualiza status da pericia" do
    ProcessMovement.create!(
      process: @legal_case,
      phase: @phase_judicial,
      movement_type: @movement_type_exam,
      exam: @exam,
      event_date: Time.current,
      display_title: "Perícia designada",
      nature: "fato_processual",
      impact: "sem_impacto_de_fase",
      origin: "manual"
    )

    assert_equal "designada", @exam.reload.status
  end

  test "atualizacao de snapshot" do
    ProcessMovement.create!(
      process: @legal_case,
      phase: @phase_judicial,
      movement_type: @movement_type,
      event_date: Time.current,
      display_title: "Exigência administrativa",
      complementary_description: "Cumprir exigência em 5 dias",
      nature: "fato_administrativo",
      impact: "exige_providencia_imediata",
      origin: "administrativo",
      administrative_situation: "em_exigencia"
    )

    process = @legal_case.reload
    assert_equal "Exigência administrativa", process.last_movement
    assert_equal "aguardando_providencia_escritorio", process.status
    assert_includes process.next_action, "Cumprir exigência"
  end

  test "edicao e exclusao geram auditoria" do
    movement = ProcessMovement.create!(
      process: @legal_case,
      phase: @phase_judicial,
      movement_type: @movement_type,
      event_date: Time.current,
      display_title: "Movimento inicial",
      nature: "fato_administrativo",
      impact: "sem_impacto_de_fase",
      origin: "manual",
      administrative_situation: "em_analise"
    )

    assert ProcessMovementAudit.where(process_movement: movement, action: "create").exists?

    movement.update!(display_title: "Movimento alterado")
    assert ProcessMovementAudit.where(process_movement: movement, action: "update").exists?

    movement.update!(active: false, manual_override: true, exception_authorized: true, override_reason: "Exclusão lógica")
    assert ProcessMovementAudit.where(process_movement: movement, action: "update").count >= 2
  end

  test "falha de automacao registra auditoria" do
    original = Task.method(:find_or_create_by!)

    Task.define_singleton_method(:find_or_create_by!) do |*args, **kwargs, &block|
      raise StandardError, "Falha simulada"
    end

    movement = ProcessMovement.create!(
            process: @legal_case,
            phase: @phase_judicial,
            movement_type: @movement_type,
      event_date: Time.current,
      display_title: "Falha de automação",
      nature: "fato_administrativo",
      impact: "sem_impacto_de_fase",
      origin: "manual",
      creates_task: true,
      administrative_situation: "em_analise"
    )

    assert ProcessMovementAudit.where(process_movement: movement, action: "automation_failure").exists?
  ensure
    Task.define_singleton_method(:find_or_create_by!, original)
  end
end
