require "test_helper"

class DeadlineTest < ActiveSupport::TestCase
  setup do
    create_case_dependencies
    @legal_case = create_full_legal_case
  end

  test "cumpre prazo juridico e registra protocolo sem perder a conclusão" do
    expediente = @legal_case.expedientes.create!(expediente_attributes)
    deadline = expediente.deadline
    completed_at = 1.day.ago

    deadline.update!(status: :completed, due_date: Date.current, completed_at: completed_at)

    deadline.cumprir!(protocolo_ref: "PJE-123")

    assert_equal "completed", deadline.status
    assert_equal completed_at.to_i, deadline.reload.completed_at.to_i
    assert_equal "PJE-123", deadline.protocolo_ref
  end

  test "cumprir prazo manual preserva o fluxo existente" do
    deadline = @legal_case.deadlines.create!(
      title: "Prazo interno",
      deadline_type: :internal,
      status: :pending,
      due_date: Date.current + 3.days
    )

    deadline.cumprir!(protocolo_ref: "IGNORADO")

    assert_equal "completed", deadline.reload.status
    assert_nil deadline.protocolo_ref
    assert_not_nil deadline.completed_at
  end

  private

  def expediente_attributes
    {
      tipo: :intimacao,
      descricao: "Intimação para manifestação",
      data_disponibilizacao: Date.current,
      quantidade_dias: 5,
      contagem: :uteis,
      prazo_em_dobro: false,
      origem: :manual
    }
  end
end
