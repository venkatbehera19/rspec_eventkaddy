module JpickerHelper

  def prepare_styles_for_jpicker(styles_by_category)
    styles_by_category.each {|category, styles|
      styles.each {|style|
        style.value[0]='' if style.property.include?('color') && style.value.include?('#')}}
  end

  def clean_styles_from_jpicker(form_results)
    form_results.each {|input_name, input_value|
      if input_name.split('_')[1].include?('color') && !input_value.include?('#')
        if input_value == 'transparent'
          # leave as it is
        elsif input_value == ''
          form_results[input_name] = 'transparent'
        else
          form_results[input_name] = '#'.concat(input_value)
        end
      end
      }
  end

end