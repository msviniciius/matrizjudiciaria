class TasksController < ApplicationController
  before_action :set_task, only: %i[ show edit update destroy ]

  # GET /tasks or /tasks.json
  def index
    @filters = task_filters
    scope = Task
      .joins(:legal_case)
      .where(legal_cases: { office_id: current_office.id })
      .includes(:legal_case)
      .order(due_date: :asc, created_at: :desc)
    scope = scope_by_current_unit(scope, through: :legal_cases)

    if @filters[:q].present?
      term = "%#{@filters[:q].strip}%"
      scope = scope.where(
        "COALESCE(tasks.title, '') ILIKE :term
         OR COALESCE(tasks.description, '') ILIKE :term
         OR COALESCE(tasks.responsible_name, '') ILIKE :term
         OR COALESCE(legal_cases.internal_number, '') ILIKE :term",
        term: term
      )
    end

    scope = scope.where(status: @filters[:status]) if @filters[:status].present?
    scope = scope.where(priority: @filters[:priority]) if @filters[:priority].present?
    scope = scope.where("COALESCE(tasks.responsible_name, '') ILIKE ?", "%#{@filters[:responsible_name].strip}%") if @filters[:responsible_name].present?

    case @filters[:due_state]
    when "overdue"
      scope = scope.where("tasks.due_date < ?", Date.current)
    when "today"
      scope = scope.where(due_date: Date.current)
    when "upcoming"
      scope = scope.where(due_date: Date.current..(Date.current + 7.days))
    when "without_due_date"
      scope = scope.where(due_date: nil)
    end

    @tasks = scope
    @advanced_filters_open = false

    return unless request.format.json?

    render json: TasksSnapshot.new(
      office: current_office,
      unit: current_unit,
      tasks: @tasks,
      filters: @filters
    ).as_json
  end

  # GET /tasks/1 or /tasks/1.json
  def show
  end

  # GET /tasks/new
  def new
    @task = Task.new
  end

  # GET /tasks/1/edit
  def edit
  end

  # POST /tasks or /tasks.json
  def create
    @task = Task.new(task_params)
    ensure_task_office_scope!

    respond_to do |format|
      if @task.save
        format.html { redirect_to @task, notice: "Tarefa cadastrada com sucesso." }
        format.json { render :show, status: :created, location: @task }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @task.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /tasks/1 or /tasks/1.json
  def update
    respond_to do |format|
      if @task.update(task_params)
        format.html { redirect_to @task, notice: "Tarefa atualizada com sucesso.", status: :see_other }
        format.json { render :show, status: :ok, location: @task }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @task.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /tasks/1 or /tasks/1.json
  def destroy
    @task.destroy!

    respond_to do |format|
      format.html { redirect_to tasks_path, notice: "Tarefa excluída com sucesso.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_task
      @task = Task.joins(:legal_case).where(legal_cases: { office_id: current_office.id }).find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def task_params
      params.expect(task: [ :legal_case_id, :title, :description, :status, :priority, :due_date, :responsible_name ])
    end

    def ensure_task_office_scope!
      return if @task.legal_case.blank?
      return if @task.legal_case.office_id == current_office.id

      raise ActiveRecord::RecordNotFound
    end

    def task_filters
      params.permit(:q, :status, :priority, :responsible_name, :due_state)
    end
end
