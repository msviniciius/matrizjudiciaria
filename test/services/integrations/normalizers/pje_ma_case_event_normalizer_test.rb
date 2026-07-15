require "test_helper"

class PjeMaCaseEventNormalizerTest < ActiveSupport::TestCase
  setup do
    @office = Office.find_or_create_by!(name: "Test Office", slug: "test-office") do |o|
      o.legal_name = "Test Office Legal"
    end

    @client = Client.find_or_create_by!(full_name: "Cliente Teste", office: @office) do |c|
      c.cpf_cnpj = "12345678901"
    end

    @legal_area = LegalArea.find_or_create_by!(name: "Direito Civil", justice_branch: "estadual")
    @process_type = ProcessType.find_or_create_by!(name: "Procedimento Comum", legal_area: @legal_area)

    @legal_case = LegalCase.create!(
      office: @office,
      client: @client,
      legal_area: @legal_area,
      process_type: @process_type,
      external_number: "08004664120258100030",
      internal_number: "SEI01",
      phase: "judicial",
      status: "em_analise",
      responsible_name: "Dr. Teste",
      next_action: "Monitorar andamentos CNJ",
      next_deadline_on: Date.current + 5.days
    )

    # Criar um MovementType para testar o mapeamento por codigo CNJ
    # CNJ 1051 (Decurso de Prazo) mapeia para o codigo interno "movimentacao_judicial"
    @movement_type = MovementType.find_or_create_by!(code: "movimentacao_judicial") do |mt|
      mt.name = "Movimentação Judicial"
      mt.active = true
    end
  end

  test "normaliza movimento do CNJ para atributos do CaseEvent" do
    movimento_cnj = {
      "codigo" => 1051,
      "dataHora" => "2026-02-07T01:08:49.000Z",
      "nome" => "Decurso de Prazo",
      "orgaoJulgador" => { "codigo" => "3134", "nome" => "JUIZADO ESPECIAL" }
    }

    normalizer = Integrations::Normalizers::PjeMaCaseEventNormalizer.new(
      movement_hash: movimento_cnj,
      legal_case_id: @legal_case.id,
      numero_processo: "08004664120258100030"
    )

    attrs = normalizer.call

    assert_equal "08004664120258100030_1051_2026-02-07T01:08:49.000Z", attrs[:pje_external_id]
    assert_equal @legal_case.id, attrs[:legal_case_id]
    assert_equal "Decurso de Prazo", attrs[:description]
    assert_equal "andamento", attrs[:entry_kind]
    assert_equal @movement_type.id, attrs[:movement_type_id]
    assert_not_nil attrs[:event_date]
  end

  test "inclui complementos na descricao quando presentes" do
    movimento_cnj = {
      "codigo" => 51,
      "dataHora" => "2025-06-09T14:09:26.000Z",
      "nome" => "Conclusão",
      "complementosTabelados" => [
        { "codigo" => 3, "descricao" => "tipo_de_conclusao", "valor" => 5, "nome" => "para despacho" }
      ],
      "orgaoJulgador" => { "codigo" => "3134", "nome" => "JUIZADO ESPECIAL" }
    }

    normalizer = Integrations::Normalizers::PjeMaCaseEventNormalizer.new(
      movement_hash: movimento_cnj,
      legal_case_id: @legal_case.id,
      numero_processo: "08004664120258100030"
    )

    attrs = normalizer.call

    assert_includes attrs[:description], "Conclusão"
    assert_includes attrs[:description], "para despacho"
  end

  test "movement_type_id retorna nil quando codigo CNJ nao existe" do
    movimento_cnj = {
      "codigo" => 99999, # Codigo inexistente
      "dataHora" => "2025-06-09T14:09:26.000Z",
      "nome" => "Movimento Desconhecido",
      "orgaoJulgador" => { "codigo" => "3134", "nome" => "JUIZADO ESPECIAL" }
    }

    normalizer = Integrations::Normalizers::PjeMaCaseEventNormalizer.new(
      movement_hash: movimento_cnj,
      legal_case_id: @legal_case.id,
      numero_processo: "08004664120258100030"
    )

    attrs = normalizer.call

    assert_nil attrs[:movement_type_id]
    assert_equal "Movimento Desconhecido", attrs[:description]
  end

  test "extrai next_action para movimentos que exigem providencia" do
    movimento_cnj = {
      "codigo" => 85,
      "dataHora" => "2025-10-08T09:20:31.000Z",
      "nome" => "Intimação",
      "complementosTabelados" => [
        { "codigo" => 19, "descricao" => "prazo", "valor" => 15, "nome" => "15 dias" }
      ],
      "orgaoJulgador" => { "codigo" => "3134", "nome" => "JUIZADO ESPECIAL" }
    }

    normalizer = Integrations::Normalizers::PjeMaCaseEventNormalizer.new(
      movement_hash: movimento_cnj,
      legal_case_id: @legal_case.id,
      numero_processo: "08004664120258100030"
    )

    attrs = normalizer.call

    assert_not_nil attrs[:next_action]
    assert_includes attrs[:next_action], "intimação"
    assert_includes attrs[:next_action], "15"
  end

  test "pje_external_id e unico para cada movimento do mesmo processo" do
    mov1 = { "codigo" => 1051, "dataHora" => "2026-02-07T01:08:49.000Z", "nome" => "Decurso de Prazo" }
    mov2 = { "codigo" => 51, "dataHora" => "2025-06-09T14:09:26.000Z", "nome" => "Conclusão" }

    id1 = Integrations::Normalizers::PjeMaCaseEventNormalizer.new(
      movement_hash: mov1, legal_case_id: @legal_case.id, numero_processo: "08004664120258100030"
    ).call[:pje_external_id]

    id2 = Integrations::Normalizers::PjeMaCaseEventNormalizer.new(
      movement_hash: mov2, legal_case_id: @legal_case.id, numero_processo: "08004664120258100030"
    ).call[:pje_external_id]

    assert_not_equal id1, id2
  end

  test "nao extrai next_action para movimentos sem palavra-chave de urgencia" do
    movimento_cnj = {
      "codigo" => 26,
      "dataHora" => "2025-04-22T13:19:49.000Z",
      "nome" => "Distribuição",
      "orgaoJulgador" => { "codigo" => "3134", "nome" => "JUIZADO ESPECIAL" }
    }

    normalizer = Integrations::Normalizers::PjeMaCaseEventNormalizer.new(
      movement_hash: movimento_cnj,
      legal_case_id: @legal_case.id,
      numero_processo: "08004664120258100030"
    )

    attrs = normalizer.call

    assert_nil attrs[:next_action]
  end
end
