require "test_helper"

class OfficeTest < ActiveSupport::TestCase
  test "normalizes oab registration to digits and state to uppercase" do
    office = Office.new(
      name: "Escritorio OAB",
      slug: "escritorio-oab",
      oab_registration: "OAB 18.727",
      oab_state: "ma"
    )

    assert office.valid?
    assert_equal "18727", office.oab_registration
    assert_equal "MA", office.oab_state
  end

  test "requires oab state when registration is present" do
    office = Office.new(name: "Escritorio Sem UF", slug: "escritorio-sem-uf", oab_registration: "18727")

    assert_not office.valid?
    assert_includes office.errors[:oab_state], "deve ser informada quando houver registro OAB"
  end

  test "requires oab registration when state is present" do
    office = Office.new(name: "Escritorio Sem Numero", slug: "escritorio-sem-numero", oab_state: "MA")

    assert_not office.valid?
    assert_includes office.errors[:oab_registration], "deve ser informado quando houver UF da OAB"
  end

  test "rejects invalid oab state" do
    office = Office.new(
      name: "Escritorio UF Invalida",
      slug: "escritorio-uf-invalida",
      oab_registration: "18727",
      oab_state: "XX"
    )

    assert_not office.valid?
    assert_includes office.errors[:oab_state], "deve ser uma UF valida"
  end
end
