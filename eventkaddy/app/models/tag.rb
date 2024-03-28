MissingParent = Struct.new(:id, :name, :parent_id)

class Tag < ApplicationRecord
  
  extend ActsAsHierarchy
  has_many :tags_session,   :dependent => :destroy
  has_many :tags_exhibitor, :dependent => :destroy
  has_many :tags_attendee,  :dependent => :destroy
  has_many :sessions,       :through   => :tags_session
  has_many :exhibitors,     :through   => :tags_exhibitor
  has_many :attendees,      :through   => :tags_attendee

  belongs_to :tag_type
  acts_as_hierarchy

  def self.parent_exists?(parent_id)
    select(:id).where(id:parent_id).length > 0
  end

  def remove_self_and_parents_without_children

    def parent_has_no_unabandoned_children?(parent_id)
      sibling_ids          = Tag.where(parent_id:parent_id).pluck(:id)
      unabandoned_siblings = sibling_ids - @ids_to_delete
      unabandoned_siblings.length == 0
    end

    @ids_to_delete = [ id ]
    tag_parent_id = parent_id

    # parent exists protects against one level of missing parents. If the missing parent 
    # also had a missing parent, we cannot find it and it must be deleted by looking for
    # non-leaf tags with no children. That's not implemented because it represents a corruption
    # of data, caused by deleting tags manually. (As does the child with no parent)
    while tag_parent_id != 0 && Tag.parent_exists?(tag_parent_id)
      raise "Expected number for parent_id, recieved: #{tag_parent_id}" unless tag_parent_id.is_a? Numeric
      @ids_to_delete.concat([tag_parent_id]) if parent_has_no_unabandoned_children?(tag_parent_id)
      next_tag      = Tag.select('id, parent_id').find(tag_parent_id)
      tag_parent_id = next_tag.parent_id
    end
    @ids_to_delete.concat([next_tag.id]) if next_tag && parent_has_no_unabandoned_children?(next_tag.id)
    Tag.where(id:@ids_to_delete.uniq).delete_all
  end

  def get_all_parents
    tags = []
    if parent_id == 0 
      return []
    else
      query = Tag.where id: parent_id
      if query.length > 0
        parent = query.first
      else
        parent = MissingParent.new(nil, "Error: Parent Could Not Be Found", 0)
      end
    end
    tags << parent
    while parent.parent_id != 0 && Tag.parent_exists?(parent.parent_id)
      parent = Tag.find parent.parent_id
      tags << parent
    end
    tags.reverse
  end

  def parents_as_string
    get_all_parents.map(&:name).join(' -> ')
  end

  def self.unused_leaf_tags_for_event event_id
    where('NOT EXISTS (SELECT DISTINCT(tag_id) FROM tags_attendees WHERE tags.id = tag_id) AND
           NOT EXISTS (SELECT DISTINCT(tag_id) FROM tags_sessions WHERE tags.id = tag_id) AND
           NOT EXISTS (SELECT DISTINCT(tag_id) FROM tags_exhibitors WHERE tags.id = tag_id) AND
           leaf=1 AND event_id=?', event_id)
  end

  # maybe not the best name for it.
  def self.add_all_session_order_tag_data event_id
    session_tag_id = TagType.where(name:'session').first.id
    where(event_id:event_id, leaf:1, tag_type_id:session_tag_id).map do |tag|
      tag.update! order: get_session_order_data( tag.id, tag.name )
      tag
    end
  end

  def self.add_all_session_meta_tag_data event_id
    session_tag_id = TagType.where(name:'session').first.id
    where(event_id:event_id, leaf:1, tag_type_id:session_tag_id).each do |tag|
      tag.update! meta_data: get_session_meta_data( tag.id )
    end
  end

  def add_session_meta_tag_data
    update! meta_data: Tag.get_session_meta_data( id )
  end

  def self.get_session_order_data tag_id, tag_name
    tag_sessions = TagsSession
      .select('date, start_at, end_at, title')
      .where(tag_id: tag_id)
      .joins('LEFT JOIN sessions on tags_sessions.session_id=sessions.id
              LEFT JOIN location_mappings ON sessions.location_mapping_id=location_mappings.id')
      .order('sessions.date ASC, sessions.start_at ASC')
      # .group(:session_id)

    return nil if tag_sessions.length == 0 # tag is abandoned

    t_date     = tag_sessions.first.date
    # t_location = tag_sessions.first.lc_name
    # t_title = tag_sessions.first.title # can I even do this? I can't really tell.
    t_start    = tag_sessions.first.start_at.strftime('%T')
    t_end      = tag_sessions.last.end_at.strftime('%T')
    "#{t_date}, #{t_start} - #{t_end} #{tag_name}"
  end

  def self.get_session_meta_data tag_id
    tag_sessions = TagsSession
      .select('date, start_at, end_at, location_mappings.name AS lc_name')
      .where(tag_id: tag_id)
      .joins('LEFT JOIN sessions on tags_sessions.session_id=sessions.id
              LEFT JOIN location_mappings ON sessions.location_mapping_id=location_mappings.id')
      .order('sessions.date ASC, sessions.start_at ASC')
      # .group(:session_id)

    return nil if tag_sessions.length == 0 # tag is abandoned

    t_date     = tag_sessions.first.date.strftime('%A, %B %-d')
    t_location = tag_sessions.first.lc_name
    t_start    = tag_sessions.first.start_at.strftime('%l:%M %p')
    t_end      = tag_sessions.last.end_at.strftime('%l:%M %p')
    "<div class=\"tag-meta-data\">#{t_date}, #{t_start} - #{t_end}<br/>#{t_location}</div>"
  end

  # sessions, exhibitors and attendees tag form page; probably will be discarded when updating how
  # this form works
	def self.assemble_tag_array params
    # params contains the tags in a hash with keys like tag_0_0 for tag set index, depth in that set
    tag_groups = []
    params.select {|k, v| /^tag_\d+_\d+$/.match( k.to_s ) && !v.blank? } # get only tag related params
          .each {|k, v| 
            indexes = /^tag_(\d+)_(\d+)$/.match k
            set_index, group_depth  = indexes[1].to_i, indexes[2].to_i
            tag_groups[set_index].is_a?( Array ) || tag_groups[set_index] = []
            tag_groups[set_index][group_depth] = v
          }
    tag_groups
	end

end
