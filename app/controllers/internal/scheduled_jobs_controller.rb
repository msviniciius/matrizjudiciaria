module Internal
  class ScheduledJobsController < ActionController::API
    before_action :authenticate_job_trigger!

    JOBS = {
      "pje_case_events" => Pje::Ma::ImportCaseEventsJob,
      "djma_publications" => Integrations::Djma::ImportPublicationsJob
    }.freeze

    def import_case_events
      run_job!("pje_case_events")
    end

    def import_djma_publications
      run_job!("djma_publications")
    end

    private

    def authenticate_job_trigger!
      expected_token = ENV["JOB_TRIGGER_TOKEN"].to_s
      actual_token = request.authorization.to_s.delete_prefix("Bearer ").strip

      return if expected_token.present? &&
        actual_token.present? &&
        ActiveSupport::SecurityUtils.secure_compare(actual_token, expected_token)

      render json: { error: "unauthorized" }, status: :unauthorized
    end

    def run_job!(job_name)
      started_at = Time.current
      started_clock = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      result = JOBS.fetch(job_name).perform_now({})
      duration_ms = elapsed_ms(started_clock)
      run = record_run!(job_name: job_name, status: "success", result: result, started_at: started_at, duration_ms: duration_ms)

      render json: response_payload(run)
    rescue => error
      duration_ms = elapsed_ms(started_clock || Process.clock_gettime(Process::CLOCK_MONOTONIC))
      run = record_run!(job_name: job_name, status: "failed", result: {}, error_message: error.message, started_at: started_at || Time.current, duration_ms: duration_ms)
      Rails.logger.error "[ScheduledJobs] #{job_name} falhou duration_ms=#{duration_ms} error=#{error.class}: #{error.message}"

      render json: response_payload(run).merge(error: error.message), status: :bad_gateway
    end

    def record_run!(job_name:, status:, result:, started_at:, duration_ms:, error_message: nil)
      finished_at = started_at + (duration_ms / 1000.0)
      ScheduledJobRun.create!(
        job_name: job_name,
        status: status,
        duration_ms: duration_ms,
        result: result || {},
        error_message: error_message,
        started_at: started_at,
        finished_at: finished_at
      )
    end

    def response_payload(run)
      {
        ok: run.status == "success",
        job: run.job_name,
        status: run.status,
        duration_ms: run.duration_ms,
        result: run.result,
        run_id: run.id
      }
    end

    def elapsed_ms(started_clock)
      ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_clock) * 1000).round
    end
  end
end
