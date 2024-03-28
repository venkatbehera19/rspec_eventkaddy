# frozen_string_literal: true

class AddIosAndAndroidToAppFormTypes < ActiveRecord::Migration[6.1]
  def up
    ["android","ios"].each{|type| AppFormType.create(name: type)}
  end

  def down
    begin
      AppFormType.delete_all
    rescue => e
      puts e.message
    end
  end
end
