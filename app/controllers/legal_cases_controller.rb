class LegalCasesController < ApplicationController
  before_action :set_legal_case, only: %i[ show edit update destroy ]

  def index
    @legal_cases = LegalCase.order(updated_at: :desc)

    @report_counts = {
      por_fase: LegalCase.group(:phase).count,
      prazo_proximo: LegalCase.with_upcoming_deadline.count,
      sem_prazo: LegalCase.without_deadline.count,
      com_pericia: LegalCase.with_pericia.count,
      com_exigencia_pendente: LegalCase.with_pending_requirement.count
    }
  end

  def show
    @process_movements = @legal_case.process_movements
      .includes(:movement_type, :movement_template, :exam, :phase, :next_phase)
      .recent

    @legacy_case_events = @legal_case.case_events
      .includes(:movement_type, :process_exam)
      .order(occurred_at: :desc)

    @timeline_items = build_timeline(@process_movements, @legacy_case_events)

    @deadlines = @legal_case.deadlines.order(due_date: :asc)
    @tasks = @legal_case.tasks.order(due_date: :asc)
    @process_exams = @legal_case.process_exams.order(Arel.sql("scheduled_at IS NULL, scheduled_at ASC"))
  end

  def new
    @legal_case = LegalCase.new
  end

  def edit
  end

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

  def destroy
    @legal_case.destroy!

    respond_to do |format|
      format.html { redirect_to legal_cases_path, notice: "Processo excluído com sucesso.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private

  def set_legal_case
    @legal_case = LegalCase.find(params.expect(:id))
  end

  def legal_case_params
    params.expect(legal_case: [
      :internal_number,
      :external_number,
      :entry_date,
      :protocol_date,
      :process_type_id,
      :legal_area_id,
      :subarea,
      :main_subject,
      :court_id,
      :district_id,
      :phase,
      :status,
      :responsible_name,
      :support_team,
      :opposing_party,
      :claim_value,
      :priority,
      :strategic_notes,
      :client_id,
      :next_action,
      :next_deadline_on,
      :tem_pericia,
      :observacao_geral_pericia
    ])
  end

  def build_timeline(process_movements, legacy_case_events)
    movement_items = process_movements.map do |movement|
      {
        source: :process_movement,
        title: movement.display_title,
        description: movement.complementary_description,
        date: movement.event_date,
        nature: movement.nature,
        highlight: movement.nature_fato_processual? || movement.nature_fato_administrativo?,
        movement_type: movement.movement_type&.name,
        exam: movement.exam,
        origin: movement.origin,
        administrative_situation: movement.administrative_situation
      }
    end

    legacy_items = legacy_case_events.map do |event|
      {
        source: :legacy_case_event,
        title: event.description,
        description: "Registro legado (case_events)",
        date: event.occurred_at,
        nature: event.entry_kind,
        highlight: false,
        movement_type: event.movement_type&.name,
        exam: event.process_exam,
        origin: "legado",
        administrative_situation: nil
      }
    end

    (movement_items + legacy_items).sort_by { |item| item[:date] || Time.at(0) }.reverse
  end
end
