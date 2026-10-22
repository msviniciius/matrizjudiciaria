require "test_helper"

class SuspensaoTest < ActiveSupport::TestCase
  test "exige inicio, fim e descricao" do
    suspensao = Suspensao.new

    assert_not suspensao.valid?
    assert_includes suspensao.errors[:inicio], "não pode ficar em branco"
    assert_includes suspensao.errors[:fim], "não pode ficar em branco"
    assert_includes suspensao.errors[:descricao], "não pode ficar em branco"
  end

  test "rejeita intervalo em que o fim vem antes do inicio" do
    suspensao = Suspensao.new(
      inicio: Date.new(2026, 12, 20),
      fim: Date.new(2026, 12, 19),
      descricao: "Recesso forense"
    )

    assert_not suspensao.valid?
    assert suspensao.errors[:fim].any?
  end

  test "aceita intervalo local ou global" do
    global = Suspensao.new(
      inicio: Date.new(2026, 12, 20),
      fim: Date.new(2027, 1, 20),
      descricao: "Recesso forense"
    )
    local = Suspensao.new(
      inicio: Date.new(2026, 11, 2),
      fim: Date.new(2026, 11, 3),
      descricao: "Suspensão do escritório",
      office: default_office
    )

    assert_predicate global, :valid?
    assert_predicate local, :valid?
  end
end
