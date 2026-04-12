class LegalCasesController < ApplicationController
  before_action :set_legal_case, only: %i[ show edit update destroy ]

  # GET /legal_cases or /legal_cases.json
  def index
    @legal_cases = LegalCase.all
  end

  # GET /legal_cases/1 or /legal_cases/1.json
  def show
    @case_events = @legal_case.case_events.order(occurred_at: :desc)
    @deadlines = @legal_case.deadlines.order(due_date: :asc)
    @tasks = @legal_case.tasks.order(due_date: :asc)
  end

  # GET /legal_cases/new
  def new
    @legal_case = LegalCase.new
  end

  # GET /legal_cases/1/edit
  def edit
  end

  # POST /legal_cases or /legal_cases.json
  def create
    @legal_case = LegalCase.new(legal_case_params)

    respond_to do |format|
      if @legal_case.save
        format.html { redirect_to @legal_case, notice: "Processo cadastrado com sucesso." }
        format.json { render :show, status: :created, location: @legal_case }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @legal_case.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /legal_cases/1 or /legal_cases/1.json
  def update
    respond_to do |format|
      if @legal_case.update(legal_case_params)
        format.html { redirect_to @legal_case, notice: "Processo atualizado com sucesso.", status: :see_other }
        format.json { render :show, status: :ok, location: @legal_case }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @legal_case.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /legal_cases/1 or /legal_cases/1.json
  def destroy
    @legal_case.destroy!

    respond_to do |format|
      format.html { redirect_to legal_cases_path, notice: "Processo excluído com sucesso.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_legal_case
      @legal_case = LegalCase.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def legal_case_params
      params.expect(legal_case: [ :internal_number, :external_number, :entry_date, :protocol_date, :process_type, :legal_area, :legal_area_id, :process_type_id, :subarea, :main_subject, :court, :district, :court_id, :district_id, :phase, :status, :responsible_name, :support_team, :opposing_party, :claim_value, :priority, :strategic_notes, :client_id ])
    end
end
