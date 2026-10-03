require "test_helper"

class OfficeTest < ActiveSupport::TestCase
  test "accepts supported logo formats" do
    %i[png jpeg webp].each do |format|
      office = Office.new(name: "Escritorio #{format}", slug: "escritorio-#{format}")
      office.logo = logo_upload(format: format)

      assert office.valid?, "expected #{format} logo to be valid: #{office.errors.full_messages.to_sentence}"
    end
  end

  test "rejects unsupported logo content type" do
    office = Office.new(name: "Escritorio Logo Invalido", slug: "escritorio-logo-invalido")
    office.logo = uploaded_file("not an image", content_type: "text/plain", filename: "logo.txt")

    assert_not office.valid?
    assert_includes office.errors[:logo], "deve ser PNG, JPEG ou WebP"
  end

  test "rejects logo larger than five megabytes" do
    office = Office.new(name: "Escritorio Logo Grande", slug: "escritorio-logo-grande")
    office.logo = logo_upload(padding: Office::LOGO_MAX_SIZE)

    assert_not office.valid?
    assert_includes office.errors[:logo], "deve ter no máximo 5 MB"
  end

  test "keeps persisted logo when replacement is invalid" do
    office = Office.create!(name: "Escritorio Logo Persistido", slug: "escritorio-logo-persistido")
    office.logo.attach(logo_upload(filename: "original.png"))
    original_blob_id = office.logo.blob.id

    office.logo = uploaded_file("not an image", content_type: "text/plain", filename: "invalid.txt")

    assert_not office.save
    assert_equal original_blob_id, office.reload.logo.blob.id
  end

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
