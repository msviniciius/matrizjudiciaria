# frozen_string_literal: true

puts "==> Iniciando carga de processos válidos para demonstração..."

def ensure_phase(code, name, order)
  ProcessPhase.find_or_create_by!(code: code) do |phase|
    phase.name = name
    phase.order = order
    phase.active = true
  end
end

def upsert_case(internal_number, attrs)
  legal_case = LegalCase.find_or_initialize_by(internal_number: internal_number)
  legal_case.assign_attributes(attrs)
  legal_case.save!
  legal_case
end

ensure_phase("analise_juridica", "Análise Jurídica", 2)
ensure_phase("judicial", "Judicial", 4)

movement_type = MovementType.find_or_create_by!(code: "movimentacao_judicial") do |record|
  record.name = "Movimentação Judicial"
  record.active = true
end

legal_area = LegalArea.find_or_create_by!(justice_branch: "Justiça Federal", name: "Previdenciário")
process_type = ProcessType.find_or_create_by!(legal_area: legal_area, name: "Ação Previdenciária")
district = District.find_or_create_by!(name: "São Luís/MA")
court = Court.find_or_create_by!(name: "1ª Vara Federal de São Luís", district: district)

client = Client.find_or_create_by!(cpf_cnpj: "12345678909") do |record|
  record.full_name = "Cliente Demo Processual"
  record.phone = "(98) 98888-0000"
  record.whatsapp = "(98) 98888-0000"
  record.email = "cliente.demo@matrizjuridica.com"
  record.address = "Rua de Teste, 123"
  record.city = "São Luís"
  record.state = "MA"
end

base_attrs = {
  client: client,
  legal_area: legal_area,
  process_type: process_type,
  district: district,
  court: court,
  entry_date: Date.current - 15.days,
  protocol_date: Date.current - 12.days,
  subarea: "Benefícios Previdenciários",
  main_subject: "Concessão de benefício",
  phase: "judicial",
  status: "ativo",
  responsible_name: "Dra. Ana Martins",
  support_team: "Equipe Previdenciário",
  opposing_party: "INSS",
  claim_value: 35_000,
  priority: "high",
  strategic_notes: "Carga automática para validação do fluxo operacional.",
  tem_pericia: true,
  observacao_geral_pericia: "Perícias criadas automaticamente para validação."
}

cases_data = [
  {
    internal_number: "PROC-DEMO-HOJE-001",
    external_number: "0000001-00.2026.4.01.3700",
    next_action: "Protocolar manifestação final",
    next_deadline_on: Date.current
  },
  {
    internal_number: "PROC-DEMO-48H-001",
    external_number: "0000002-00.2026.4.01.3700",
    next_action: "Revisar petição de cumprimento",
    next_deadline_on: Date.current + 1.day
  },
  {
    internal_number: "PROC-DEMO-ATRAS-001",
    external_number: "0000003-00.2026.4.01.3700",
    next_action: "Regularizar prazo vencido",
    next_deadline_on: Date.current - 1.day
  },
  {
    internal_number: "PROC-DEMO-SEM-ACAO-001",
    external_number: "0000004-00.2026.4.01.3700",
    next_action: "Providência temporária",
    next_deadline_on: Date.current + 3.days
  }
]

created_cases = cases_data.map do |entry|
  attrs = base_attrs.merge(
    external_number: entry[:external_number],
    next_action: entry[:next_action],
    next_deadline_on: entry[:next_deadline_on]
  )

  upsert_case(entry[:internal_number], attrs)
end

created_cases.each do |legal_case|
  due_date = legal_case.next_deadline_on || Date.current + 7.days
  phase_record = ProcessPhase.find_by!(code: legal_case.phase)

  deadline = Deadline.find_or_initialize_by(
    legal_case: legal_case,
    title: "Prazo operacional #{legal_case.internal_number}"
  )
  deadline.assign_attributes(
    deadline_type: "judicial",
    start_date: Date.current - 2.days,
    due_date: due_date,
    status: "pending",
    priority: "high",
    responsible_name: legal_case.responsible_name
  )
  deadline.save!

  task = Task.find_or_initialize_by(
    legal_case: legal_case,
    title: "Tarefa operacional #{legal_case.internal_number}"
  )
  task.assign_attributes(
    description: "Executar providência interna vinculada ao processo.",
    status: "pending",
    priority: "high",
    due_date: due_date,
    responsible_name: legal_case.responsible_name
  )
  task.save!

  exam = ProcessExam.find_or_initialize_by(
    legal_case: legal_case,
    exam_nature: "medica",
    exam_scope: "judicial"
  )
  exam.assign_attributes(
    status: "designada",
    scheduled_at: Date.current + 10.days,
    location: "Fórum Previdenciário de São Luís",
    expert_name: "Perito Judicial Demo",
    notes: "Perícia para homologação de benefício."
  )
  exam.save!

  movement = ProcessMovement.find_or_initialize_by(
    process: legal_case,
    display_title: "Andamento inicial #{legal_case.internal_number}"
  )
  movement.assign_attributes(
    phase: phase_record,
    movement_type: movement_type,
    event_date: Time.current,
    complementary_description: "Revisar documentos e preparar próxima medida.",
    nature: "fato_processual",
    impact: "exige_providencia_imediata",
    origin: "manual",
    active: true
  )
  movement.save!
end

sem_acao_case = LegalCase.find_by(internal_number: "PROC-DEMO-SEM-ACAO-001")
sem_acao_case.update_column(:next_action, nil) if sem_acao_case.present?

puts "==> Carga finalizada com sucesso."
puts "Processos criados/atualizados:"
created_cases.each do |legal_case|
  puts " - #{legal_case.internal_number} | prazo: #{legal_case.next_deadline_on || '-'} | responsável: #{legal_case.responsible_name}"
end
puts "Fila sem próxima providência preparada: PROC-DEMO-SEM-ACAO-001"
