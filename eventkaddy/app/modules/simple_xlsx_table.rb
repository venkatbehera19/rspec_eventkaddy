module SimpleXlsxTable

  def self.add_sheet wb, name, two_d_array, column_widths=false, column_types=false, event_id=nil
    header_style = black_cell wb
    wb.add_worksheet(name: name) do |sheet|
      sheet.add_row two_d_array.first, :style => two_d_array.first.map { |h| header_style  }
      two_d_array[1..-1].each do |row|
        sheet.add_row row, types: column_types
        sheet.column_widths *( column_widths || row.map{ |n| 30 })
        yield if block_given?
      end
      
      if !event_id.blank?
        setting_type_id = SettingType.find_by_name "cms_settings"
        setting         = Setting.where(event_id: event_id, setting_type_id: setting_type_id).first
        setting         = setting.json

        col_no = 0

        two_d_array[0].each do |col|

          if col == "Email" && setting['hide_reports_view_attendee_email']
            sheet.column_info[col_no].hidden = true
          elsif  col == "Business Phone"  && setting['hide_reports_view_attendee_business_phone']
            sheet.column_info[col_no].hidden = true
          elsif col == "Mobile Phone" &&  setting['hide_reports_view_attendee_mobile_phone']
            sheet.column_info[col_no].hidden = true
          end
          
          col_no += 1
        end
      end
    end
  end

  def self.black_cell wb
    wb.styles.add_style :bg_color => "00",
                        :fg_color => "FF",
                        :sz => 14,
                        :alignment => { :horizontal=> :center }
  end

  def self.wrap_cell wb
    wb.styles.add_style alignment: {wrap_text: true}
  end

  # help for when client data is inconsistently encoded
  def self.encode string
    return '' unless string
    string.encode( Encoding.find('ASCII'), {
      :invalid           => :replace,  # Replace invalid byte sequences
      :undef             => :replace,  # Replace anything not defined in ASCII
      :replace           => '',        # Use a blank for those replacements
      :universal_newline => true       # Always break lines with \n
    } )
  end
end
