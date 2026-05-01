class LegalCasePdfExporter
  def initialize(legal_case:, timeline_items:, deadlines:, tasks:, process_exams:)
    @legal_case = legal_case
    @timeline_items = timeline_items
    @deadlines = deadlines
    @tasks = tasks
    @process_exams = process_exams
  end

  def to_pdf
    unless defined?(Prawn)
      raise LoadError, "Gem 'prawn' não está disponível"
    end

    Prawn::Document.new(page_size: "A4", margin: 32) do |pdf|
      pdf.text "Processo #{@legal_case.internal_number}", size: 18, style: :bold
      pdf.move_down 6
      pdf.text "Cliente: #{@legal_case.client&.full_name || '-'}"
      pdf.text "Emitido em: #{I18n.l(Time.current, format: :short)}"
      pdf.move_down 14

      section(pdf, "Resumo")
      key_values(pdf, [
        [ "Fase", enum_label(LegalCase, :phase, @legal_case.phase) ],
        [ "Status", enum_label(LegalCase, :status, @legal_case.status) ],
        [ "Prioridade", enum_label(LegalCase, :priority, @legal_case.priority) ],
        [ "Responsável", @legal_case.responsible_name.presence || "-" ],
        [ "Último andamento", @legal_case.last_movement.presence || "-" ],
        [ "Próxima providência", @legal_case.next_action.presence || "-" ],
        [ "Próximo prazo", @legal_case.next_deadline_on.present? ? I18n.l(@legal_case.next_deadline_on, format: :short) : "-" ]
      ])

      section(pdf, "Dados do Processo")
      key_values(pdf, [
        [ "Número interno", @legal_case.internal_number ],
        [ "Área", @legal_case.legal_area&.name || "-" ],
        [ "Tipo", @legal_case.process_type&.name || "-" ],
        [ "Subárea", @legal_case.subarea.presence || "-" ],
        [ "Assunto", @legal_case.main_subject.presence || "-" ],
        [ "Comarca", @legal_case.district&.name || "-" ],
        [ "Órgão/Vara/Tribunal", @legal_case.court&.name || "-" ],
        [ "Parte contrária", @legal_case.opposing_party.presence || "-" ],
        [ "Valor da causa", @legal_case.claim_value.presence || "-" ]
      ])
      pdf.text "Observações estratégicas: #{@legal_case.strategic_notes.presence || '-'}"
      pdf.move_down 8

      if @legal_case.tem_pericia?
        section(pdf, "Perícias do Processo")
        if @process_exams.any?
          @process_exams.each do |exam|
            pdf.text "- #{enum_label(ProcessExam, :exam_nature, exam.exam_nature)} | #{enum_label(ProcessExam, :exam_scope, exam.exam_scope)} | #{exam.scheduled_label} | #{enum_label(ProcessExam, :status, exam.status)}"
          end
        else
          pdf.text "Nenhuma perícia cadastrada."
        end
        pdf.text "Observação geral de perícia: #{@legal_case.observacao_geral_pericia.presence || '-'}"
        pdf.move_down 8
      end

      section(pdf, "Timeline")
      if @timeline_items.any?
        @timeline_items.first(40).each do |item|
          date = item[:date].present? ? I18n.l(item[:date], format: :short) : "-"
          pdf.text "- [#{date}] #{item[:title].presence || '-'} (#{item[:origin].to_s.humanize})"
          pdf.text "  #{item[:description]}" if item[:description].present?
        end
      else
        pdf.text "Nenhum andamento cadastrado."
      end
      pdf.move_down 8

      section(pdf, "Prazos")
      if @deadlines.any?
        @deadlines.each do |deadline|
          pdf.text "- #{deadline.title} | #{I18n.l(deadline.due_date)} | #{enum_label(Deadline, :status, deadline.status)} | #{enum_label(Deadline, :priority, deadline.priority)}"
        end
      else
        pdf.text "Sem prazos."
      end
      pdf.move_down 8

      section(pdf, "Tarefas")
      if @tasks.any?
        @tasks.each do |task|
          pdf.text "- #{task.title} | #{task.responsible_name.presence || '-'} | #{I18n.l(task.due_date)} | #{enum_label(Task, :status, task.status)} | #{enum_label(Task, :priority, task.priority)}"
        end
      else
        pdf.text "Sem tarefas."
      end
    end.render
  end

  private

  def section(pdf, title)
    pdf.move_down 8
    pdf.text title, size: 13, style: :bold
    pdf.stroke_horizontal_rule
    pdf.move_down 6
  end

  def key_values(pdf, rows)
    rows.each do |(key, value)|
      pdf.text "#{key}: #{value}"
    end
    pdf.move_down 6
  end

  def enum_label(model_class, enum_name, value)
    ApplicationController.helpers.enum_label(model_class, enum_name, value)
  end
end
