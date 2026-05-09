class LegalCasesController < ApplicationController
  before_action :set_legal_case, only: %i[ show edit update destroy print pdf google_calendar ]

  def index
    @filters = legal_case_filters
    scope = current_office.legal_cases.includes(:client).order(updated_at: :desc)

    if @filters[:q].present?
      term = "%#{@filters[:q].strip}%"
      scope = scope.joins(:client).where(
        "legal_cases.internal_number ILIKE :term
         OR clients.full_name ILIKE :term
         OR COALESCE(legal_cases.main_subject, '') ILIKE :term
         OR COALESCE(legal_cases.opposing_party, '') ILIKE :term
         OR COALESCE(legal_cases.last_movement, '') ILIKE :term",
        term: term
      )
    end

    scope = scope.where(phase: @filters[:phase]) if @filters[:phase].present?
    scope = scope.where(status: @filters[:status]) if @filters[:status].present?
    scope = scope.where(priority: @filters[:priority]) if @filters[:priority].present?

    if @filters[:responsible_name].present?
      responsible_term = "%#{@filters[:responsible_name].strip}%"
      scope = scope.where("COALESCE(legal_cases.responsible_name, '') ILIKE ?", responsible_term)
    end

    case @filters[:deadline_state]
    when "overdue"
      scope = scope.where("next_deadline_on < ?", Date.current)
    when "today"
      scope = scope.where(next_deadline_on: Date.current)
    when "upcoming"
      scope = scope.where(next_deadline_on: Date.current..(Date.current + 7.days))
    when "without_deadline"
      scope = scope.where(next_deadline_on: nil)
    end

    @legal_cases = scope
    @advanced_filters_open = false
  end

  def show
    load_case_related_collections
  end

  def pdf
    load_case_related_collections
    exporter = LegalCasePdfExporter.new(
      legal_case: @legal_case,
      timeline_items: @timeline_items,
      deadlines: @deadlines,
      tasks: @tasks,
      process_exams: @process_exams
    )

    send_data(
      exporter.to_pdf,
      type: "application/pdf",
      disposition: "attachment",
      filename: "processo-#{@legal_case.internal_number.parameterize}.pdf"
    )
  rescue LoadError, NameError
    flash[:warning] = "Exportação em PDF indisponível no momento. Abra a versão para impressão e salve como PDF."
    redirect_to print_legal_case_path(@legal_case)
  end

  def print
    load_case_related_collections
    render :pdf, layout: false
  end

  def daily_closure
    @reference_date = parse_reference_date(params[:reference_date])
    @closure_rows = DailyClosureReport.new(reference_date: @reference_date, scope: current_office.legal_cases).rows
  end

  def google_calendar
    public_base_url = ENV["APP_PUBLIC_URL"].presence || request.base_url
    feed_url = "#{public_base_url.chomp('/')}#{legal_case_calendar_feed_path(token: @legal_case.calendar_feed_token)}"
    subscribe_url = feed_url.sub(/\Ahttps?:\/\//, "webcal://")
    google_url = GoogleCalendarLinkBuilder.subscribe_url(subscribe_url)

    redirect_to google_url, allow_other_host: true
  end

  def new
    @legal_case = current_office.legal_cases.new(
      internal_number: LegalCase.next_internal_number_preview(current_office),
      phase: current_office.default_phase,
      status: current_office.default_status,
      priority: current_office.default_priority,
      responsible_name: current_user&.name
    )
  end

  def edit
  end

  def create
    @legal_case = current_office.legal_cases.new(legal_case_params)
    @legal_case.responsible_name = current_user&.name
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
    permitted = [
      :entry_date,
      :protocol_date,
      :process_type_id,
      :legal_area_id,
      :subarea,
      :court_id,
      :district_id,
      :phase,
      :status,
      :support_team,
      :opposing_party,
      :claim_value,
      :priority,
      :strategic_notes,
      :client_id,
      :last_movement,
      :last_movement_at,
      :next_deadline_on,
      :tem_pericia,
      :observacao_geral_pericia
    ]

    permitted << :responsible_name if current_user&.admin?

    params.expect(legal_case: permitted)
  end

  def load_case_related_collections
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

  def legal_case_filters
    params.permit(:q, :phase, :status, :priority, :responsible_name, :deadline_state)
  end
end
