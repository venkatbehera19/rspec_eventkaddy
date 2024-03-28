# things that need to happen:
# 1. received filters must be checked if they are standard
# 2. if they are not standard, they must be checked if they are
# automated (1 and 2 can happen in reverse order)
# 3. filters neither standard nor automated return
# errors array
# 4. filters not standard but appropriate automated filter need to update
# attendee.pn_filters by removing no longer appropriate automated filters,
# and adding the new automated filter.
# 5. filters standard but not automated return no errors.
# 6. filters not standard, but an inappropriate automated filter need to
# be removed silently.

class PnFilterProcessor

  attr_accessor :standard_filters, :type_to_pn_hash

  def initialize event_id
    event = Event.find event_id
    # regular filters
    @standard_filters = 
      event.pn_filters.blank? ? [] : JSON.parse( event.pn_filters )
    # automated filters
    @type_to_pn_hash =
      event.type_to_pn_hash.blank? ? {} : event.type_to_pn_hash
  end

  # The idea of this method is to always return a valid list
  # of filters for the model type that could be updated regardless,
  # with additional info about errors to give feedback to the user if
  # there is one.
  #
  # model_type refers to type in type_to_pn_hash, ie: custom_filter_1 for
  # avma and some other events
  # requested pn filters should be a comma delimited string or an array
  # process filters should always return the updated filters as an array
  def process_filters model_type, requested_pn_filters

    result = { success: true, errors: [], updated_filters: [] }

    if requested_pn_filters.is_a? String
      requested_pn_filters = requested_pn_filters.split(',').map(&:strip)
    elsif !requested_pn_filters.is_a?(Array) && model_type.blank?
      # exit early as we received nil or something we can't work with, presumably
      # because no filters were wanted
      return result
    end

    # in a case where there is a type which is not a automated type,
    # but requested pn filters argument was nil, we need this line
    requested_pn_filters ||= []

    # this seems a little awkward, but we're trying to add it to the types,
    # and then in the next reject block, remove autotypes that no longer
    # match the model type
    # We have to use concat instead of << (which would have been safer) because
    # multiple filters can be in a type
    if type_to_pn_hash.has_key? model_type
      requested_pn_filters.concat(type_to_pn_hash[ model_type ])
    end

    result[:updated_filters] = requested_pn_filters.reject {|f|
      unless valid_standard_filter?(f) || valid_automated_filter?(model_type, f)
        result[:success] = false
        result[:errors] << "Invalid notification filter \"#{f}\". Possible standard filters: #{standard_filters.join(', ')}; Permissable automated filters: #{type_to_pn_hash.inspect}."
        true # as in, delete the item
      end
    }.uniq
    result
  end

  def valid_standard_filter? filter
    standard_filters.include? filter
  end

  def valid_automated_filter? model_type, filter
    type_to_pn_hash[model_type] && type_to_pn_hash[ model_type ].include?(filter)
  end

end

# Only manual
# PnFilterProcessor.new( 20 ).process_filters '', "groupA" 
# {:success=>true, :errors=>[], :updated_filters=>["groupA"]}

# Manual and Autofilter
# PnFilterProcessor.new( 20 ).process_filters 'Veterinary Students', "groupA"  
# {:success=>true, :errors=>[], :updated_filters=>["groupA", "bothVetStudentsAndRecentGraduates", "veterinaryStudents"]}

# Only Autofilter
# PnFilterProcessor.new( 20 ).process_filters 'Veterinary Students', ""  
# {:success=>true, :errors=>[], :updated_filters=>["bothVetStudentsAndRecentGraduates", "veterinaryStudents"]}

# Neither
# PnFilterProcessor.new( 20 ).process_filters '', "" 
# {:success=>true, :errors=>[], :updated_filters=>[]}

# Auto with outdated auto ( representing type change )
# ( Adds to errors array, but autocorrects for you if you're not interested )
# PnFilterProcessor.new( 20 ).process_filters 'Recent Graduates', "veterinaryStudents"   
# {:success=>false, :errors=>["Invalid notification filter \"veterinaryStudents\". Possible standard filters: groupA, groupB; Permissable automated filters: {\"Veterinary Students\"=>[\"bothVetStudentsAndRecentGraduates\", \"veterinaryStudents\"], \"Recent Graduates\"=>[\"recentGraduates\", \"bothVetStudentsAndRecentGraduates\"], \"Veterinary Technician Students\"=>[\"vetTechnicians\"], \"Veterinary Technicians\"=>[\"vetTechnicians\"], \"Veterinary Technician Daily Registration\"=>[\"vetTechnicians\"]}."], :updated_filters=>["recentGraduates", "bothVetStudentsAndRecentGraduates"]}

# with nil value
# PnFilterProcessor.new( 20 ).process_filters '', nil  
# {:success=>true, :errors=>[], :updated_filters=>""}
# PnFilterProcessor.new( 20 ).process_filters nil, nil   
# {:success=>true, :errors=>[], :updated_filters=>""}
# PnFilterProcessor.new( 20 ).process_filters 'Veterinary Students', nil   
# {:success=>true, :errors=>[], :updated_filters=>["bothVetStudentsAndRecentGraduates", "veterinaryStudents"]}
# PnFilterProcessor.new( 20 ).process_filters nil, 'groupA' 
# {:success=>true, :errors=>[], :updated_filters=>["groupA"]}

# using array instead of comma string
# PnFilterProcessor.new( 20 ).process_filters nil, ['groupA']  
# {:success=>true, :errors=>[], :updated_filters=>["groupA"]}
# PnFilterProcessor.new( 20 ).process_filters '', ['groupA']   
# {:success=>true, :errors=>[], :updated_filters=>["groupA"]}
# PnFilterProcessor.new( 20 ).process_filters 'Veterinary Students', ['groupA']    
# {:success=>true, :errors=>[], :updated_filters=>["groupA", "bothVetStudentsAndRecentGraduates", "veterinaryStudents"]}

# Using invalid type
# PnFilterProcessor.new( 20 ).process_filters 'Big Mountain', ['groupA']  
# {:success=>true, :errors=>[], :updated_filters=>["groupA"]}
# PnFilterProcessor.new( 20 ).process_filters 'Big Mountain', ''  
# {:success=>true, :errors=>[], :updated_filters=>[]}
# PnFilterProcessor.new( 20 ).process_filters '', 'Little Rock' 
# {:success=>false, :errors=>["Invalid notification filter \"Little Rock\". Possible standard filters: groupA, groupB; Permissable automated filters: {\"Veterinary Students\"=>[\"bothVetStudentsAndRecentGraduates\", \"veterinaryStudents\"], \"Recent Graduates\"=>[\"recentGraduates\", \"bothVetStudentsAndRecentGraduates\"], \"Veterinary Technician Students\"=>[\"vetTechnicians\"], \"Veterinary Technicians\"=>[\"vetTechnicians\"], \"Veterinary Technician Daily Registration\"=>[\"vetTechnicians\"]}."], :updated_filters=>[]}
  
# PnFilterProcessor.new( 118 ).process_filters 'Vendors', nil
 # PnFilterProcessor.new( 118 ).process_filters 'Vendors', nil
 #   [1m[36mEvent Load (0.3ms)[0m  [1mSELECT `events`.* FROM `events` WHERE `events`.`id` = 118 LIMIT 1[0m
 #   [1m[35mEvent Load (0.3ms)[0m  SELECT `events`.* FROM `events` WHERE `events`.`id` = 118 LIMIT 1
 # {:success=>true, :errors=>[], :updated_filters=>[]}
 # 
# PnFilterProcessor.new(118).process_filters nil, nil
