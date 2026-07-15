class ProcessMovementsController < ApplicationController
  before_action :set_process_movement, only: %i[show edit update destroy]

  def index
    @filters = filter_params.to_h.symbolize_keys
    @process_movements = filtered_scope
      .includes(:process, :movement_type, :movement_template, :exam, :phase)
      .recent

    @reports = {
      por_fase: office_process_movements.joins(:phase).group("process_phases.name").count,
      por_tipo: office_process_movements.joins(:movement_type).group("movement_types.name").count,
      por_natureza: office_process_movements.group(:nature).count,
      por_impacto: office_process_movements.group(:impact).count,
      por_origem: office_process_movements.group(:origin).count
    }

    @advanced_filters_open = @filters.except(:q).values.any?(&:present?)
  end

  def show
  end

  def new
    @process_movement = ProcessMovement.new(process_id: params[:process_id], creates_deadline: true)
  end

  def edit
  end

  def create
    @process_movement = ProcessMovement.new(process_movement_params)
    @process_movement.created_by_user_id ||= current_user.id
    ensure_process_movement_office_scope!

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
    @process_movement = office_process_movements.find(params.expect(:id))
  end

  def filtered_scope
    scope = office_process_movements.active
    ProcessMovementQuery.new(scope, @filters).call
  end

  def filter_params
    params.permit(
      :q,
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

  def office_process_movements
    ProcessMovement.joins(:process).where(legal_cases: { office_id: current_office.id })
  end

  def ensure_process_movement_office_scope!
    return if @process_movement.process.blank?
    return if @process_movement.process.office_id == current_office.id

    raise ActiveRecord::RecordNotFound
  end
end
