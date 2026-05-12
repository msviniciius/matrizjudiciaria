class AppFormBuilder < ActionView::Helpers::FormBuilder
  (field_helpers - [ :label, :check_box, :radio_button, :hidden_field, :file_field, :fields_for ]).each do |helper_name|
    define_method(helper_name) do |method, *args, **options, &block|
      options = options.dup
      apply_required_option!(method, options)
      super(method, *args, **options, &block)
    end
  end

  def select(method, choices = nil, options = {}, html_options = {}, &block)
    html_options = html_options.dup
    apply_required_option!(method, html_options)
    super(method, choices, options, html_options, &block)
  end

  def collection_select(method, collection, value_method, text_method, options = {}, html_options = {})
    html_options = html_options.dup
    apply_required_option!(method, html_options)
    super(method, collection, value_method, text_method, options, html_options)
  end

  private

  def apply_required_option!(method, options)
    return if options.key?(:required)
    return unless object.present?
    return unless object.class.respond_to?(:validators_on)

    has_presence = object.class.validators_on(method).any? do |validator|
      validator.kind == :presence
    end

    return unless has_presence

    options[:required] = true
    options[:aria] = { **(options[:aria] || {}), required: true }
  end
end

ActionView::Base.default_form_builder = AppFormBuilder
