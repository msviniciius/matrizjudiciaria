class DeadlinesController < ApplicationController
  before_action :set_deadline, only: %i[ show edit update destroy quick_update ]

  # GET /deadlines or /deadlines.json
  def index
    @filters = deadline_filters
    scope = Deadline
      .joins(:legal_case)
      .where(legal_cases: { office_id: current_office.id })
      .includes(legal_case: :client)
      .order(due_date: :asc, created_at: :desc)
    scope = scope_by_current_unit(scope, through: :legal_cases)

    if @filters[:q].present?
      term = "%#{@filters[:q].strip}%"
      scope = scope.where(
        "COALESCE(deadlines.title, '') ILIKE :term
         OR COALESCE(deadlines.responsible_name, '') ILIKE :term
         OR COALESCE(legal_cases.internal_number, '') ILIKE :term",
        term: term
      )
    end

    scope = scope.where(status: @filters[:status]) if @filters[:status].present?
    scope = scope.where(priority: @filters[:priority]) if @filters[:priority].present?
    scope = scope.where(deadline_type: @filters[:deadline_type]) if @filters[:deadline_type].present?

    case @filters[:due_state]
    when "overdue"
      scope = scope.where("deadlines.due_date < ?", Date.current)
    when "today"
      scope = scope.where(due_date: Date.current)
    when "upcoming"
      scope = scope.where(due_date: Date.current..(Date.current + 7.days))
    when "without_due_date"
      scope = scope.where(due_date: nil)
    end

    @deadlines = scope
    @advanced_filters_open = false

    return unless request.format.json?

    render json: DeadlinesSnapshot.new(
      office: current_office,
      unit: current_unit,
      deadlines: @deadlines,
      filters: @filters
    ).as_json
  end

  # GET /deadlines/1 or /deadlines/1.json
  def show
  end

  # GET /deadlines/new
  def new
    @deadline = Deadline.new
  end

  # GET /deadlines/1/edit
  def edit
  end

  # POST /deadlines or /deadlines.json
  def create
    @deadline = Deadline.new(deadline_params)
    ensure_deadline_office_scope!

    respond_to do |format|
      if @deadline.save
        format.html { redirect_to @deadline, notice: "Prazo cadastrado com sucesso." }
        format.json { render :show, status: :created, location: @deadline }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @deadline.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /deadlines/1 or /deadlines/1.json
  def update
    respond_to do |format|
      if @deadline.update(deadline_params)
        format.html { redirect_to @deadline, notice: "Prazo atualizado com sucesso.", status: :see_other }
        format.json { render :show, status: :ok, location: @deadline }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @deadline.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /deadlines/1 or /deadlines/1.json
  def destroy
    @deadline.destroy!

    respond_to do |format|
      format.html { redirect_to deadlines_path, notice: "Prazo excluído com sucesso.", status: :see_other }
      format.json { head :no_content }
    end
  end

  def quick_update
    action_kind = params[:action_kind].to_s

    case action_kind
    when "completed"
      @deadline.update!(status: "completed", completed_at: Time.current)
      notice = "Prazo marcado como cumprido."
    when "suspended"
      @deadline.update!(
        status: "suspended",
        delay_reason: @deadline.delay_reason.presence || "Prazo suspenso em #{I18n.l(Time.current, format: :short)}."
      )
      notice = "Prazo marcado como suspenso."
    when "extended"
      unless Deadline.column_names.include?("extended_at") && Deadline.column_names.include?("extended_from_date")
        redirect_back fallback_location: deadlines_path, alert: "Atualize o banco com as migrations para usar a prorrogação com data."
        return
      end

      extended_to = begin
        Date.parse(params[:extended_to].to_s)
      rescue StandardError
        nil
      end

      if extended_to.blank?
        redirect_back fallback_location: deadlines_path, alert: "Selecione a data de prorrogação."
        return
      end

      previous_due_date = @deadline.due_date || Date.current

      if extended_to <= previous_due_date
        redirect_back fallback_location: deadlines_path, alert: "A nova data deve ser posterior ao vencimento atual."
        return
      end

      @deadline.update!(
        status: "extended",
        extended_at: Time.current,
        extended_from_date: previous_due_date,
        due_date: extended_to,
        delay_reason: @deadline.delay_reason.presence || "Prazo prorrogado manualmente para #{I18n.l(extended_to, format: :short)}."
      )
      notice = "Prazo prorrogado para #{I18n.l(extended_to, format: :short)}."
    else
      notice = "Ação de prazo inválida."
    end

    refresh_legal_case_next_deadline!(@deadline.legal_case)
    redirect_back fallback_location: deadlines_path, notice: notice
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_deadline
      @deadline = Deadline.joins(:legal_case).where(legal_cases: { office_id: current_office.id }).find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def deadline_params
      params.expect(deadline: [ :legal_case_id, :title, :deadline_type, :due_date, :status, :priority, :delay_reason ])
    end

    def ensure_deadline_office_scope!
      return if @deadline.legal_case.blank?
      return if @deadline.legal_case.office_id == current_office.id

      raise ActiveRecord::RecordNotFound
    end

    def refresh_legal_case_next_deadline!(legal_case)
      return if legal_case.blank?

      next_due_date = legal_case.deadlines
        .where(status: %w[pending in_progress extended overdue])
        .where.not(due_date: nil)
        .minimum(:due_date)

      legal_case.update_column(:next_deadline_on, next_due_date)
    end

    def deadline_filters
      params.permit(:q, :status, :priority, :deadline_type, :due_state)
    end
end
