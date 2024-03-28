require 'test_helper'

class ModelInfoTest < ActiveSupport::TestCase

  test "get dependent destroy associations" do
    result = ModelInfo.dependent_destroy_associations_for Session

    # a little fragile to specify the exact properties; a better
    # pattern would be to just test the association prop had this
    assert_includes(
      result, 
      {
        :association => :sessions_speakers,
        :class_name => "SessionsSpeaker",
        :foreign_key => :session_id,
        :macro       => :has_many,
        :children    => []
      },
      "should contain :sessions_speakers association"
    )



    assert_includes(
      result,
      {
        :association=>:session_files,
        :class_name => "SessionFile",
        :foreign_key => :session_id,
        :macro => :has_many,
        :children=>[
          {
            :association=>:session_file_versions,
            :class_name => "SessionFileVersion",
            :foreign_key => :session_file_id,
            :macro => :has_many,
            :children=>[
              {
                :association=>:event_file, 
                :class_name => "EventFile",
                :foreign_key => :event_file_id,
                :macro => :belongs_to,
                :children=>[
                  {
                    :association=>:exhibitor_file,
                    :class_name => "ExhibitorFile",
                    :foreign_key => :event_file_id,
                    :macro => :has_one,
                    :children=>[]}
                ]
              }
            ]
          }
        ]
      },
      "should contain :session_files association and its children; should handle
      circular relationship"
    )

  end

  # session is useful for testing this method
  # as it has some very deeply nested relationships,
  # like with session_file_versions
  def test_count_of_each_association

    # setup
    session = session_with_two_session_file_versions 1

    # test
    result = ModelInfo.count_of_each_association session
    assert_kind_of Array, result, true

    session_files_result = result.find {|s| s[:association] == :session_files}
    assert_equal(
      1,
      session_files_result[:count],
      "should have count of 1 session files"
    )

    session_file_versions_result = session_files_result[:children].find {|s| 
      s[:association] == :session_file_versions }
    assert_equal(
      2,
      session_file_versions_result[:count],
      "should have count of 2 session_file_versions"
    )

    event_file_results = session_file_versions_result[:children]

    assert_equal(
      2,
      event_file_results.reduce(0) {|m, e| m + e[:count] },
      "should have count of 2 event files across session_file_versions"
    )

    assert_equal(
      :exhibitor_file,
      event_file_results[0][:children][0][:association],
      "first session_file_version result should have an exhibitor_file association"
    )

    assert_equal(
      :exhibitor_file,
      event_file_results[1][:children][0][:association],
      "second session_file_version result should also have an exhibitor_file association"
    )

    # cleanup
    session.destroy
  end

  # speaker have some examples of other relationships
  # we care about, including foreign keys and has_one and
  # belongs_to, so it's a good candidate for verifying
  # the effectiveness of this method
  def test_count_of_each_association_for_speaker

    # setup
    speaker = speaker_with_payment_detail_and_photo 1

    # test
    result = ModelInfo.count_of_each_association speaker

    speaker_payment_detail_result = result.find {|s| 
      s[:association] == :speaker_payment_detail}

    assert_equal(
      1,
      speaker_payment_detail_result[:count],
      "should have count of 1 speaker payment detail"
    )

    event_file_photo = result.find {|s| s[:association] == :event_file_photo}

    assert_equal(
      1,
      event_file_photo[:count],
      "should have count of 1 event_file_photo"
    )

    # cleanup
    speaker.destroy
  end

  def test_sum_count_of_each_association
    session = session_with_two_session_file_versions 1
    
    assert_equal(
      5,
      ModelInfo.sum_count_of_each_association( session )
    )

    # cleanup
    session.destroy
  end

  def test_count_all_dependent_destroy_records_for_event
    session = session_with_two_session_file_versions 1
    session_2 = session_with_two_session_file_versions 1
    # a dummy session for a different event_id to make
    # sure we're only counting the right event
    session_3 = session_with_two_session_file_versions 2

    result = ModelInfo.count_all_dependent_destroy_records_for_event(
      Session,
      :event_id,
      [1]
    )

    assert_equal(
      2,
      result[:session],
      "should have count of 2 sessions"
    )

    assert_equal(
      2,
      result[:session_file],
      "should have count of 2 session files"
    )

    assert_equal(
      4,
      result[:session_file_version],
      "should have count of 4 session file versions"
    )

    # Cleanup
    [session, session_2, session_3].each{|s| s.destroy }
  end

  def test_count_all_dependent_destroy_records_for_event_for_speaker
    speaker = speaker_with_payment_detail_and_photo 1
    speaker_2 = speaker_with_payment_detail_and_photo 1
    # a dummy session for a different event_id to make
    # sure we're only counting the right event
    speaker_3 = speaker_with_payment_detail_and_photo 2

    result = ModelInfo.count_all_dependent_destroy_records_for_event(
      Speaker,
      :event_id,
      [1]
    )

    assert_equal(
      2,
      result[:speaker],
      "should have count of 2 sessions"
    )

    assert_equal(
      2,
      result[:event_file_photo],
      "should have count of 2 event file photos"
    )

    # Cleanup
    [speaker, speaker_2, speaker_3].each{|s| s.destroy }
  end

  private

  def session_with_two_session_file_versions event_id
    session = Session.create(event_id:event_id)
    session.save( validate: false )

    session_file = SessionFile.create( session_id: session.id )
    session_file.save( validate: false )

    event_file = EventFile.create( event_id: event_id )
    event_file.save( validate: false )
    event_file_2 = EventFile.create( event_id: event_id )
    event_file_2.save( validate: false )

    session_file_version = SessionFileVersion.create(
      session_file_id: session_file.id,
      event_file_id: event_file.id
    )
    session_file_version.save( validate: false )

    # pp session_file_version.id

    session_file_version_2 = SessionFileVersion.create(
      session_file_id: session_file.id,
      event_file_id: event_file_2.id
    )
    session_file_version_2.save( validate: false )

    session
  end

  def speaker_with_payment_detail_and_photo event_id
    speaker = Speaker.create(event_id:event_id)
    speaker.save( validate: false )

    speaker_payment_detail = SpeakerPaymentDetail.create( speaker_id: speaker.id )
    speaker_payment_detail.save( validate: false )

    event_file_photo = EventFile.create( event_id: event_id )
    event_file_photo.save( validate: false )

    speaker.photo_event_file_id = event_file_photo.id
    speaker.save( validate: false )

    speaker
  end

end
