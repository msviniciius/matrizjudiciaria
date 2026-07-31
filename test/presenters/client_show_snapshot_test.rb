require "test_helper"

class ClientShowSnapshotTest < ActiveSupport::TestCase
  include Rails.application.routes.url_helpers

  test "serializes the client dossier and linked cases" do
    create_case_dependencies
    client = create_client(
      full_name: "Cliente Detalhe",
      cpf_cnpj: "12345678901",
      phone: "(98) 99999-1111",
      email: "cliente@example.com",
      dados_gov: "Email: gov@example.com\nSenha: segredo",
      cadastro_pendente: true
    )
    legal_case = create_full_legal_case(
      client: client,
      internal_number: "PROC-CLIENT-001",
      next_deadline_on: Date.current + 1.day,
      responsible_name: "Marina"
    )

    snapshot = ClientShowSnapshot.new(client: client, legal_cases: [ legal_case ]).as_json

    assert_equal client.id, snapshot.fetch(:client).fetch(:id)
    assert_equal "Cadastro pendente", snapshot.fetch(:client).fetch(:status_label)
    assert_equal edit_client_path(client), snapshot.fetch(:actions).fetch(:edit)
    assert_equal new_legal_case_path(client_id: client.id), snapshot.fetch(:actions).fetch(:new_legal_case)
    assert_equal "Email: gov@example.com\nSenha: ********", snapshot.fetch(:gov).fetch(:masked)
    assert_equal "PROC-CLIENT-001", snapshot.fetch(:legal_cases).sole.fetch(:internal_number)
    assert_equal legal_case_path(legal_case), snapshot.fetch(:legal_cases).sole.fetch(:path)
  end

  test "serializes empty optional data with display fallbacks" do
    client = create_client(full_name: "Cliente Sem Dados")

    snapshot = ClientShowSnapshot.new(client: client, legal_cases: []).as_json

    assert_equal "Não informado", snapshot.fetch(:client).fetch(:phone)
    assert_equal false, snapshot.fetch(:gov).fetch(:present)
    assert_empty snapshot.fetch(:legal_cases)
    assert_equal 0, snapshot.fetch(:client).fetch(:legal_cases_count)
  end
end
