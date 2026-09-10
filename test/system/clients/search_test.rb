require_relative "../clients_test_case"

class ClientsSearchTest < ClientsSystemTestCase
  test "searches clients by name and updates the URL" do
    _office, unit, user = create_system_context
    matching_client = create_client_for(
      unit,
      full_name: "Cliente Aurora",
      cpf_cnpj: "33333333333"
    )
    other_client = create_client_for(
      unit,
      full_name: "Cliente Boreal",
      cpf_cnpj: "44444444444"
    )

    sign_in_and_select(user, unit)
    visit clients_path
    assert_selector "article", text: matching_client.full_name
    assert_selector "article", text: other_client.full_name

    fill_in "Busca", with: "Aurora"
    click_on "Buscar"

    assert_selector "article", text: matching_client.full_name
    assert_no_text other_client.full_name
    assert_current_path clients_path(q: "Aurora")
    assert_text "1 cliente(s)"
  end

  test "shows an empty state when the search has no matches" do
    _office, unit, user = create_system_context
    create_client_for(unit, full_name: "Cliente Existente", cpf_cnpj: "55555555555")

    sign_in_and_select(user, unit)
    visit clients_path
    fill_in "Busca", with: "Cliente inexistente"
    click_on "Buscar"

    assert_text "Nenhum cliente encontrado para estes filtros."
    assert_text "0 cliente(s)"
  end
end
