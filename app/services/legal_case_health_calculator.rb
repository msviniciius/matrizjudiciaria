class LegalCaseHealthCalculator
  # Calcula a "saude" de um processo com base em metricas operacionais.
  #
  # Aceita tanto um LegalCase (ActiveRecord) quanto um Hash com os campos
  # necessarios, permitindo uso em relatorios sem carregar o modelo inteiro.
  #
  # Uso:
  #   LegalCaseHealthCalculator.new(legal_case).call
  #   LegalCaseHealthCalculator.new(attrs_hash).call
  #
  class << self
    def calculate(legal_case_or_attrs)
      new(legal_case_or_attrs).call
    end
  end

  def initialize(source)
    @source = source
  end

  def call
    {
      score: score,
      status: status,
      vermelho?: vermelho?,
      amarelo?: amarelo?,
      verde?: verde?,
      issues: issues
    }
  end

  # Metodos individuais para compatibilidade com o modelo

  def score
    @score ||= compute_score
  end

  def status
    case score
    when 80..100 then "verde"
    when 50..79 then "amarelo"
    else "vermelho"
    end
  end

  def vermelho?
    status == "vermelho"
  end

  def amarelo?
    status == "amarelo"
  end

  def verde?
    status == "verde"
  end

  def issues
    @issues ||= build_issues
  end

  private

  def compute_score
    score = 100
    score -= 45 if deadline_overdue?
    score -= 20 if next_deadline_expected? && next_deadline_on.blank?
    score -= 18 if next_action.blank?
    score -= 12 if responsible_name.blank?
    score -= 10 if stale_last_movement?
    score -= 8 if prazo_alerta? && !deadline_overdue?
    score.clamp(0, 100)
  end

  def build_issues
    issues = []
    issues << "Prazo vencido" if deadline_overdue?
    issues << "Sem próxima providência" if next_action.blank?
    issues << "Sem próximo prazo definido" if next_deadline_expected? && next_deadline_on.blank?
    issues << "Sem responsável definido" if responsible_name.blank?
    issues << "Sem atualização recente" if stale_last_movement?
    issues
  end

  def deadline_overdue?
    next_deadline_on.present? && next_deadline_on < Date.current
  end

  def stale_last_movement?
    last_movement_at.blank? || last_movement_at < 15.days.ago
  end

  def prazo_alerta?
    next_deadline_on.present? && next_deadline_on <= Date.current + 7.days
  end

  def next_deadline_expected?
    %w[
      em_analise
      aguardando_providencia_escritorio
      aguardando_cliente
      aguardando_terceiros
    ].include?(extract(:status).to_s)
  end

  # Helpers para extrair atributos de LegalCase ou Hash

  def next_deadline_on
    extract(:next_deadline_on)
  end

  def next_action
    extract(:next_action)
  end

  def responsible_name
    extract(:responsible_name)
  end

  def last_movement_at
    extract(:last_movement_at)
  end

  def extract(key)
    if @source.is_a?(Hash)
      @source[key]
    elsif @source.respond_to?(key)
      @source.public_send(key)
    else
      nil
    end
  end
end
