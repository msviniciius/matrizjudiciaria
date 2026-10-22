json.partial! "deadlines/deadline", deadline: @deadline
json.complete_path cumprir_deadline_path(@deadline)
json.ciencia_path ciencias_path if @deadline.expediente.present? && @deadline.expediente.ciencia.blank?
