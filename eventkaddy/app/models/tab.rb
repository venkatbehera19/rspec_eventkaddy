class Tab < ApplicationRecord

  belongs_to :tab_type

  def self.createDefaults(event_id, portal)
    TabType.where(portal: portal).each_with_index do |default, index|
      if Tab.where( event_id:event_id, tab_type_id: default.id ).length===0
        Tab.create(
          event_id:    event_id,
          tab_type_id: default.id,
          name:        default.default_name,
          enabled:     true,
          order:       index
        )
      end
    end
  end

  def self.tab_by_event_and_default_name event_id, default_name, portal
    select('tabs.*, tab_types.default_name')
      .joins('JOIN tab_types ON tabs.tab_type_id=tab_types.id')
      .where('event_id=? AND default_name=? AND portal=?', event_id, default_name, portal)
      .first
  end
end
