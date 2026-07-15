require "test_helper"

class CaseEventTest < ActiveSupport::TestCase
  setup do
    @movement_type = MovementType.find_or_create_by!(code: "exigencia_administrativa") do |mt|
      mt.name = "Exigência administrativa"
      mt.active = true
    end

    @legal_case = create_full_legal_case(
      internal_number: "PROC-CE-001",
      responsible_name: "Advogado CE",
      next_action: "Monitorar processo"
    )
  end

  test "evento de andamento sem movement_type nem pje_external_id exige movement_type" do
    event = CaseEvent.new(
      legal_case: @legal_case,
      entry_kind: "andamento",
      event_date: Time.current,
      description: "Andamento sem tipo de movimento"
    )

    assert_not event.valid?
    assert_includes event.errors[:movement_type], "não pode ficar em branco"
  end

  test "evento com pje_external_id nao exige movement_type" do
    event = CaseEvent.new(
      legal_case: @legal_case,
      entry_kind: "andamento",
      event_date: Time.current,
      description: "Andamento importado do CNJ",
      pje_external_id: "08004664120258100030_1051_2026-02-07T01:08:49.000Z"
    )

    assert event.valid?
  end

  test "unifica fase pelo tipo de andamento" do
    event = CaseEvent.new(
      legal_case: @legal_case,
      entry_kind: "andamento",
      movement_type: @movement_type,
      event_date: Time.current,
      description: "Exigência recebida do órgão administrativo"
    )

    assert event.valid?
    # Mapeia exigencia_administrativa → administrativo (via MOVEMENT_TYPE_PHASE_TRANSITIONS)
    assert_equal "administrativo", event.phase_after_unified
    # Mapeia exigencia_administrativa → aguardando_providencia_escritorio (via MOVEMENT_TYPE_STATUS_TRANSITIONS)
    assert_equal "aguardando_providencia_escritorio", event.status_after_unified
  end

  test "evento sem movement_type mapeado retorna fase e status do processo" do
    other_type = MovementType.find_or_create_by!(code: "outro_tipo") do |mt|
      mt.name = "Outro Tipo"
      mt.active = true
    end

    event = CaseEvent.new(
      legal_case: @legal_case,
      entry_kind: "andamento",
      movement_type: other_type,
      event_date: Time.current,
      description: "Movimento genérico"
    )

    assert event.valid?
    # Sem mapeamento, retorna a fase/status atuais do processo
    assert_equal @legal_case.phase, event.phase_after_unified
    assert_equal @legal_case.status, event.status_after_unified
  end
end
