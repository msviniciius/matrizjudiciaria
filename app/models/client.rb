class Client < ApplicationRecord
  has_many :legal_cases, dependent: :destroy

  validates :full_name, :cpf_cnpj, presence: true
  validates :cpf_cnpj, uniqueness: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
end
