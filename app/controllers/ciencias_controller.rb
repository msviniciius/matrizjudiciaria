class CienciasController < ApplicationController
  def create
    @expediente = scoped_expedientes.find(ciencia_params.fetch(:expediente_id))
    @ciencia = @expediente.build_ciencia(ciencia_params.except(:expediente_id).merge(tipo: :expressa, user: current_user))

    Ciencia.transaction do
      @ciencia.save!
      DeadlineCalculator.new(@expediente.deadline).recalcular!
    end

    respond_to do |format|
      format.html { redirect_to @expediente.legal_case, notice: "Ciência expressa registrada com sucesso." }
      format.json { render json: ciencia_payload, status: :created, location: @expediente.legal_case }
    end
  rescue ActiveRecord::RecordInvalid => error
    respond_to do |format|
      format.html { redirect_to @expediente&.legal_case || root_path, alert: error.record.errors.full_messages.to_sentence }
      format.json { render json: { errors: error.record.errors }, status: :unprocessable_entity }
    end
  end

  private

  def scoped_expedientes
    scope = Expediente.joins(:legal_case).where(legal_cases: { office_id: current_office.id })
    scope_by_current_unit(scope, through: :legal_cases)
  end

  def ciencia_params
    params.expect(ciencia: [ :expediente_id, :data_ciencia ])
  end

  def ciencia_payload
    {
      ciencia: @ciencia.as_json,
      deadline: @expediente.deadline.reload.as_json
    }
  end
end
