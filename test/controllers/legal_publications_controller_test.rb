require "test_helper"

class LegalPublicationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    create_case_dependencies
    @admin = User.create!(
      office: default_office,
      name: "Admin Publicacoes",
      email: "admin-publicacoes-#{SecureRandom.hex(4)}@example.com",
      role: "admin",
      password: "segredo123",
      password_confirmation: "segredo123",
      active: true,
      matrix_access: true
    )
    @client = create_client(full_name: "Cliente Publicacoes")
    @legal_case = create_full_legal_case(client: @client, external_number: "0000001-00.2026.8.10.0001")

    post login_path, params: { email: @admin.email, password: "segredo123" }
  end

  test "index lists office publications" do
    publication = LegalPublication.create!(
      office: default_office,
      legal_case: @legal_case,
      source: "escavador",
      external_id: "pub-index",
      event_name: "diario_movimentacao_nova",
      title: "Publicacao encontrada",
      content: "Conteudo da publicacao"
    )

    get legal_publications_path

    assert_response :success
    assert_select "h3", "Publicações"
    assert_match publication.title, response.body
    assert_select "a[href='#{legal_case_path(@legal_case)}']"
  end

  test "filters unread and unlinked publications" do
    visible = LegalPublication.create!(
      office: default_office,
      source: "escavador",
      external_id: "pub-visible",
      event_name: "diario_movimentacao_nova",
      title: "Publicacao pendente",
      content: "Conteudo pendente"
    )
    LegalPublication.create!(
      office: default_office,
      legal_case: @legal_case,
      source: "escavador",
      external_id: "pub-hidden",
      event_name: "diario_movimentacao_nova",
      title: "Publicacao lida vinculada",
      content: "Conteudo lido",
      read_at: Time.current
    )

    get legal_publications_path(status: "unread", link: "unlinked")

    assert_response :success
    assert_match visible.title, response.body
    assert_no_match "Publicacao lida vinculada", response.body
  end

  test "renders clients listing filter pattern and searches publications" do
    visible = LegalPublication.create!(
      office: default_office,
      source: "djma",
      external_id: "pub-search-visible",
      event_name: "djma_publication",
      title: "Mandado de intimacao",
      content: "Texto do DJMA com OAB 18727"
    )
    LegalPublication.create!(
      office: default_office,
      source: "djma",
      external_id: "pub-search-hidden",
      event_name: "djma_publication",
      title: "Publicacao diversa",
      content: "Outro texto"
    )

    get legal_publications_path(q: "mandado")

    assert_response :success
    assert_select "form.main-filters--clients-pattern[aria-label='Filtros de publicações']"
    assert_select "input[name='q'][placeholder='Título, conteúdo, processo ou fonte']"
    assert_select "button", "Filtros avançados"
    assert_select "a", "Limpar filtros"
    assert_match visible.title, response.body
    assert_select "tbody" do |elements|
      assert_no_match "Publicacao diversa", elements.map(&:text).join
    end
  end

  test "marks publication as read" do
    publication = LegalPublication.create!(
      office: default_office,
      source: "escavador",
      external_id: "pub-read",
      event_name: "diario_movimentacao_nova",
      content: "Conteudo para leitura"
    )

    patch mark_read_legal_publication_path(publication)

    assert_redirected_to legal_publications_path
    assert publication.reload.read_at.present?
  end
end
