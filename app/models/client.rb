class Client < ApplicationRecord
  belongs_to :office
  belongs_to :unit, optional: true
  has_many :legal_cases, dependent: :destroy
  has_many :receivables, dependent: :nullify

  validates :full_name, :cpf_cnpj, presence: true
  validates :cpf_cnpj, uniqueness: { scope: :office_id }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :zip_code, format: { with: /\A\d{5}-?\d{3}\z/, message: "deve estar no formato 00000-000" }, allow_blank: true
  validates :phone, presence: true, on: :quick_create

  scope :ordered, -> { order(:full_name) }

  def display_name_with_status
    return full_name unless cadastro_pendente?

    "#{full_name} (cadastro pendente)"
  end
end
