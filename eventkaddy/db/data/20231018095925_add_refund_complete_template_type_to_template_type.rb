# frozen_string_literal: true

class AddRefundCompleteTemplateTypeToTemplateType < ActiveRecord::Migration[6.1]
  def up
    TemplateType.find_or_create_by( name: "attendee_refund_complete_template" )
  end

  def down
    begin
      TemplateType.find_by(name: "attendee_refund_complete_template").delete
    rescue => exception
      raise ActiveRecord::IrreversibleMigration
    end
  end
end
