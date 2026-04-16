class CaseEventsController < ApplicationController
  before_action :set_case_event, only: %i[ show edit update destroy ]

  def index
    @case_events = CaseEvent.includes(:legal_case, :movement_type, :process_exam).order(occurred_at: :desc)
  end

  def show
  end

  def new
    @case_event = CaseEvent.new(legal_case_id: params[:legal_case_id])
  end

  def edit
  end

  def create
    @case_event = CaseEvent.new(case_event_params)

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
    @case_event = CaseEvent.find(params.expect(:id))
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
      :next_action,
      :phase_after,
      :status_after,
      :process_exam_id
    ])
  end
end
