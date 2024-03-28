# frozen_string_literal: true

class SessionKeywordToTagType < ActiveRecord::Migration[6.1]
  def up
    TagType.find_or_create_by(name: "session-keywords")
  end

  def down
    begin
      TagType.find_by(name: 'session-keywords').delete
    rescue => exception
      raise ActiveRecord::IrreversibleMigration
    end
  end
end
