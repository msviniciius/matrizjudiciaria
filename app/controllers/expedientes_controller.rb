class ExpedientesController < ApplicationController
  def create
    @legal_case = scoped_legal_cases.find(expediente_params.fetch(:legal_case_id))
    @expediente = @legal_case.expedientes.new(expediente_params.except(:legal_case_id))

    respond_to do |format|
      if @expediente.save
        format.html { redirect_to @legal_case, notice: "Expediente cadastrado com sucesso." }
        format.json { render json: expediente_payload, status: :created, location: @legal_case }
      else
        format.html { redirect_to @legal_case, alert: @expediente.errors.full_messages.to_sentence }
        format.json { render json: { errors: @expediente.errors }, status: :unprocessable_entity }
      end
    end
  end

  private

  def scoped_legal_cases
    scope_by_current_unit(current_office.legal_cases)
  end

  def expediente_params
    params.expect(expediente: [
      :legal_case_id,
      :tipo,
      :descricao,
      :data_disponibilizacao,
      :quantidade_dias,
      :contagem,
      :prazo_em_dobro,
      :origem,
      :referencia_externa,
      :referencia_evento
    ])
  end

  def expediente_payload
    {
      expediente: @expediente.as_json,
      deadline: @expediente.deadline&.as_json
    }
  end
end
