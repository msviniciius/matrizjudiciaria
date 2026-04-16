class MovementTemplate < ApplicationRecord
  belongs_to :phase, class_name: "ProcessPhase"
  belongs_to :movement_type
  belongs_to :next_phase, class_name: "ProcessPhase", optional: true

  has_many :process_movements, dependent: :restrict_with_exception

  enum :nature_default, {
    fato_processual: "fato_processual",
    fato_administrativo: "fato_administrativo",
    nota_interna: "nota_interna",
    atualizacao_estrategica: "atualizacao_estrategica"
  }, prefix: true

  enum :impact_default, {
    sem_impacto_de_fase: "sem_impacto_de_fase",
    altera_fase: "altera_fase",
    exige_providencia_imediata: "exige_providencia_imediata",
    exige_revisao_estrategica: "exige_revisao_estrategica"
  }, prefix: true

  validates :code, :name, :nature_default, :impact_default, presence: true
  validates :code, uniqueness: true
end
