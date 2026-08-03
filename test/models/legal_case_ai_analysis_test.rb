require "test_helper"

class LegalCaseAiAnalysisTest < ActiveSupport::TestCase
  test "requires generated analysis fields" do
    analysis = LegalCaseAiAnalysis.new

    assert_not analysis.valid?
    assert_includes analysis.errors[:legal_case], "deve existir"
    assert_includes analysis.errors[:provider], "não pode ficar em branco"
    assert_includes analysis.errors[:model], "não pode ficar em branco"
    assert_includes analysis.errors[:summary], "não pode ficar em branco"
    assert_includes analysis.errors[:suggested_action], "não pode ficar em branco"
  end
end
