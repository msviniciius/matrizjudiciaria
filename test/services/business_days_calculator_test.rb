require "test_helper"

class BusinessDaysCalculatorTest < ActiveSupport::TestCase
  setup do
    @office = default_office
    @other_office = Office.create!(name: "Outro Escritorio")
    @monday = Date.new(2026, 9, 7)
  end

  test "identifica dias de semana e rejeita fim de semana" do
    calculator = BusinessDaysCalculator.new(office: @office)

    assert calculator.dia_util?(Date.new(2026, 9, 8))
    refute calculator.dia_util?(Date.new(2026, 9, 12))
    refute calculator.dia_util?(Date.new(2026, 9, 13))
  end

  test "considera feriados globais e do escritorio, mas ignora feriado de outro escritorio" do
    Feriado.create!(data: @monday, descricao: "Feriado global", ambito: :nacional)
    Feriado.create!(data: @monday + 1.day, descricao: "Feriado local", ambito: :municipal, office: @office)
    Feriado.create!(data: @monday + 2.days, descricao: "Feriado externo", ambito: :municipal, office: @other_office)
    calculator = BusinessDaysCalculator.new(office: @office)

    refute calculator.dia_util?(@monday)
    refute calculator.dia_util?(@monday + 1.day)
    assert calculator.dia_util?(@monday + 2.days)
  end

  test "considera suspensao ou recesso em todo o intervalo inclusivo" do
    Suspensao.create!(
      inicio: @monday + 1.day,
      fim: @monday + 3.days,
      descricao: "Recesso forense",
      office: @office
    )
    calculator = BusinessDaysCalculator.new(office: @office)

    assert_equal @monday + 4.days, calculator.proximo_dia_util(@monday + 1.day)
    refute calculator.dia_util?(@monday + 2.days)
  end

  test "soma dias uteis atravessando fim de semana e feriado" do
    Feriado.create!(data: @monday, descricao: "Feriado", ambito: :nacional)
    calculator = BusinessDaysCalculator.new(office: @office)

    assert_equal Date.new(2026, 9, 9), calculator.somar_dias_uteis(Date.new(2026, 9, 4), 2)
  end

  test "soma dias uteis comuns sem incluir a data inicial" do
    calculator = BusinessDaysCalculator.new(office: @office)

    assert_equal Date.new(2026, 9, 9), calculator.somar_dias_uteis(Date.new(2026, 9, 7), 2)
  end

  test "somar zero dias uteis preserva a data inicial" do
    calculator = BusinessDaysCalculator.new(office: @office)
    date = Date.new(2026, 9, 7)

    assert_equal date, calculator.somar_dias_uteis(date, 0)
  end

  test "soma dias uteis atravessa feriados e suspensoes consecutivos" do
    Feriado.create!(data: @monday, descricao: "Feriado", ambito: :nacional)
    Suspensao.create!(
      inicio: @monday + 1.day,
      fim: @monday + 2.days,
      descricao: "Recesso",
      office: @office
    )
    calculator = BusinessDaysCalculator.new(office: @office)

    assert_equal Date.new(2026, 9, 10), calculator.somar_dias_uteis(Date.new(2026, 9, 4), 1)
  end

  test "conta dias uteis de forma inclusiva no intervalo" do
    Feriado.create!(data: @monday, descricao: "Feriado", ambito: :nacional)
    Suspensao.create!(
      inicio: Date.new(2026, 9, 9),
      fim: Date.new(2026, 9, 9),
      descricao: "Suspensao",
      office: @office
    )
    calculator = BusinessDaysCalculator.new(office: @office)

    assert_equal 3, calculator.dias_uteis_entre(Date.new(2026, 9, 7), Date.new(2026, 9, 11))
    assert_equal 0, calculator.dias_uteis_entre(Date.new(2026, 9, 12), Date.new(2026, 9, 13))
  end

  test "usa o escritorio do caso quando nenhum escritorio e informado" do
    legal_case = create_full_legal_case(office: @office)
    Feriado.create!(data: @monday, descricao: "Feriado local", ambito: :municipal, office: @office)
    Feriado.create!(data: @monday + 1.day, descricao: "Feriado externo", ambito: :municipal, office: @other_office)

    calculator = BusinessDaysCalculator.new(legal_case: legal_case)

    refute calculator.dia_util?(@monday)
    assert calculator.dia_util?(@monday + 1.day)
  end

  test "carrega somente calendario sobre o intervalo consultado" do
    queries = []
    subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |_name, _start, _finish, _id, payload|
      queries << payload[:sql] if payload[:sql].include?("feriados") || payload[:sql].include?("suspensoes")
    end

    BusinessDaysCalculator.new(reference_date: @monday, office: @office).dia_util?(@monday)
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber)
    assert queries.any? { |sql| sql.match?(/WHERE.*"feriados"\."data"/) }
    assert queries.any? { |sql| sql.match?(/WHERE.*inicio/) && sql.match?(/WHERE.*fim/) }
  end
end
