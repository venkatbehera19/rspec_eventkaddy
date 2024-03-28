class AddFieldstoVideoViews < ActiveRecord::Migration[4.2]
  def change
    add_column :video_views, :event_year, :integer
    add_column :video_views, :session_code, :string
    add_column :video_views, :account_code, :string
    add_column :video_views, :start_time, :time
    add_column :video_views, :date, :date
    add_column :video_views, :view_ranges, :text
    add_column :video_views, :view_total, :integer
    add_column :video_views, :duration, :integer
    add_column :video_views, :paused_at, :integer
    add_column :video_views, :time_watched, :integer
    add_column :video_views, :video_length, :integer
    add_column :video_views, :view_details, :text
    add_column :video_views, :custom_fields_1, :text
    add_column :video_views, :custom_fields_2, :string
    add_column :video_views, :custom_fields_3, :string
    add_index :video_views, :event_id
    add_index :video_views, :attendee_id
    add_index :video_views, :session_id
    add_index :video_views, :exhibitor_id
  end
end
