# Not sure of a better name for this, but
# just something to mix into models that add
# important functionality. At the point of
# creation, to add a bulk delete method that
# is fast but dynamically reads assocations

module ModelMethods

  def dependent_destroy_associations
    ModelInfo.get_dependent_destroy_associations self
  end

  def count_all_associated_records_for_event

  end

  def delete_all_and_associated_records_for_event event_id
    dependent_destroy_associations.each do |a|
      case a[:macro]
      when :has_many
        # delete IN session_id == session_ids in assoc
      when :has_one
        # delete IN session_id == session_ids in assoc
      when :belongs_to
        # delete IN ids == foreign_key_column_ids in parent
        # get ids from parent forign key column
      else
        raise "Association type #{assoc} was not defined by delete_all_and_associated_records."
      end
    end
  end

end

# Session.dependent_destroy_associations # [{:association=>:sessions_speakers, :macro=>:has_many, :children=>[]}, {:association=>:sessions_subtracks, :macro=>:has_many, :children=>[]}, {:association=>:sessions_sponsors, :macro=>:has_many, :children=>[]}, {:association=>:sessions_attendees, :macro=>:has_many, :children=>[]}, {:association=>:sessions_trackowners, :macro=>:has_many, :children=>[]}, {:association=>:survey_sessions, :macro=>:has_many, :children=>[]}, {:association=>:tags_sessions, :macro=>:has_many, :children=>[]}, {:association=>:session_files, :macro=>:has_many, :children=>[{:association=>:session_file_versions, :macro=>:has_many, :children=>[{:association=>:event_file, :macro=>:belongs_to, :children=>[{:association=>:exhibitor_file, :macro=>:has_one, :children=>[]}]}]}]}, {:association=>:session_av_requirements, :macro=>:has_many, :children=>[]}, {:association=>:attendee_scans, :macro=>:has_many, :children=>[]}]
