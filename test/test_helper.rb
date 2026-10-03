ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "base64"
require "stringio"

module LogoUploadTestHelper
  LOGO_FILE_DATA = {
    png: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=",
    jpeg: "/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAP//////////////////////////////////////////////////////////////////////////////////////2wBDAf//////////////////////////////////////////////////////////////////////////////////////wAARCAABAAEDASIAAhEBAxEB/8QAFQABAQAAAAAAAAAAAAAAAAAAAAX/xAAUEAEAAAAAAAAAAAAAAAAAAAAA/9oADAMBAAIQAxAAAAEf/8QAFBABAAAAAAAAAAAAAAAAAAAAAP/aAAgBAQABBQJ//8QAFBEBAAAAAAAAAAAAAAAAAAAAAP/aAAgBAwEBPwF//8QAFBEBAAAAAAAAAAAAAAAAAAAAAP/aAAgBAgEBPwF//8QAFBABAAAAAAAAAAAAAAAAAAAAAP/aAAgBAQAGPwJ//8QAFBABAAAAAAAAAAAAAAAAAAAAAP/aAAgBAQABPyF//9oADAMBAAIAAwAAABAf/8QAFBEBAAAAAAAAAAAAAAAAAAAAAP/aAAgBAwEBPxB//8QAFBEBAAAAAAAAAAAAAAAAAAAAAP/aAAgBAgEBPxB//8QAFBABAAAAAAAAAAAAAAAAAAAAAP/aAAgBAQABPxB//9k=",
    webp: "UklGRiIAAABXRUJQVlA4IBYAAAAwAQCdASoBAAEADsD+JaQAA3AAAAAA"
  }.freeze
  LOGO_CONTENT_TYPES = {
    png: "image/png",
    jpeg: "image/jpeg",
    webp: "image/webp"
  }.freeze
  LOGO_EXTENSIONS = { png: "png", jpeg: "jpg", webp: "webp" }.freeze

  def logo_upload(format: :png, filename: nil, padding: 0)
    data = Base64.strict_decode64(LOGO_FILE_DATA.fetch(format)) + ("\0" * padding)
    uploaded_file(
      data,
      content_type: LOGO_CONTENT_TYPES.fetch(format),
      filename: filename || "logo.#{LOGO_EXTENSIONS.fetch(format)}"
    )
  end

  def uploaded_file(data, content_type:, filename:)
    Rack::Test::UploadedFile.new(StringIO.new(data), content_type, original_filename: filename)
  end
end

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)
    include LogoUploadTestHelper
    # Fixtures disabled: test data is built in each test case to avoid FK-order issues on restricted PostgreSQL users.

    # Helper para fornecer um Office padrao em todos os testes.
    # Usa find_or_create_by! para ser seguro em execucao paralela.
    def default_office
      @default_office ||= Office.find_or_create_by!(name: "Test Office", slug: "test-office") do |office|
        office.legal_name = "Test Office Legal"
        office.default_phase = "atendimento_inicial"
        office.default_status = "em_analise"
        office.default_priority = "medium"
      end
    end

    # Helper para criar um Client com office padrao e atributos minimos
    def create_client(full_name:, cpf_cnpj: nil, **attrs)
      Client.create!(
        full_name: full_name,
        cpf_cnpj: cpf_cnpj || SecureRandom.hex(6),
        office: default_office,
        **attrs
      )
    end

    # Helper para criar um LegalCase com associacoes minimas validas
    def create_legal_case(internal_number: nil, **attrs)
      internal_number ||= "PROC-TEST-#{SecureRandom.hex(4).upcase}"

      defaults = {
        internal_number: internal_number,
        phase: "analise_juridica",
        status: "em_analise",
        responsible_name: "Advogado Teste",
        next_action: "Revisar documentação",
        next_deadline_on: Date.current + 5.days
      }

      LegalCase.create!(defaults.merge(attrs))
    end

    # Cria registros auxiliares comuns (District, Court, LegalArea, ProcessType)
    def create_case_dependencies(district_name: "Comarca Teste", court_name: "Vara Teste",
                                legal_area_name: "Direito Civil", justice_branch: "estadual",
                                process_type_name: "Procedimento Comum")
      @test_district = District.find_or_create_by!(name: district_name)
      @test_court = Court.find_or_create_by!(name: court_name, district: @test_district)
      @test_legal_area = LegalArea.find_or_create_by!(name: legal_area_name, justice_branch: justice_branch)
      @test_process_type = ProcessType.find_or_create_by!(name: process_type_name, legal_area: @test_legal_area)
    end

    # Cria um LegalCase completo com todos os prerequisitos
    def create_full_legal_case(internal_number: nil, client: nil, **attrs)
      create_case_dependencies unless @test_legal_area

      client ||= create_client(full_name: "Cliente #{SecureRandom.hex(4)}")

      create_legal_case(
        internal_number: internal_number,
        client: client,
        office: default_office,
        legal_area: @test_legal_area,
        process_type: @test_process_type,
        district: @test_district,
        court: @test_court,
        **attrs
      )
    end
  end
end
