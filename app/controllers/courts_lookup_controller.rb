class CourtsLookupController < ApplicationController
  def index
    district = District.find(params.expect(:district_id))
    courts = district.courts.order(:name)

    render json: courts.select(:id, :name)
  end
end
