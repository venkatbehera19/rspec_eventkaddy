class GenerateTagsForModel

  def initialize(model, tagsets, tag_type)
    @tagsets     = tagsets.uniq
    @model       = model
    if tag_type.is_a? String
      @tag_type    = tag_type.downcase
      @tag_type_id = TagType.where(name:tag_type).pluck(:id)[0]
      raise "tag type for '#{tag_type}' returned nil." if @tag_type_id.nil?
    elsif tag_type.is_a? Integer
      @tag_type_id = tag_type
      raise unless TagType.find(@tag_type_id)
    else
      raise "Expected tag_type to be a String containing tag_type, or an Integer containing tag_type_id"
    end

    @event_id = @model.event_id

    unless @model.class.name == 'Session' || @model.class.name == 'Attendee' || @model.class.name == 'Exhibitor'
      raise ArgumentError.new('Model received was not a Session, Exhibitor or Attendee instance.')
    end
    raise ArgumentError.new("#{@model.class.name}'s id cannot be nil.") if @model.id.nil?
    raise ArgumentError.new("#{@model.class.name}'s event id cannot be nil.") if @model.event_id.nil?
  end

  def call
    process_tags
  end

  private

  def tag_match tag_name, index, leaf, parent_id, bloodline
    tags = Tag.where(event_id:@event_id, tag_type_id:@tag_type_id, name:tag_name, level:index, leaf:leaf, parent_id:parent_id)
    # ensure correct bloodline for tags that already exist; we could optimize
    # this by only updating it if it doesn't already have a value, but that's
    # slightly less safe
    tags[0].update!(bloodline: bloodline) if tags.length > 0 && tags[0].bloodline != bloodline
    tags
  end

  def tagset_exists? tagset

    # search from top level to bottom level tag to find a matching
    # tag set in the database. Duplicate top-level tags could confuse
    # this method, but duplicate top-level tags represent an error in
    # data in the first place. An exception could be raised to make this
    # method safer when two tags have the same name and parent id, but this
    # class should never be able to create that bad data itself.

    exists    = false
    parent_id = 0

    tagset.each_with_index do |tag_name, index|

      leaf = index == tagset.length - 1
      bloodline = bloodline_for_tag(tag_name, tagset)
      tags = tag_match tag_name, index, leaf, parent_id, bloodline

      if tags.length > 0
        exists    = true
        parent_id = tags[0].id
      else
        exists = false; break;
      end
    end
    exists
  end

  # how would I do this? reject() ? It's actually somewhat tricky.
  # Well, the imperitive way to do it is to make a new result array, and
  # add to it up to the point we have the tag_name
  def bloodline_for_tag tag_name, tagset
    result = []
    tagset.each do |tag|
      result << tag
      break if tag == tag_name
    end
    result.join('||')
  end

  def create_tagset_and_return_leaf_id tagset

    parent_id = 0

    tagset.each_with_index do |tag_name, index|

      leaf = index == tagset.length - 1
      bloodline = bloodline_for_tag(tag_name, tagset)
      tags = tag_match tag_name, index, leaf, parent_id, bloodline

      if tags.length == 0
        t = Tag.create!(event_id:@event_id, tag_type_id:@tag_type_id, name:tag_name, level:index, leaf:leaf, parent_id:parent_id, bloodline:bloodline)
        #Update ancestor_ids field for each newly created tag
        t.parent && t.update!(ancestor_ids: t.parent.ancestor_ids.to_s +
          t.ancestor_id_separator + t.parent_id.to_s + t.ancestor_id_separator)
        parent_id = t.id
      else
        parent_id = tags[0].id
      end
    end
    parent_id
  end

  def associate_tag leaf_id
    "Tags#{@model.class.name}".constantize.where(:tag_id => leaf_id, "#{@model.class.name.downcase}_id".to_sym => @model.id).first_or_create
  end

  def return_leaf_id tagset

    parent_id = 0

    tagset.each_with_index do |tag_name, index|
      leaf      = index == tagset.length - 1
      bloodline = bloodline_for_tag(tag_name, tagset)
      parent_id = tag_match(tag_name, index, leaf, parent_id, bloodline)[0].id
    end
    parent_id
  end

  def remove_current_assocations
    tag_ids = Tag.where(event_id: @event_id, tag_type_id: @tag_type_id).pluck(:id)
    "Tags#{@model.class.name}".constantize
      .where( "#{@model.class.name.downcase}_id".to_sym => @model.id )
      .where(tag_id: tag_ids)
      .delete_all
  end

  def process_tags
    remove_current_assocations
    @tagsets.each do |tagset|
      leaf_id = tagset_exists?(tagset) ? return_leaf_id(tagset) : create_tagset_and_return_leaf_id(tagset)
      associate_tag(leaf_id)
    end
  end

end
