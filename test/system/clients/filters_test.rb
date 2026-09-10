require_relative "../clients_test_case"

class ClientsFiltersTest < ClientsSystemTestCase
  test "filters clients by registration status and city" do
    _office, unit, user = create_system_context
    matching_client = create_client_for(
      unit,
      full_name: "Pendente São Luís",
      cpf_cnpj: "66666666666",
      cadastro_pendente: true,
      city: "São Luís"
    )
    create_client_for(
      unit,
      full_name: "Completo São Luís",
      cpf_cnpj: "77777777777",
      cadastro_pendente: false,
      city: "São Luís"
    )
    other_city_client = create_client_for(
      unit,
      full_name: "Pendente Imperatriz",
      cpf_cnpj: "88888888888",
      cadastro_pendente: true,
      city: "Imperatriz"
    )

    sign_in_and_select(user, unit)
    visit clients_path
    click_on "Filtros avançados"
    select "Pendente", from: "Status do cadastro"
    fill_in "Cidade", with: "São Luís"

    assert_selector "article", text: matching_client.full_name
    assert_no_text "Completo São Luís"
    assert_no_text other_city_client.full_name
    assert_current_path clients_path(cadastro_pendente: "true", city: "São Luís")
    assert_text "1 cliente(s)"
  end
end
