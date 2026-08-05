require "test_helper"

class InternalScheduledJobsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @token = "test-trigger-token"
    @previous_token = ENV["JOB_TRIGGER_TOKEN"]
    ENV["JOB_TRIGGER_TOKEN"] = @token
  end

  teardown do
    @previous_token.nil? ? ENV.delete("JOB_TRIGGER_TOKEN") : ENV["JOB_TRIGGER_TOKEN"] = @previous_token
  end

  test "rejects requests without the internal trigger token" do
    post internal_jobs_import_case_events_path, as: :json

    assert_response :unauthorized
    assert_equal "unauthorized", response.parsed_body.fetch("error")
  end

  test "runs case events import immediately and records performance" do
    calls = []
    stub_job(Pje::Ma::ImportCaseEventsJob, ->(params = {}) {
      calls << params
      { imported: 2, skipped: 1, errors: 0 }
    }) do
      assert_difference("ScheduledJobRun.count", 1) do
        post internal_jobs_import_case_events_path,
          headers: authorization_header,
          as: :json
      end
    end

    assert_response :success
    body = response.parsed_body
    run = ScheduledJobRun.last

    assert_equal "pje_case_events", body.fetch("job")
    assert_equal "success", body.fetch("status")
    assert_operator body.fetch("duration_ms"), :>=, 0
    assert_equal [ {} ], calls
    assert_equal "pje_case_events", run.job_name
    assert_equal "success", run.status
    assert_equal({ "imported" => 2, "skipped" => 1, "errors" => 0 }, run.result)
    assert_operator run.duration_ms, :>=, 0
  end

  test "runs djma publications import immediately" do
    calls = []
    stub_job(Integrations::Djma::ImportPublicationsJob, ->(params = {}) {
      calls << params
      { imported: 1, skipped: 0, errors: 0 }
    }) do
      post internal_jobs_import_djma_publications_path,
        headers: authorization_header,
        as: :json
    end

    assert_response :success
    assert_equal "djma_publications", response.parsed_body.fetch("job")
    assert_equal [ {} ], calls
  end

  test "records job failures with duration" do
    stub_job(Pje::Ma::ImportCaseEventsJob, ->(*) { raise "boom" }) do
      assert_difference("ScheduledJobRun.count", 1) do
        post internal_jobs_import_case_events_path,
          headers: authorization_header,
          as: :json
      end
    end

    assert_response :bad_gateway
    body = response.parsed_body
    run = ScheduledJobRun.last

    assert_equal "failed", body.fetch("status")
    assert_equal "boom", body.fetch("error")
    assert_equal "failed", run.status
    assert_equal "boom", run.error_message
    assert_operator run.duration_ms, :>=, 0
  end

  private

  def authorization_header
    { "Authorization" => "Bearer #{@token}" }
  end

  def stub_job(job_class, callable)
    original = job_class.method(:perform_now)
    job_class.define_singleton_method(:perform_now) { |params = {}| callable.call(params) }
    yield
  ensure
    job_class.define_singleton_method(:perform_now, original)
  end
end
