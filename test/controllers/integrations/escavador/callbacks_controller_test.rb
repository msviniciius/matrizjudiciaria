require "test_helper"

class Integrations::Escavador::CallbacksControllerTest < ActionDispatch::IntegrationTest
  setup do
    create_case_dependencies
    default_office.update!(oab_registration: "18727", oab_state: "MA")
    @client = create_client(full_name: "Cliente Callback")
    @legal_case = create_full_legal_case(
      client: @client,
      external_number: "0000001-00.2026.8.10.0001"
    )
  end

  test "rejects callbacks without the configured token" do
    with_escavador_callback_token("segredo") do
      post integrations_escavador_callbacks_path, params: publication_payload, as: :json
    end

    assert_response :unauthorized
    assert_equal 0, LegalPublication.count
  end

  test "creates and links a publication from a valid callback" do
    with_escavador_callback_token("segredo") do
      assert_difference -> { LegalPublication.count }, 1 do
        post integrations_escavador_callbacks_path,
          params: publication_payload,
          headers: { "Authorization" => "Bearer segredo" },
          as: :json
      end
    end

    assert_response :created
    publication = LegalPublication.last
    assert_equal default_office, publication.office
    assert_equal @legal_case, publication.legal_case
    assert_equal "callback-1", publication.external_id
  end

  test "does not duplicate retried callbacks" do
    with_escavador_callback_token("segredo") do
      post integrations_escavador_callbacks_path,
        params: publication_payload,
        headers: { "Authorization" => "Bearer segredo" },
        as: :json
      assert_response :created

      assert_no_difference -> { LegalPublication.count } do
        post integrations_escavador_callbacks_path,
          params: publication_payload,
          headers: { "Authorization" => "Bearer segredo" },
          as: :json
      end
    end

    assert_response :ok
  end

  test "accepts unsupported events without creating a publication" do
    with_escavador_callback_token("segredo") do
      assert_no_difference -> { LegalPublication.count } do
        post integrations_escavador_callbacks_path,
          params: { evento: "evento_desconhecido", uuid: "unknown-1" },
          headers: { "Authorization" => "Bearer segredo" },
          as: :json
      end
    end

    assert_response :accepted
  end

  private

  def publication_payload
    {
      evento: "diario_movimentacao_nova",
      uuid: "callback-1",
      movimentacao: {
        conteudo: "Publicacao do processo 0000001-00.2026.8.10.0001",
        data: "2026-08-03",
        tribunal: "TJMA",
        diario: "DJE MA"
      }
    }
  end

  def with_escavador_callback_token(token)
    previous = ENV["ESCAVADOR_CALLBACK_TOKEN"]
    ENV["ESCAVADOR_CALLBACK_TOKEN"] = token
    yield
  ensure
    ENV["ESCAVADOR_CALLBACK_TOKEN"] = previous
  end
end
