class SessionsAttendee < ApplicationRecord

	belongs_to :session
	belongs_to :attendee

  # session_id is a string, which makes queries on this table extremely slow
  # so a new column is available to make joins on, but it has to be updated first
  # overall it should be faster to run the updates, then due the query.
  # updating the whole table could be really slow, so just do it on recent records
  # still a bit slow, but hopefully tolerable
  def self.update_session_id_int_from_2019_on
    where('created_at > "2019-01-01 00:00:00" AND session_id_int IS NULL').
      update_all("session_id_int=session_id")
  end

  def self.favourite_counts_by_session_code event_id, date=nil
    q = where( session_id: Session.where(event_id: event_id).pluck(:id) )
    q = q.where(date:date) if date
    codes = q.order(:session_code).pluck(:session_code)
    # codes.uniq.map{|code| { code => codes.count(code) } }

    # delete_if is slightly faster, since it removes items we're iterating over
    r = {}
    codes.uniq.each{|code|
      count = 0
      codes.delete_if {|x| if x == code then count += 1; true end }
      r[code.to_s] = count
    }
    r
  end

end

