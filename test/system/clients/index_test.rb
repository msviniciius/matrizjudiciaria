require_relative "../clients_test_case"

class ClientsIndexTest < ClientsSystemTestCase
  test "lists only clients from the selected unit" do
    _office, unit, user = create_system_context
    selected_client = create_client_for(
      unit,
      full_name: "Cliente da unidade",
      cpf_cnpj: "11111111111",
      email: "unidade@example.com",
      city: "São Luís"
    )
    other_unit = Unit.create!(office: unit.office, name: "Outra unidade #{SecureRandom.hex(4)}")
    other_client = create_client_for(
      other_unit,
      full_name: "Cliente de outra unidade",
      cpf_cnpj: "22222222222"
    )

    sign_in_and_select(user, unit)
    visit clients_path

    assert_selector "h1", text: "Clientes"
    assert_selector "article", text: selected_client.full_name
    assert_no_text other_client.full_name
    assert_text "1 cliente(s)"
    assert_link "Novo cliente", href: new_client_path
    assert_selector "a[aria-label='Editar cliente #{selected_client.full_name}'][href='#{edit_client_path(selected_client)}']"
  end
end
