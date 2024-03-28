# frozen_string_literal: true

class AddExhibitorReciptTemplateToTemplateType < ActiveRecord::Migration[6.1]
  def up
    ['exhibitor_receipt_template', 'exhibitor_refund_intiated_template', 'exhibitor_refund_complete_template'].each do |template|
      TemplateType.find_or_create_by( name: template )
    end
  end

  def down
    begin
      ['exhibitor_receipt_template', 'exhibitor_refund_intiated_template', 'exhibitor_refund_complete_template'].each do |template|
        TemplateType.find_by(name: template).delete
      end
    rescue => exception
      raise ActiveRecord::IrreversibleMigration
    end
  end
end
