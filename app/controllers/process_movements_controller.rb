class ProcessMovementsController < ApplicationController
  before_action :set_process_movement, only: %i[show edit update destroy]

  def index
    @filters = filter_params.to_h.symbolize_keys
    @process_movements = filtered_scope
      .includes(:process, :movement_type, :movement_template, :exam, :phase)
      .recent

    @reports = {
      por_fase: ProcessMovement.joins(:phase).group("process_phases.name").count,
      por_tipo: ProcessMovement.joins(:movement_type).group("movement_types.name").count,
      por_natureza: ProcessMovement.group(:nature).count,
      por_impacto: ProcessMovement.group(:impact).count,
      por_origem: ProcessMovement.group(:origin).count
    }
  end

  def show
  end

  def new
    @process_movement = ProcessMovement.new(process_id: params[:process_id])
  end

  def edit
  end

  def create
    @process_movement = ProcessMovement.new(process_movement_params)

    if @process_movement.save
      redirect_to @process_movement, notice: "Andamento processual cadastrado com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @process_movement.update(process_movement_params)
      redirect_to @process_movement, notice: "Andamento processual atualizado com sucesso.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @process_movement.destroy!
    redirect_to process_movements_path, notice: "Andamento processual excluído com sucesso.", status: :see_other
  end

  private

  def set_process_movement
    @process_movement = ProcessMovement.find(params.expect(:id))
  end

  def filtered_scope
    scope = ProcessMovement.active

    if @filters[:phase_id].present?
      scope = scope.where(phase_id: @filters[:phase_id])
    end

    if @filters[:status].present?
      scope = scope.joins(:process).where(legal_cases: { status: @filters[:status] })
    end

    if @filters[:movement_type_id].present?
      scope = scope.where(movement_type_id: @filters[:movement_type_id])
    end

    if @filters[:nature].present?
      scope = scope.where(nature: @filters[:nature])
    end

    if @filters[:impact].present?
      scope = scope.where(impact: @filters[:impact])
    end

    if @filters[:origin].present?
      scope = scope.where(origin: @filters[:origin])
    end

    if @filters[:from].present?
      scope = scope.where("event_date >= ?", Time.zone.parse(@filters[:from]).beginning_of_day)
    end

    if @filters[:to].present?
      scope = scope.where("event_date <= ?", Time.zone.parse(@filters[:to]).end_of_day)
    end

    if @filters[:responsible_name].present?
      scope = scope.joins(:process).where("LOWER(legal_cases.responsible_name) LIKE ?", "%#{@filters[:responsible_name].downcase}%")
    end

    if @filters[:exam_id].present?
      scope = scope.where(exam_id: @filters[:exam_id])
    end

    if @filters[:administrative_situation].present?
      scope = scope.where(administrative_situation: @filters[:administrative_situation])
    end

    scope.distinct
  end

  def filter_params
    params.permit(
      :phase_id,
      :status,
      :movement_type_id,
      :nature,
      :impact,
      :origin,
      :from,
      :to,
      :responsible_name,
      :exam_id,
      :administrative_situation
    )
  end

  def process_movement_params
    params.expect(process_movement: [
      :process_id,
      :phase_id,
      :movement_type_id,
      :movement_template_id,
      :exam_id,
      :event_date,
      :display_title,
      :complementary_description,
      :nature,
      :impact,
      :origin,
      :administrative_situation,
      :updates_phase,
      :next_phase_id,
      :creates_task,
      :creates_deadline,
      :created_by_user_id,
      :active
    ])
  end
end
