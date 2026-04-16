class Client < ApplicationRecord
  has_many :legal_cases, dependent: :destroy

  validates :full_name, :cpf_cnpj, presence: true
  validates :cpf_cnpj, uniqueness: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :phone, presence: true, on: :quick_create

  scope :ordered, -> { order(:full_name) }

  def display_name_with_status
    return full_name unless cadastro_pendente?

    "#{full_name} (cadastro pendente)"
  end
end
