class Expediente < ApplicationRecord
  belongs_to :legal_case
  has_one :ciencia, dependent: :destroy
  has_one :deadline, dependent: :destroy

  enum :tipo, {
    intimacao: "intimacao",
    citacao: "citacao",
    despacho: "despacho",
    sentenca: "sentenca"
  }, validate: true

  enum :contagem, {
    uteis: "uteis",
    corridos: "corridos"
  }, validate: true

  enum :origem, {
    manual: "manual",
    djma: "djma",
    pje: "pje"
  }, validate: true

  validates :tipo, :descricao, :data_disponibilizacao, :quantidade_dias, :contagem, :origem, presence: true
  validates :quantidade_dias, numericality: { only_integer: true, greater_than: 0 }, allow_blank: true

  after_create :create_pending_deadline!

  private

  def create_pending_deadline!
    create_deadline!(
      legal_case: legal_case,
      title: "Prazo jurídico: #{descricao}",
      deadline_type: :judicial,
      status: :pending
    )
  end
end
