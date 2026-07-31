class ClientsSnapshot
  include Rails.application.routes.url_helpers

  FILTER_KEYS = %i[q cadastro_pendente city].freeze

  def initialize(office:, unit:, clients:, filters:)
    @office = office
    @unit = unit
    @clients = clients
    @filters = filters.to_h.symbolize_keys
  end

  def as_json(*)
    {
      meta: {
        office_name: office.name,
        unit_name: unit&.name,
        total_count: clients.count
      },
      filters: FILTER_KEYS.index_with { |key| filters[key].to_s },
      clients: clients.map { |record| client_entry(record) },
      actions: {
        index: clients_path,
        new: new_client_path
      }
    }
  end

  private

  attr_reader :office, :unit, :clients, :filters

  def client_entry(record)
    {
      id: record.id,
      path: client_path(record),
      edit_path: edit_client_path(record),
      delete_path: client_path(record),
      full_name: record.full_name,
      cpf_cnpj: record.cpf_cnpj,
      phone: record.phone.to_s,
      email: record.email.to_s,
      city: record.city.to_s,
      cadastro_pendente: record.cadastro_pendente?,
      status_label: record.cadastro_pendente? ? "Cadastro pendente" : "Completo",
      legal_cases_count: record.legal_cases.size,
      processes_path: client_path(record)
    }
  end
end
