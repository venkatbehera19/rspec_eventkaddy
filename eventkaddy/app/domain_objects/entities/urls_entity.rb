class UrlsEntity

  attr_reader :array

  @@root_domain = 'https://cms.eventkaddy.net'

  def initialize args = {} 
    @array = !args[:json].blank? ? JSON.parse(args[:json]) : !args[:array].blank? ? args[:array] : []
  end

  def self.root_domain
    @@root_domain
  end

  def remove_by ary 
    ary.each {|o|
      k = o.keys.first
      array.reject! {|item| item[k.to_s]==o[k]}}
  end

  def add ary 
    array.concat(ary).uniq!
  end

  def json
    array.to_json
  end

  # this was just used for events that didn't use window.url_root to determine
  # location of file
  def force_urls_to_use_full_path
    array.each {|ary| ary['url'] = @@root_domain + ary['url'] unless ary['url'][0..25] == @@root_domain}
  end

  def self.extension mime_type 
    file_types[mime_type] || '.doc'
  end

  def self.file_types
    {"application/msword"                                                         => ".doc",
      "application/vnd.openxmlformats-officedocument.wordprocessingml.document"   => ".docx",
      "application/vnd.oasis.opendocument.spreadsheet"                            => ".ods",
      "application/pdf"                                                           => ".pdf",
      "text/plain"                                                                => ".txt",
      "application/rtf"                                                           => ".rtf",
      "application/vnd.ms-powerpoint"                                             => ".ppt",
      "application/vnd.openxmlformats-officedocument.presentationml.presentation" => "pptx",
      "application/vnd.ms-excel"                                                  => ".xls",
      "application/xlsx"                                                          => ".xlsx",
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"         => ".xlsx",
      "video/quicktime"                                                           => ".mov",
      "video/mp4"                                                                 => ".mp4",
      "audio/mpeg"                                                                => ".mp3",
      "application/octet-stream"                                                  => ".pez"}
  end
end

