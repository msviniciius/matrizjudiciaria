class ClientShowSnapshot
  include Rails.application.routes.url_helpers

  def initialize(client:, legal_cases:)
    @client = client
    @legal_cases = legal_cases
  end

  def as_json(*)
    {
      client: client_entry,
      identification: identification,
      contact: contact,
      address: address,
      family: family,
      notes: client.notes.to_s,
      gov: gov_credentials,
      legal_cases: legal_cases.map { |record| legal_case_entry(record) },
      actions: actions
    }
  end

  private

  attr_reader :client, :legal_cases

  def client_entry
    {
      id: client.id,
      full_name: client.full_name,
      cpf_cnpj: value(client.cpf_cnpj),
      phone: value(client.phone),
      email: value(client.email),
      cadastro_pendente: client.cadastro_pendente?,
      status_label: client.cadastro_pendente? ? "Cadastro pendente" : "Completo",
      legal_cases_count: legal_cases.size,
      unit_name: client.unit&.name
    }
  end

  def identification
    [
      detail(:full_name, client.full_name),
      detail(:rg, client.rg),
      detail(:birth_date, client.birth_date.present? ? I18n.l(client.birth_date) : nil),
      detail(:marital_status, client.marital_status),
      detail(:profession, client.profession)
    ]
  end

  def contact
    [
      detail(:phone, client.phone),
      detail(:whatsapp, client.whatsapp),
      detail(:email, client.email)
    ]
  end

  def address
    [
      detail(:zip_code, client.zip_code),
      detail(:address, client.address),
      detail(:city, client.city),
      detail(:state, client.state)
    ]
  end

  def family
    [
      detail(:mother_name, client.mother_name),
      detail(:father_name, client.father_name)
    ]
  end

  def gov_credentials
    lines = client.dados_gov.to_s.lines.map(&:strip).reject(&:blank?)
    raw = lines.join("\n")

    {
      present: raw.present?,
      masked: lines.map { |line| line.match?(/^senha\s*:/i) ? line.sub(/(:\s*).*/, ": ********") : line }.join("\n"),
      raw: raw
    }
  end

  def legal_case_entry(record)
    {
      id: record.id,
      internal_number: record.internal_number,
      phase_label: enum_label(LegalCase, :phase, record.phase),
      status_label: enum_label(LegalCase, :status, record.status),
      priority_label: enum_label(LegalCase, :priority, record.priority),
      next_deadline_label: date_label(record.next_deadline_on),
      responsible_name: value(record.responsible_name),
      path: legal_case_path(record)
    }
  end

  def actions
    {
      index: clients_path,
      edit: edit_client_path(client),
      delete: client_path(client),
      new_legal_case: new_legal_case_path(client_id: client.id)
    }
  end

  def detail(attribute, raw_value)
    {
      label: Client.human_attribute_name(attribute),
      value: value(raw_value)
    }
  end

  def value(raw_value)
    raw_value.presence || "Não informado"
  end

  def enum_label(model_class, enum_name, raw_value)
    return "-" if raw_value.blank?

    I18n.t(
      "activerecord.attributes.#{model_class.model_name.i18n_key}.#{enum_name.to_s.pluralize}.#{raw_value}",
      default: raw_value.to_s.humanize
    )
  end

  def date_label(raw_value)
    raw_value.present? ? I18n.l(raw_value, format: :short) : "-"
  end
end
