class SessionFile < ApplicationRecord

  attr_accessor :event_name

  belongs_to :session
  belongs_to :event
  belongs_to :session_file_type
  has_many :session_file_versions, :dependent => :destroy

  # , sfu = SessionFileUrlsEntity
  def updateJsonEntry(params)
    # sfvs              = session_file_versions.where(unpublished: false).order('created_at DESC')
    # event_file        = sfvs.first.event_file if sfvs.length > 0
    # session_file_urls = sfu.new(json:session.session_file_urls)

    # if event_file
    #   ## as sf_id is new, need to support deleting by url for awhile. - May 9 2016
    #   session_file_urls.remove_by [{url:event_file.path}]
    #   session_file_urls.add [{"title" => title, "url" => event_file.path,
    #     "type" => sfu.extension(event_file.mime_type), "sf_id" => id}]
    # end
    # ## bugfix for bad bns configuration. Safe to remove after BNS 2016 is over.
    # session_file_urls.force_urls_to_use_full_path if event_id == 20 || event_id == 77 || event_id == 104
    # session.update! session_file_urls:session_file_urls.json
    session.update_session_file_urls_json
  end

  def bundleFiles

    session_file_dir = Rails.root.join(
      'public',
      'event_data',
      event_id.to_s,
      'session_files'
    )

    published_session_file_dir = Rails.root.join(
      'public',
      'event_data',
      event_id.to_s,
      'session_files_published'
    )

    destination = session_file_dir.join "#{event_name}_session_files.zip"
    dirs        = [ session_file_dir, published_session_file_dir ]

    FileOperations.bundle_directories destination, dirs

  end
end

