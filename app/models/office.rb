class Office < ApplicationRecord
  CALENDAR_FEED_PURPOSE = :office_calendar_feed

  TRIBUNAL_INTEGRATIONS = {
    # Tribunais Estaduais
    "TJAC (Tribunal de Justiça do Acre)" => "tjac",
    "TJAL (Tribunal de Justiça de Alagoas)" => "tjal",
    "TJAP (Tribunal de Justiça do Amapá)" => "tjap",
    "TJAM (Tribunal de Justiça do Amazonas)" => "tjam",
    "TJBA (Tribunal de Justiça da Bahia)" => "tjba",
    "TJCE (Tribunal de Justiça do Ceará)" => "tjce",
    "TJDFT (Tribunal de Justiça do DF e Territórios)" => "tjdft",
    "TJES (Tribunal de Justiça do Espírito Santo)" => "tjes",
    "TJGO (Tribunal de Justiça de Goiás)" => "tjgo",
    "TJMA (Tribunal de Justiça do Maranhão)" => "tjma",
    "TJMT (Tribunal de Justiça do Mato Grosso)" => "tjmt",
    "TJMS (Tribunal de Justiça do Mato Grosso do Sul)" => "tjms",
    "TJMG (Tribunal de Justiça de Minas Gerais)" => "tjmg",
    "TJPA (Tribunal de Justiça do Pará)" => "tjpa",
    "TJPB (Tribunal de Justiça da Paraíba)" => "tjpb",
    "TJPR (Tribunal de Justiça do Paraná)" => "tjpr",
    "TJPE (Tribunal de Justiça de Pernambuco)" => "tjpe",
    "TJPI (Tribunal de Justiça do Piauí)" => "tjpi",
    "TJRJ (Tribunal de Justiça do Rio de Janeiro)" => "tjrj",
    "TJRN (Tribunal de Justiça do Rio Grande do Norte)" => "tjrn",
    "TJRS (Tribunal de Justiça do Rio Grande do Sul)" => "tjrs",
    "TJRO (Tribunal de Justiça de Rondônia)" => "tjro",
    "TJRR (Tribunal de Justiça de Roraima)" => "tjrr",
    "TJSC (Tribunal de Justiça de Santa Catarina)" => "tjsc",
    "TJSP (Tribunal de Justiça de São Paulo)" => "tjsp",
    "TJSE (Tribunal de Justiça de Sergipe)" => "tjse",
    "TJTO (Tribunal de Justiça do Tocantins)" => "tjto",
    # Tribunais Regionais Federais
    "TRF1 (Tribunal Regional Federal da 1ª Região)" => "trf1",
    "TRF2 (Tribunal Regional Federal da 2ª Região)" => "trf2",
    "TRF3 (Tribunal Regional Federal da 3ª Região)" => "trf3",
    "TRF4 (Tribunal Regional Federal da 4ª Região)" => "trf4",
    "TRF5 (Tribunal Regional Federal da 5ª Região)" => "trf5",
    "TRF6 (Tribunal Regional Federal da 6ª Região)" => "trf6",
    # Tribunais Superiores
    "STJ (Superior Tribunal de Justiça)" => "stj",
    "TST (Tribunal Superior do Trabalho)" => "tst",
    "STM (Superior Tribunal Militar)" => "stm",
    "TSE (Tribunal Superior Eleitoral)" => "tse",
    # Tribunais Regionais do Trabalho
    "TRT1 (Tribunal Regional do Trabalho 1ª Região - RJ)" => "trt1",
    "TRT2 (Tribunal Regional do Trabalho 2ª Região - SP)" => "trt2",
    "TRT3 (Tribunal Regional do Trabalho 3ª Região - MG)" => "trt3",
    "TRT4 (Tribunal Regional do Trabalho 4ª Região - RS)" => "trt4",
    "TRT5 (Tribunal Regional do Trabalho 5ª Região - BA)" => "trt5",
    "TRT6 (Tribunal Regional do Trabalho 6ª Região - PE)" => "trt6",
    "TRT7 (Tribunal Regional do Trabalho 7ª Região - CE)" => "trt7",
    "TRT8 (Tribunal Regional do Trabalho 8ª Região - PA/AP)" => "trt8",
    "TRT9 (Tribunal Regional do Trabalho 9ª Região - PR)" => "trt9",
    "TRT10 (Tribunal Regional do Trabalho 10ª Região - DF/TO)" => "trt10",
    "TRT11 (Tribunal Regional do Trabalho 11ª Região - AM/RR)" => "trt11",
    "TRT12 (Tribunal Regional do Trabalho 12ª Região - SC)" => "trt12",
    "TRT13 (Tribunal Regional do Trabalho 13ª Região - PB)" => "trt13",
    "TRT14 (Tribunal Regional do Trabalho 14ª Região - RO/AC)" => "trt14",
    "TRT15 (Tribunal Regional do Trabalho 15ª Região - Campinas/SP)" => "trt15",
    "TRT16 (Tribunal Regional do Trabalho 16ª Região - MA)" => "trt16",
    "TRT17 (Tribunal Regional do Trabalho 17ª Região - ES)" => "trt17",
    "TRT18 (Tribunal Regional do Trabalho 18ª Região - GO)" => "trt18",
    "TRT19 (Tribunal Regional do Trabalho 19ª Região - AL)" => "trt19",
    "TRT20 (Tribunal Regional do Trabalho 20ª Região - SE)" => "trt20",
    "TRT21 (Tribunal Regional do Trabalho 21ª Região - RN)" => "trt21",
    "TRT22 (Tribunal Regional do Trabalho 22ª Região - PI)" => "trt22",
    "TRT23 (Tribunal Regional do Trabalho 23ª Região - MT)" => "trt23",
    "TRT24 (Tribunal Regional do Trabalho 24ª Região - MS)" => "trt24",
    # Tribunais Regionais Eleitorais
    "TRE-MA (Tribunal Regional Eleitoral do Maranhão)" => "tre-ma",
    "TRE-SP (Tribunal Regional Eleitoral de São Paulo)" => "tre-sp",
    "TRE-RJ (Tribunal Regional Eleitoral do Rio de Janeiro)" => "tre-rj",
    "TRE-MG (Tribunal Regional Eleitoral de Minas Gerais)" => "tre-mg"
  }.freeze

  has_one_attached :logo

  has_many :users, dependent: :destroy
  has_many :units, dependent: :destroy
  has_many :clients, dependent: :destroy
  has_many :legal_cases, dependent: :destroy
  has_many :receivables, dependent: :destroy
  has_many :deadline_settings, dependent: :destroy

  before_validation :normalize_slug

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :zip_code, format: { with: /\A\d{5}-?\d{3}\z/, message: "deve estar no formato 00000-000" }, allow_blank: true
  validates :default_phase, inclusion: { in: LegalCase.phases.keys }
  validates :default_status, inclusion: { in: LegalCase.statuses.keys }
  validates :default_priority, inclusion: { in: LegalCase.priorities.keys }
  validates :deadline_alert_days, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 60 }
  validates :task_alert_days, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 60 }
  validate :enabled_tribunals_must_be_allowed

  def logo_attached?
    logo.attached?
  end

  def enabled_tribunal_codes
    return [] unless respond_to?(:enabled_tribunals)

    Array(enabled_tribunals).map(&:to_s).reject(&:blank?)
  end

  def tribunal_enabled?(code)
    enabled_tribunal_codes.include?(code.to_s)
  end

  def calendar_feed_token(expires_in: 5.years)
    signed_id(purpose: CALENDAR_FEED_PURPOSE, expires_in: expires_in)
  end

  def self.find_by_calendar_feed_token!(token)
    find_signed!(token, purpose: CALENDAR_FEED_PURPOSE)
  end

  private

  def enabled_tribunals_must_be_allowed
    return unless respond_to?(:enabled_tribunals)

    normalized_codes = Array(enabled_tribunals).map(&:to_s).reject(&:blank?)
    self.enabled_tribunals = normalized_codes

    invalid_codes = normalized_codes - TRIBUNAL_INTEGRATIONS.values
    return if invalid_codes.empty?

    errors.add(:enabled_tribunals, "contém integrações inválidas")
  end

  def normalize_slug
    return if slug.blank? && name.blank?

    self.slug = (slug.presence || name).to_s.parameterize
  end
end
