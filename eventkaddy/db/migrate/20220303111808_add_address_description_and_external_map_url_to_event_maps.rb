class AddAddressDescriptionAndExternalMapUrlToEventMaps < ActiveRecord::Migration[6.1]
  def change
    add_column :event_maps, :address_description, :text
    add_column :event_maps, :external_map_url, :text
  end
end
