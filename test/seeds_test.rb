require "test_helper"

class SeedsTest < ActiveSupport::TestCase
  include ActiveSupport::Testing::TimeHelpers

  test "seeds calculam pascoa de 2026 e 2027 e seus feriados derivados" do
    travel_to Date.new(2026, 10, 21) do
      Rails.application.load_seed

      assert_national_holiday Date.new(2026, 4, 3), "Paixão de Cristo"
      assert_national_holiday Date.new(2026, 6, 4), "Corpus Christi"
      assert_forensic_holiday Date.new(2026, 4, 2), "Semana Santa"

      assert_national_holiday Date.new(2027, 3, 26), "Paixão de Cristo"
      assert_national_holiday Date.new(2027, 5, 27), "Corpus Christi"
      assert_forensic_holiday Date.new(2027, 3, 25), "Semana Santa"

      counts = [ Feriado.count, Suspensao.count ]
      Rails.application.load_seed
      assert_equal counts, [ Feriado.count, Suspensao.count ]
    end
  end

  private

  def assert_national_holiday(date, description)
    assert Feriado.exists?(data: date, ambito: :nacional, office_id: nil, descricao: description),
      "expected national holiday #{description.inspect} on #{date} (Easter 2/60-day offsets)"
  end

  def assert_forensic_holiday(date, description)
    assert Feriado.exists?(data: date, ambito: :forense, office_id: nil, descricao: description),
      "expected forensic holiday #{description.inspect} on #{date} (Easter 3-day offset)"
  end
end
