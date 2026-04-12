class CaseEventsController < ApplicationController
  before_action :set_case_event, only: %i[ show edit update destroy ]

  # GET /case_events or /case_events.json
  def index
    @case_events = CaseEvent.all
  end

  # GET /case_events/1 or /case_events/1.json
  def show
  end

  # GET /case_events/new
  def new
    @case_event = CaseEvent.new
  end

  # GET /case_events/1/edit
  def edit
  end

  # POST /case_events or /case_events.json
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

  # PATCH/PUT /case_events/1 or /case_events/1.json
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

  # DELETE /case_events/1 or /case_events/1.json
  def destroy
    @case_event.destroy!

    respond_to do |format|
      format.html { redirect_to case_events_path, notice: "Andamento excluído com sucesso.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_case_event
      @case_event = CaseEvent.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def case_event_params
      params.expect(case_event: [ :legal_case_id, :event_type, :occurred_at, :description, :responsible_name ])
    end
end
