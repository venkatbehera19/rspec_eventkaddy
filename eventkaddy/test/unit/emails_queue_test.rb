require 'test_helper'

# From rails documentation:
# Fixtures are not designed to create every object that your tests need, and
# are best managed when only used for default data that can be applied to the
# common case.

class EmailsQueueTest < ActiveSupport::TestCase

  test "cancel emails for event" do

    pending_count_before_cancel = EmailsQueue.where(event_id: 1, status: 'pending').length

    assert pending_count_before_cancel > 0,
      'Emails queue did not have more than zero pending emails, which would invalidate testing cancellation.'

    EmailsQueue.cancel_emails_for_event 1

    assert EmailsQueue.where(event_id: 1, status: 'pending').length == 0,
      'Emails queue should not have had any records pending'

    # tricky, american and british spelling of past tense of cancel easy to mix up
    assert EmailsQueue.where(event_id: 1, status: 'cancelled').length >= pending_count_before_cancel,
      'Number of emails cancelled should be equal or greater than the amount pending before cancel'
  end

  test "cancel emails for all events" do

    pending_count_before_cancel = EmailsQueue.where(status: 'pending').length

    assert_operator pending_count_before_cancel, :>, 0,
      'Emails queue did not have more than zero pending emails, which would invalidate testing cancellation.'

    EmailsQueue.cancel_all_emails

    assert EmailsQueue.where(status: 'pending').length == 0,
      'Emails queue should not have had any records pending'

    assert EmailsQueue.where(status: 'cancelled').length >= pending_count_before_cancel,
      'Number of emails cancelled should be equal or greater than the amount pending before cancel'

    # here it would be temping to count the number of cancelled emails, but
    # that would make the test fragile since any changes to the fixtures would
    # break it. To make it less fragile, we would have to have a setup and
    # cleanup phase specific to this test, or do a count of the number of
    # emails already cancelled
    #
    # Actually, we could just get a count instead, and make sure the numbers lined up
    #
    # One convenient thing, if we don't do that, is that fixtures cleanup and
    # rebuild on their own between each test
  end

  # I wrote many of the features related to this without automated tests...
  # quite a few months after this initial work was done, since other things came up

end
