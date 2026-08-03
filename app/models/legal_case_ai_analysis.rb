class LegalCaseAiAnalysis < ApplicationRecord
  belongs_to :legal_case
  belongs_to :created_by, class_name: "User", optional: true

  validates :provider, :model, :summary, :suggested_action, :confidence, presence: true
  validates :risks, :deterministic_snapshot, :raw_response, presence: true

  def as_json(*)
    {
      id: id,
      provider: provider,
      model: model,
      summary: summary,
      risks: risks,
      suggested_action: suggested_action,
      confidence: confidence,
      notes: notes,
      created_at: created_at&.iso8601,
      created_at_label: created_at.present? ? I18n.l(created_at, format: :short) : nil,
      created_by_name: created_by&.name
    }
  end
end
