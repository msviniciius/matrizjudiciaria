class CaseEvent < ApplicationRecord
  belongs_to :legal_case

  enum :event_type, {
    initial_contact: "initial_contact",
    documents_received: "documents_received",
    legal_analysis: "legal_analysis",
    filing: "filing",
    hearing: "hearing",
    decision: "decision",
    appeal: "appeal",
    client_contact: "client_contact",
    phase_changed: "phase_changed",
    status_changed: "status_changed",
    case_closed: "case_closed"
  }, prefix: true

  validates :event_type, :occurred_at, :description, presence: true
  validates :event_type, inclusion: { in: event_types.keys }
end
