require "test_helper"

class CienciaTest < ActiveSupport::TestCase
  setup do
    create_case_dependencies
    @legal_case = create_full_legal_case
    @expediente = @legal_case.expedientes.create!(expediente_attributes)
  end

  test "pertence a um expediente e pode registrar usuario responsavel" do
    user = User.create!(
      office: default_office,
      name: "Usuário da Ciência",
      email: "ciencia-#{SecureRandom.hex(4)}@example.com",
      role: "admin",
      password: "segredo123",
      password_confirmation: "segredo123"
    )

    ciencia = @expediente.create_ciencia!(tipo: :expressa, data_ciencia: Date.current, user: user)

    assert_equal @expediente, ciencia.expediente
    assert_equal user, ciencia.user
    assert ciencia.expressa?
  end

  test "exige tipo e data da ciencia" do
    ciencia = Ciencia.new(expediente: @expediente)

    assert_not ciencia.valid?
    assert_includes ciencia.errors[:tipo], "não pode ficar em branco"
    assert_includes ciencia.errors[:data_ciencia], "não pode ficar em branco"
    assert_equal %w[expressa tacita], Ciencia.tipos.keys
  end

  test "permite somente uma ciencia por expediente" do
    @expediente.create_ciencia!(tipo: :expressa, data_ciencia: Date.current)
    duplicate = Ciencia.new(
      expediente_id: @expediente.id,
      tipo: :tacita,
      data_ciencia: Date.current
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:expediente], "já está em uso"
  end

  test "rejeita ciencia registrada por usuario de outro escritorio" do
    other_office = Office.create!(name: "Outro Escritório Ciência", slug: "outro-escritorio-ciencia")
    other_user = User.create!(
      office: other_office,
      name: "Usuário Externo",
      email: "externo-#{SecureRandom.hex(4)}@example.com",
      role: "admin",
      password: "segredo123",
      password_confirmation: "segredo123"
    )
    ciencia = Ciencia.new(
      expediente: @expediente,
      user: other_user,
      tipo: :expressa,
      data_ciencia: Date.current
    )

    assert_not ciencia.valid?
    assert_includes ciencia.errors[:user], "deve pertencer ao mesmo escritório do processo"
  end

  test "permite ciencia sem usuario responsavel" do
    ciencia = Ciencia.new(expediente: @expediente, tipo: :tacita, data_ciencia: Date.current)

    assert ciencia.valid?, ciencia.errors.full_messages.join(", ")
  end

  private

  def expediente_attributes
    {
      tipo: :citacao,
      descricao: "Citação recebida",
      data_disponibilizacao: Date.current,
      quantidade_dias: 15,
      contagem: :corridos,
      prazo_em_dobro: true,
      origem: :manual
    }
  end
end
