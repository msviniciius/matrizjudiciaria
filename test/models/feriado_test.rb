require "test_helper"

class FeriadoTest < ActiveSupport::TestCase
  test "exige data, descricao e ambito" do
    feriado = Feriado.new

    assert_not feriado.valid?
    assert_includes feriado.errors[:data], "não pode ficar em branco"
    assert_includes feriado.errors[:descricao], "não pode ficar em branco"
    assert_includes feriado.errors[:ambito], "não pode ficar em branco"
  end

  test "aceita feriado global ou vinculado a um escritorio" do
    global = Feriado.new(data: Date.new(2026, 9, 7), descricao: "Independência", ambito: :nacional)
    local = Feriado.new(data: Date.new(2026, 10, 28), descricao: "Feriado local", ambito: :municipal, office: default_office)

    assert_predicate global, :valid?
    assert_predicate local, :valid?
  end

  test "aceita apenas ambitos de calendario conhecidos" do
    feriado = Feriado.new(data: Date.current, descricao: "Data", ambito: "desconhecido")

    assert_not feriado.valid?
    assert feriado.errors[:ambito].any?
  end
end
