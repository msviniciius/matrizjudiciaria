class TimelineBuilder
  # Constroi uma timeline unificada mesclando ProcessMovement e CaseEvent.
  #
  # Uso:
  #   TimelineBuilder.build(process_movements:, case_events:)       # detalhado
  #   TimelineBuilder.build_compact(process_movements:, case_events:, limit: 10) # resumido
  #
  class << self
    # Formato detalhado — usado na pagina de detalhes do processo (show)
    def build(process_movements:, case_events:, limit: nil)
      items = build_process_movement_items(process_movements, detail: :full) +
              build_case_event_items(case_events, detail: :full)

      items = items.sort_by { |item| item[:date] || Time.at(0) }.reverse
      items = items.first(limit) if limit
      items
    end

    # Formato compacto — usado no feed do painel (dashboard)
    def build_compact(process_movements:, case_events:, limit: nil)
      items = build_process_movement_items(process_movements, detail: :compact) +
              build_case_event_items(case_events, detail: :compact)

      items = items.sort_by { |item| item[:date] || Time.at(0) }.reverse
      items = items.first(limit) if limit
      items
    end

    private

    def build_process_movement_items(movements, detail:)
      movements.map do |movement|
        if detail == :compact
          {
            title: movement.display_title,
            date: movement.event_date,
            process_id: movement.process_id,
            internal_number: movement.process.internal_number,
            movement_type: movement.movement_type&.name,
            origin: "Manual",
            highlight: false
          }
        else
          {
            source: :process_movement,
            process_movement_id: movement.id,
            title: movement.display_title,
            description: movement.complementary_description,
            date: movement.event_date,
            nature: movement.nature,
            highlight: movement.nature_fato_processual? || movement.nature_fato_administrativo?,
            movement_type: movement.movement_type&.name,
            exam: movement.exam,
            origin: movement.origin,
            administrative_situation: movement.administrative_situation
          }
        end
      end
    end

    def build_case_event_items(events, detail:)
      events.map do |event|
        from_cnj = event.pje_external_id.present?
        tribunal = event.source_tribunal || "CNJ"

        if detail == :compact
          {
            title: event.description,
            date: event.event_date || event.created_at,
            process_id: event.legal_case_id,
            internal_number: event.legal_case.internal_number,
            movement_type: event.movement_type&.name,
            origin: tribunal,
            highlight: true
          }
        else
          {
            source: from_cnj ? :cnj_import : :manual_event,
            case_event_id: event.id,
            title: event.description,
            description: from_cnj ? "Importado do #{tribunal}" : "Registro manual",
            date: event.event_date || event.created_at,
            nature: event.entry_kind,
            highlight: from_cnj,
            movement_type: event.movement_type&.name,
            exam: event.process_exam,
            origin: from_cnj ? tribunal : "Manual",
            administrative_situation: nil
          }
        end
      end
    end
  end
end
