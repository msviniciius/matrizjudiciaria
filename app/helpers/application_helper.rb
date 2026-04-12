module ApplicationHelper
  def enum_label(model_class, enum_name, value)
    return "" if value.blank?

    I18n.t(
      "activerecord.attributes.#{model_class.model_name.i18n_key}.#{enum_name.to_s.pluralize}.#{value}",
      default: value.to_s.humanize
    )
  end

  def enum_options_for(model_class, enum_name)
    model_class.public_send(enum_name.to_s.pluralize).keys.map do |value|
      [enum_label(model_class, enum_name, value), value]
    end
  end
end
