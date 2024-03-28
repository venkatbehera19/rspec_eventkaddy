# frozen_string_literal: true

class SpeakerNumericPasswordTemplateToTemplateType < ActiveRecord::Migration[6.1]
  def up
    TemplateType.find_or_create_by(name: 'speaker_numeric_password_template')
  end

  def down
    begin
      TemplateType.find_by(name: 'speaker_numeric_password_template').delete
    rescue => exception
      raise ActiveRecord::IrreversibleMigration
    end
  end
end
