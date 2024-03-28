module SpeakerPortalsHelper
  def can_be_fields? check_value
    begin
      JSON.parse(check_value.to_json)
      true
    rescue StandardError => e
      false
    end
  end
end
