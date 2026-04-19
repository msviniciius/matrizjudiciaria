class LegalCasesController < ApplicationController
  before_action :set_legal_case, only: %i[ show edit update destroy calendar ]

  def index
    @legal_cases = current_office.legal_cases.order(updated_at: :desc)
    operational_scope = current_office.legal_cases.operational

    @report_counts = {
      por_fase: current_office.legal_cases.group(:phase).count,
      prazo_proximo: @legal_cases.with_upcoming_deadline.count,
      sem_prazo: @legal_cases.without_deadline.count,
      com_pericia: @legal_cases.with_pericia.count,
      com_exigencia_pendente: @legal_cases.with_pending_requirement.count,
      saude_critica: @legal_cases.count(&:health_status_vermelho?)
    }

    @risk_counts = {
      vence_hoje: operational_scope.deadline_due_today.count,
      vence_48h: operational_scope.deadline_due_in_48h.count,
      atrasados: operational_scope.deadline_overdue.count,
      sem_proxima_providencia: operational_scope.without_next_action.count
    }

    @risk_queues = {
      vence_hoje: operational_scope.deadline_due_today.order(:next_deadline_on, :updated_at).limit(6),
      vence_48h: operational_scope.deadline_due_in_48h.order(:next_deadline_on, :updated_at).limit(6),
      atrasados: operational_scope.deadline_overdue.order(:next_deadline_on, :updated_at).limit(6),
      sem_proxima_providencia: operational_scope.without_next_action.order(updated_at: :desc).limit(6)
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

  def daily_closure
    @reference_date = parse_reference_date(params[:reference_date])
    @closure_rows = DailyClosureReport.new(reference_date: @reference_date, scope: current_office.legal_cases).rows
  end

  def calendar
    exporter = LegalCaseCalendarExporter.new(@legal_case)

    send_data(
      exporter.to_ics,
      type: "text/calendar; charset=utf-8",
      disposition: "attachment",
      filename: "processo-#{@legal_case.internal_number.parameterize}.ics"
    )
  end

  def new
    @legal_case = current_office.legal_cases.new(
      internal_number: LegalCase.next_internal_number_preview(current_office),
      phase: current_office.default_phase,
      status: current_office.default_status,
      priority: current_office.default_priority
    )
  end

  def edit
  end

  def create
    @legal_case = current_office.legal_cases.new(legal_case_params)
    ensure_legal_case_office_scope!

    respond_to do |format|
      if @legal_case.save
        format.html { redirect_to @legal_case, flash: success_flash("Processo cadastrado com sucesso.", @legal_case) }
        format.json { render :show, status: :created, location: @legal_case }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @legal_case.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    ensure_legal_case_office_scope!

    respond_to do |format|
      if @legal_case.update(legal_case_params)
        format.html { redirect_to @legal_case, status: :see_other, flash: success_flash("Processo atualizado com sucesso.", @legal_case) }
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
    @legal_case = current_office.legal_cases.find(params.expect(:id))
  end

  def legal_case_params
    params.expect(legal_case: [
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
      :last_movement,
      :last_movement_at,
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

  def parse_reference_date(raw_date)
    return Date.current if raw_date.blank?

    Date.parse(raw_date)
  rescue ArgumentError
    Date.current
  end

  def success_flash(message, legal_case)
    payload = { notice: message }
    return payload unless legal_case.next_action_warning?

    payload[:warning] = I18n.t("legal_cases.warnings.next_action_blank")
    payload
  end

  def ensure_legal_case_office_scope!
    return if @legal_case.client.blank?
    return if @legal_case.client.office_id == current_office.id

    raise ActiveRecord::RecordNotFound
  end
end
