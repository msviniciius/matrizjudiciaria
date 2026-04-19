class DeadlinesController < ApplicationController
  before_action :set_deadline, only: %i[ show edit update destroy ]

  # GET /deadlines or /deadlines.json
  def index
    @deadlines = Deadline.joins(:legal_case).where(legal_cases: { office_id: current_office.id })
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

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_deadline
      @deadline = Deadline.joins(:legal_case).where(legal_cases: { office_id: current_office.id }).find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def deadline_params
      params.expect(deadline: [ :legal_case_id, :title, :deadline_type, :start_date, :due_date, :status, :priority, :completed_at, :delay_reason, :responsible_name ])
    end

    def ensure_deadline_office_scope!
      return if @deadline.legal_case.blank?
      return if @deadline.legal_case.office_id == current_office.id

      raise ActiveRecord::RecordNotFound
    end
end
