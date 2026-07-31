class LegalCasesController < ApplicationController
  before_action :set_legal_case, only: %i[ show edit update destroy print pdf google_calendar sync ]

  def index
    @filters = legal_case_filters
    if request.format.json?
      render json: LegalCasesSnapshot.new(
        office: current_office,
        unit: current_unit,
        all_units_mode: all_units_mode?,
        filters: @filters
      ).as_json
      return
    end

    scope = scope_by_current_unit(current_office.legal_cases).includes(:client).order(updated_at: :desc)
    scope = LegalCaseQuery.new(scope, @filters).call

    @legal_cases = scope
    @new_events_case_ids = current_office.legal_cases.with_new_imported_events.pluck(:id).to_set
    @advanced_filters_open = false
  end

  def show
    if request.format.json?
      render json: LegalCaseShowSnapshot.new(legal_case: @legal_case).as_json
      return
    end

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
    @closure_rows = DailyClosureReport.new(reference_date: @reference_date, scope: scope_by_current_unit(current_office.legal_cases)).rows
  end

  def google_calendar
    public_base_url = ENV["APP_PUBLIC_URL"].presence || request.base_url
    feed_url = "#{public_base_url.chomp('/')}#{legal_case_calendar_feed_path(token: @legal_case.calendar_feed_token)}"
    subscribe_url = feed_url.sub(/\Ahttps?:\/\//, "webcal://")
    google_url = GoogleCalendarLinkBuilder.subscribe_url(subscribe_url)

    redirect_to google_url, allow_other_host: true
  end

  def sync
    if @legal_case.external_number.blank?
      return sync_error("Este processo não possui número externo (CNJ) configurado.", :unprocessable_entity)
    end

    # Sincrono para feedback imediato (a API do CNJ leva ~8s)
    result = sync_importer.call(legal_case_ids: [ @legal_case.id ], limit: 1)
    message, status = sync_feedback(result)

    sync_success(message, status)
  rescue => e
    Rails.logger.error "[PJE_MA] Erro na sincronização manual: #{e.message}"
    sync_error("Erro ao sincronizar: #{e.message}", :internal_server_error)
  end

  def new
    @legal_case = current_office.legal_cases.new(
      internal_number: LegalCase.next_internal_number_preview(current_office),
      phase: current_office.default_phase,
      status: current_office.default_status,
      priority: current_office.default_priority,
      client_id: permitted_prefill_client_id,
      responsible_name: current_user&.name,
      unit: current_unit
    )
    @legal_case.process_exams.build if @legal_case.process_exams.empty?
  end

  def edit
    @legal_case.process_exams.build if @legal_case.process_exams.empty?
  end

  def create
    @legal_case = current_office.legal_cases.new(legal_case_params)
    @legal_case.responsible_name = current_user&.name if @legal_case.responsible_name.blank?
    @legal_case.unit ||= current_unit
    @legal_case.process_exams.each { |exam| exam.created_by_user_id ||= current_user.id }

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
    @legal_case.assign_attributes(legal_case_params)
    @legal_case.process_exams.each { |exam| exam.created_by_user_id ||= current_user.id }

    respond_to do |format|
      if @legal_case.save
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
    @legal_case = scope_by_current_unit(current_office.legal_cases).find(params.expect(:id))
  end

  def permitted_prefill_client_id
    return if params[:client_id].blank?

    scope_by_current_unit(current_office.clients).find_by(id: params[:client_id])&.id
  end

  def legal_case_params
    permitted = [
      :entry_date,
      :protocol_date,
      :process_type_id,
      :legal_area_id,
      :court_id,
      :district_id,
      :phase,
      :status,
      :opposing_party,
      :claim_value,
      :priority,
      :client_id,
      :internal_number,
      :external_number,
      :subarea,
      :main_subject,
      :next_action,
      :last_movement,
      :last_movement_at,
      :next_deadline_on,
      :tem_pericia,
      process_exams_attributes: [
        :id,
        :exam_nature,
        :exam_scope,
        :status,
        :scheduled_at,
        :location,
        :expert_name,
        :notes,
        :active,
        :_destroy
      ]
    ]

    permitted << :responsible_name

    params.require(:legal_case).permit(*permitted)
  end

  def load_case_related_collections
    @process_movements = @legal_case.process_movements
      .includes(:movement_type, :movement_template, :exam, :phase, :next_phase)
      .recent

    @legacy_case_events = @legal_case.case_events
      .includes(:movement_type, :process_exam)
      .order(created_at: :desc)

    @timeline_items = TimelineBuilder.build(
      process_movements: @process_movements,
      case_events: @legacy_case_events
    )

    @deadlines = @legal_case.deadlines.order(due_date: :asc)
    @tasks = @legal_case.tasks.order(due_date: :asc)
    @process_exams = @legal_case.process_exams.order(Arel.sql("scheduled_at IS NULL, scheduled_at ASC"))
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

  def sync_feedback(result)
    if result[:imported] > 0
      [ "#{result[:imported]} andamento(s) novo(s) importado(s) do CNJ. #{result[:skipped]} já existiam.", :notice ]
    elsif result[:skipped] > 0
      [ "Nenhum andamento novo. #{result[:skipped]} já estavam sincronizados.", :notice ]
    else
      [ "Nenhum andamento encontrado para este processo no CNJ.", :alert ]
    end
  end

  def sync_json_request?
    request.headers["Accept"] == "application/json"
  end

  def sync_importer
    request.env.fetch("legal_cases.sync_importer") { Pje::Ma::ImportCaseEventsJob.method(:perform_now) }
  end

  def sync_success(message, status)
    return render json: { message: message, level: status.to_s } if sync_json_request?

    redirect_to @legal_case, flash: { status => message }
  end

  def sync_error(message, status)
    return render json: { error: message }, status: status if sync_json_request?

    redirect_to @legal_case, alert: message
  end

  def legal_case_filters
    params.permit(:q, :phase, :status, :priority, :responsible_name, :deadline_state, :health, :without_next_action, :operational)
  end
end
