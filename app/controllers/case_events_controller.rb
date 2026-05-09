class CaseEventsController < ApplicationController
  before_action :set_case_event, only: %i[ show edit update destroy ]

  def index
    @filters = case_event_filters
    scope = CaseEvent
      .joins(:legal_case)
      .where(legal_cases: { office_id: current_office.id })
      .includes(:legal_case, :movement_type, :process_exam)
      .order(occurred_at: :desc)

    if @filters[:q].present?
      term = "%#{@filters[:q].strip}%"
      scope = scope.where(
        "COALESCE(case_events.description, '') ILIKE :term
         OR COALESCE(legal_cases.internal_number, '') ILIKE :term",
        term: term
      )
    end

    scope = scope.where(entry_kind: @filters[:entry_kind]) if @filters[:entry_kind].present?
    scope = scope.where(event_type: @filters[:event_type]) if @filters[:event_type].present?
    scope = scope.where(movement_type_id: @filters[:movement_type_id]) if @filters[:movement_type_id].present?
    scope = scope.where("case_events.occurred_at >= ?", @filters[:from].to_date.beginning_of_day) if @filters[:from].present?
    scope = scope.where("case_events.occurred_at <= ?", @filters[:to].to_date.end_of_day) if @filters[:to].present?

    @case_events = scope
    @movement_types = MovementType.where(active: true).order(:name)
    @advanced_filters_open = false
  end

  def show
  end

  def new
    legal_case_id = params[:legal_case_id]
    if legal_case_id.present?
      current_office.legal_cases.find(legal_case_id)
    end
    @case_event = CaseEvent.new(legal_case_id: legal_case_id)
  end

  def edit
  end

  def create
    @case_event = CaseEvent.new(case_event_params)
    ensure_case_event_office_scope!

    respond_to do |format|
      if @case_event.save
        format.html { redirect_to @case_event, notice: "Andamento cadastrado com sucesso." }
        format.json { render :show, status: :created, location: @case_event }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @case_event.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @case_event.update(case_event_params)
        format.html { redirect_to @case_event, notice: "Andamento atualizado com sucesso.", status: :see_other }
        format.json { render :show, status: :ok, location: @case_event }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @case_event.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @case_event.destroy!

    respond_to do |format|
      format.html { redirect_to case_events_path, notice: "Andamento excluído com sucesso.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private

  def set_case_event
    @case_event = CaseEvent
      .joins(:legal_case)
      .where(legal_cases: { office_id: current_office.id })
      .find(params.expect(:id))
  end

  def case_event_params
    params.expect(case_event: [
      :legal_case_id,
      :event_type,
      :occurred_at,
      :description,
      :responsible_name,
      :movement_type_id,
      :entry_kind,
      :next_action
    ])
  end

  def ensure_case_event_office_scope!
    return if @case_event.legal_case.blank?
    return if @case_event.legal_case.office_id == current_office.id

    raise ActiveRecord::RecordNotFound
  end

  def case_event_filters
    params.permit(:q, :entry_kind, :event_type, :movement_type_id, :from, :to)
  end
end
