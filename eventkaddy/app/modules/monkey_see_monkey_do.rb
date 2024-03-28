module MonkeySeeMonkeyDo

  # TODO: a method where I can copy an entire event would be really useful for
  # testing a production event's data in a non production event id, modifying the few
  # values that are of interest to me.... and those values could even be modified by
  # another method that would just update the notification key values to test keys,
  # and maybe a few other things like event_server. It could even just create an entirely
  # new event with the production event name prepended by TEST_
  #
  # You can see here though that my existing code relies on a well defined schema
  # I would need one for event, sessions, speakers, attendees, exhibitors, home buttons...
  # might be a someday never kind of thing
  #
  # Maybe it's not that bad, I did quite a nested and complicated one for surveys, none of our other
  # data is really that complex. I might try... anyway it would look something like
  #
  # Event
  #   Session
  #     SessionTags
  #   Speaker
  #     SpeakerTags
  #   Exhibitor
  #     ExhibitorTags
  #   Settings
  #   HomeButtons
  #   Attendees
  #     AttendeeTags
  #
  # I'm not sure if the existing system would be able to handle the
  # many_to_many relationship. For Surveys everything was a belongs_to
  # relationship. I guess for the time being I don't really need the tags

  def self.copy_model_to_event schema, original_id_columns=[]
    r = {}
    if schema[:columns] == :all
      (original_id_columns << id_column(schema[:model])).uniq!
      r[:model] = schema[:model].class.new(
        schema[:model].
          attributes. # returns keys that are strings, annoyingly... or maybe reject does that
          reject{|k,v| original_id_columns.include?(k.to_sym) || [:id, :created_at, :updated_at].include?(k.to_sym) }.
          merge( schema[:ids] )
      )
      if schema[:children]
        r[:children] = schema[:children].map {|c|
          copy_model_to_event c.merge( {ids: schema[:ids] } ), original_id_columns
        }
      else
        r[:children] = []
      end
      r
    else
      raise "Specific column copying not implemented."
    end
  end

  # take output from copy_model_to_event, and save to database
  def self.save_result_copy copy, ids={}
    r = {}
    # set parent ids if present for model
    ids.each do |k,v|
      if copy[:model].respond_to? k
        copy[:model].send k.to_s + '=', v
      end
    end
    copy[:model].save # returns true
    r[:model] = copy[:model]
    r[:children] = copy[:children].map {|c|
      ids = ids.merge({ id_column( r[:model] ) => r[:model].id })
      save_result_copy c, ids
    }
    r
  end

  private

  def self.id_column model_instance
    (model_instance.class.name.snakecase + "_id").to_sym
  end

end
