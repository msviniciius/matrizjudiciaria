class ProcessTypesController < ApplicationController
  def index
    legal_area = LegalArea.find(params.expect(:legal_area_id))
    process_types = legal_area.process_types.order(:name)

    render json: process_types.select(:id, :name)
  end
end
