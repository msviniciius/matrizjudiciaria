class ProcessExamsController < ApplicationController
  before_action :set_process_exam, only: %i[ edit update destroy ]
  before_action :set_legal_case_from_params, only: %i[ new create ]

  def new
     = .process_exams.new
  end

  def edit
  end

  def create
     = .process_exams.new(process_exam_params)

    if .save
      .update_column(:tem_pericia, true)
      redirect_to legal_case_path(), notice: "Perícia cadastrada com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if .update(process_exam_params)
      redirect_to legal_case_path(.legal_case), notice: "Perícia atualizada com sucesso."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    legal_case = .legal_case
    .destroy!
    legal_case.update_column(:tem_pericia, legal_case.process_exams.active.exists?)
    redirect_to legal_case_path(legal_case), notice: "Perícia removida com sucesso."
  end

  private

  def set_process_exam
     = ProcessExam.find(params.expect(:id))
  end

  def set_legal_case_from_params
     = LegalCase.find(params.expect(:legal_case_id))
  end

  def process_exam_params
    params.expect(process_exam: [ :exam_nature, :exam_scope, :status, :scheduled_at, :location, :expert_name, :notes, :active ])
  end
end
