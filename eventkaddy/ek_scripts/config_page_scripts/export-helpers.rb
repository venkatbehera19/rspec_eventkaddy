
def config_page_export_data job, filename, sheetname, linkname, event_id, data

  # -1 because first row is headers
  job.update!(row: 0, total_rows: data.length - 1, status:'Adding Rows to Excel Sheet')
  job.write_to_file

  path    = Rails.root.join('public', 'event_data', event_id.to_s, 'config_page_exports', filename)
  dirname = File.dirname( path )
  FileUtils.mkdir_p(dirname) unless File.directory?(dirname)

  p = Axlsx::Package.new
  p.use_shared_strings = true
  wb = p.workbook

  SimpleXlsxTable.add_sheet( wb, sheetname, data, ( [] || false ), ( [] || false ) ) {
    job.row = job.row + 1
    job.write_to_file if job.row % job.rows_per_write == 0
  }

  p.serialize( path )

  job.add_info "<a class='btn btn-success btn-sm' href='#{path.to_s.split('public')[1]}'>#{linkname}</a>"

end
