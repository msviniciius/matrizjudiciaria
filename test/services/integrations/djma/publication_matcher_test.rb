require "test_helper"

class DjmaPublicationMatcherTest < ActiveSupport::TestCase
  test "finds publications by oab and extracts cnj from surrounding text" do
    text = <<~TEXT
      PROCEDIMENTO DO JUIZADO ESPECIAL CIVEL
      MANDADO DE INTIMACAO PROCESSO CIVEL No 0800466-41.2025.8.10.0030
      Promovente MARCOS VINICIUS DA CRUZ DA SILVA
      INTIMADO: Advogado(s) do reclamado: WASHINGTON LUIZ DE MIRANDA DOMINGUES TRANM (OAB 18727-MA)
      FINALIDADE: Intimar Vossa Senhoria para tomar ciencia da sentenca proferida nos autos.
    TEXT

    matches = Integrations::Djma::PublicationMatcher.new(
      text: text,
      oab_registration: "18727",
      oab_state: "MA"
    ).call

    assert_equal 1, matches.size
    assert_equal "0800466-41.2025.8.10.0030", matches.first[:process_number]
    assert_includes matches.first[:content], "MANDADO DE INTIMACAO"
    assert_includes matches.first[:matched_terms], "OAB 18727-MA"
  end

  test "finds publications by process numbers even when oab is absent" do
    text = "Disponibilizado no DJE. Processo 0000001-00.2026.8.10.0001. Intimacao publicada."

    matches = Integrations::Djma::PublicationMatcher.new(
      text: text,
      oab_registration: "18727",
      oab_state: "MA",
      process_numbers: [ "0000001-00.2026.8.10.0001" ]
    ).call

    assert_equal 1, matches.size
    assert_equal "0000001-00.2026.8.10.0001", matches.first[:process_number]
    assert_includes matches.first[:matched_terms], "0000001-00.2026.8.10.0001"
  end
end
