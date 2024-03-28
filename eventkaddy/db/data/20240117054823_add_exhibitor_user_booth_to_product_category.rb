# frozen_string_literal: true

class AddExhibitorUserBoothToProductCategory < ActiveRecord::Migration[6.1]
  def up
    ProductCategory.find_or_create_by(
      name: 'Exhibitor User Booth',
      iid: 'exhibitor_user_booth',
      event_id: 320,
      multi_select_product: false,
      single_product: false,
      free_booth_select_product: false
    )
  end

  def down
    begin
      ProductCategory.find_by(
        name: 'Exhibitor User Booth',
        iid: 'exhibitor_user_booth',
        event_id: 320
      ).delete
    rescue => exception
      raise ActiveRecord::IrreversibleMigration
    end
  end
end
