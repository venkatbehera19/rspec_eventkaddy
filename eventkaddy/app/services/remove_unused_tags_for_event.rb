class RemoveUnusedTagsForEvent

  def initialize(event_id)
    @event_id      = event_id
    @ids_to_delete = []
  end

  def call
    remove_tags
  end

  private

  attr_reader :event_id, :ids_to_delete

  def return_abandoned_leaf_tags
    Tag.unused_leaf_tags_for_event event_id
    # Tag.select('id, parent_id')
    #    .where('id NOT IN (SELECT DISTINCT(tag_id) FROM tags_attendees) AND
    #            id NOT IN (SELECT DISTINCT(tag_id) FROM tags_sessions) AND
    #            id NOT IN (SELECT DISTINCT(tag_id) FROM tags_exhibitors) AND
    #            leaf=1 AND
    #            event_id=?', event_id)
  end

  def parent_has_no_unabandoned_children?(parent_id)
    sibling_ids          = Tag.where(parent_id:parent_id).pluck(:id)
    unabandoned_siblings = sibling_ids - ids_to_delete
    unabandoned_siblings.length == 0
  end

  def add_parents_with_no_unabandoned_children_to_ids_to_delete(abandoned_leafs_parents)
    abandoned_leafs_parents.each do |parent_id|
      next if parent_id == 0 ## skip if leaf tag was also the top tag.
      # prevent one layer of data corruption by checking if child does not have parent.
      # This means user won't get an ugly message, but they won't successfully delete
      # parents who have no children
      while parent_id != 0 && Tag.parent_exists?(parent_id)
        raise "Expected number for parent_id, recieved: #{parent_id}" unless parent_id.is_a? Numeric
        ids_to_delete.concat([parent_id]) if parent_has_no_unabandoned_children?(parent_id)
        next_tag  = Tag.select('id, parent_id').find(parent_id)
        parent_id = next_tag.parent_id
      end
      ids_to_delete.concat([next_tag.id]) if next_tag && parent_has_no_unabandoned_children?(next_tag.id)
    end
  end

  def remove_tags
    abandoned_leaf_tags = return_abandoned_leaf_tags
    ids_to_delete.concat(abandoned_leaf_tags.pluck(:id))
    add_parents_with_no_unabandoned_children_to_ids_to_delete(abandoned_leaf_tags.pluck(:parent_id))
    # puts ids_to_delete.uniq.inspect
    Tag.where(id:ids_to_delete.uniq).delete_all
  end
end
