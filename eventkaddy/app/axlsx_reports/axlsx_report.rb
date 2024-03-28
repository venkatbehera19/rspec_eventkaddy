class AxlsxReport

  attr_reader :package, :workbook, :job, :event_id

  # If event id is not blank, SimpleXlsxTable will check the  Report view settings in settings table and will apply them.
  def initialize package, job=nil, event_id=nil
    # @package                    = Axlsx::Package.new # can't use this or else we have to give up axlsx template... maybe that's not the worst, but for consistency
    @package                    = package
    @package.use_shared_strings = true
    @workbook                   = package.workbook
    @job                        = job
    @event_id                   = event_id
    # workbook.use_shared_strings = true

    # SimpleXlsxTable.black_cell workbook
    # SimpleXlsxTable.wrap_cell workbook

  end

  def add_sheet name, two_d_array, column_widths=false, column_types=false

    if job
      job.update!( status: "Processing Rows", total_rows: (job.total_rows || 0) + two_d_array.length - 1) # first row is headers
      job.write_to_file
    end

    SimpleXlsxTable.add_sheet( workbook, name, two_d_array, column_widths, column_types, event_id ) {
      job.plus_one_row if job
    }
  end

  # just a convenient alias
  def encode string
    SimpleXlsxTable.encode string
  end

end
