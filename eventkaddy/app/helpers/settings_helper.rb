module SettingsHelper
  def btn_classes_enum
    {
      primary: "btn-primary",
      secondary: "btn-secondary",
      success: "btn-success",
      danger: "btn-danger",
      warning: "btn-warning",
      info: "btn-info",
      light: "btn-light",
      dark: "btn-dark",
      link: "btn-link",
      primary_outlined: "btn-outline-primary",
      secondary_outlined: "btn-outline-secondary",
      success_outlined: "btn-outline-success",
      danger_outlined: "btn-outline-danger",
      warning_outlined: "btn-outline-warning",
      info_outlined: "btn-outline-info",
      light_outlined: "btn-outline-light",
      dark_outlined: "btn-outline-dark",
    }
  end
  
  def check_existing_tag_or_keyword event, tag_type, tag_name
        
    if event.tag_sets_hash.blank?
      return false
    end
    event.tag_sets_hash[tag_type.id.to_s]&.flatten&.include?(tag_name)
  end
end