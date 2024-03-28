module StylesheetPaths

  def video_portal_stylesheet(event_id)
    file_path = Rails.root.join('public','event_data',event_id.to_s,'video_portal_stylesheet','tailored.css').to_path
    FileUtils.mkdir_p(File.dirname(file_path)) unless File.directory?(File.dirname(file_path))
    file_path
  end

  def default_video_portal_stylesheet
    Rails.root.join('public','defaults','video_portal_stylesheet','tailored.css').to_path
  end

end