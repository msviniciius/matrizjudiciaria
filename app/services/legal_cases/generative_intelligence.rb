module LegalCases
  class GenerativeIntelligence
    def initialize(legal_case:, user:, client: Ai::GeminiClient.new)
      @legal_case = legal_case
      @user = user
      @client = client
    end

    def call
      response = client.generate_process_analysis(payload: payload)

      legal_case.ai_analyses.create!(
        created_by: user,
        provider: "gemini",
        model: ENV.fetch("GEMINI_MODEL", "gemini-2.5-pro"),
        summary: response.fetch("summary"),
        risks: Array(response["risks"]),
        suggested_action: response.fetch("suggested_action"),
        confidence: response.fetch("confidence", "low"),
        notes: response["notes"],
        deterministic_snapshot: payload,
        raw_response: response
      )
    end

    private

    attr_reader :legal_case, :user, :client

    def payload
      @payload ||= {
        deterministic: LegalCases::IntelligenceSnapshot.new(legal_case: legal_case).as_json,
        process: process_payload,
        recent_timeline: recent_timeline,
        deadlines: deadlines_payload,
        tasks: tasks_payload,
        unread_publications: publications_payload
      }
    end

    def process_payload
      {
        internal_number: legal_case.internal_number,
        external_number: legal_case.external_number,
        client_name: legal_case.client&.full_name,
        phase: legal_case.phase,
        status: legal_case.status,
        priority: legal_case.priority,
        responsible_name: legal_case.responsible_name,
        next_action: legal_case.next_action,
        next_deadline_on: legal_case.next_deadline_on&.iso8601,
        last_movement: legal_case.last_movement,
        last_movement_at: legal_case.last_movement_at&.iso8601
      }
    end

    def recent_timeline
      TimelineBuilder.build(
        process_movements: legal_case.process_movements.recent.limit(5),
        case_events: legal_case.case_events.order(created_at: :desc).limit(5)
      ).first(8).map do |item|
        {
          title: item[:title],
          description: item[:description],
          date: item[:date]&.iso8601,
          source: item[:source]
        }
      end
    end

    def deadlines_payload
      legal_case.deadlines.order(Arel.sql("due_date ASC NULLS LAST")).limit(10).map do |deadline|
        deadline.slice(:title, :status, :priority, :deadline_type).merge(due_date: deadline.due_date&.iso8601)
      end
    end

    def tasks_payload
      legal_case.tasks.order(Arel.sql("due_date ASC NULLS LAST")).limit(10).map do |task|
        task.slice(:title, :description, :status, :priority, :responsible_name).merge(due_date: task.due_date&.iso8601)
      end
    end

    def publications_payload
      legal_case.legal_publications.unread.recent.limit(5).map do |publication|
        {
          title: publication.title,
          content: publication.content.to_s.truncate(1_000),
          source: publication.source,
          published_at: publication.published_at&.iso8601
        }
      end
    end
  end
end
