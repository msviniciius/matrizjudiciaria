class MovementTemplatesController < ApplicationController
  before_action :set_movement_template, only: %i[show edit update destroy]

  def index
    @movement_templates = MovementTemplate.includes(:phase, :movement_type, :next_phase).order(:order, :name)
  end

  def show
  end

  def new
    @movement_template = MovementTemplate.new(active: true)
  end

  def edit
  end

  def create
    @movement_template = MovementTemplate.new(movement_template_params)

    if @movement_template.save
      redirect_to @movement_template, notice: "Modelo de andamento cadastrado com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @movement_template.update(movement_template_params)
      redirect_to @movement_template, notice: "Modelo de andamento atualizado com sucesso.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @movement_template.destroy!
    redirect_to movement_templates_path, notice: "Modelo de andamento excluído com sucesso.", status: :see_other
  end

  private

  def set_movement_template
    @movement_template = MovementTemplate.find(params.expect(:id))
  end

  def movement_template_params
    params.expect(movement_template: [
      :phase_id,
      :movement_type_id,
      :code,
      :name,
      :short_description,
      :nature_default,
      :impact_default,
      :updates_phase,
      :next_phase_id,
      :creates_task,
      :task_template_name,
      :creates_deadline,
      :deadline_template_name,
      :requires_exam_id,
      :active,
      :order
    ])
  end
end
