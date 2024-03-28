class AttendeesAppBadge < ApplicationRecord

  # attr_accessible :app_badge_id, :attendee_id, :event_id, :app_badge_points_collected, :num_app_badge_tasks_completed, :complete, :prize_redeemed
  
  belongs_to :app_badge
  belongs_to :attendee

  # this is the old function used by cms only; almost identitcal to top_ten = 
  # except that the name is concatonated here.
  def self.top_ten_by_points event_id
    find_by_sql ["
      SELECT *, 
             SUM(app_badge_points_collected) AS points,
             CONCAT(attendees.first_name, ' ', attendees.last_name) AS name,
             attendees.account_code,
             MAX( attendees_app_badges.updated_at ) AS most_recent_update
      FROM attendees_app_badges
      JOIN attendees ON attendees_app_badges.attendee_id=attendees.id
      WHERE attendees_app_badges.event_id=? AND app_badge_points_collected IS NOT NULL
      GROUP BY attendee_id
      ORDER BY points DESC, most_recent_update ASC
      LIMIT 20", event_id]
  end

  # for avma, a function that orders attendees by how soon they
  # completed all app_badges
  def self.leaderboard_by_all_badges_completed_time event_id, limit = false
    limit = limit ? "LIMIT #{limit.to_i}" : ""
    find_by_sql ["
      SELECT *
      FROM(
        SELECT
          COUNT( attendees_app_badges.id ) AS badges_completed,
          SUM( app_badge_points_collected ) AS points,
          CONCAT( attendees.first_name, ' ', attendees.last_name ) AS name,
          attendees.account_code,
          complete,
          MAX( attendees_app_badges.updated_at ) AS most_recent_update
            FROM attendees_app_badges
            JOIN attendees ON attendees_app_badges.attendee_id=attendees.id
            WHERE attendees_app_badges.event_id=? AND app_badge_points_collected IS NOT NULL AND complete = 1
            GROUP BY attendee_id
            ORDER BY badges_completed DESC, most_recent_update ASC
            #{limit}
      ) AS top_ten
      WHERE badges_completed = (
        SELECT COUNT(id) FROM app_badges WHERE event_id = ?
      )
      ORDER BY badges_completed DESC, most_recent_update ASC;", event_id, event_id]
  end

  # get limit records starting from offset + 1
  # The SUM on complete is overly clever, but I don't know
  # a better way to count the badges_completed
  def self.leaderboard_slice event_id, limit, offset
    find_by_sql(["
      SELECT SUM(app_badge_points_collected) AS points,
             CONCAT(attendees.first_name, ' ', attendees.last_name) AS name,
             attendees.email,
             attendees.account_code,
             SUM(complete) AS badges_completed,
             MAX( attendees_app_badges.updated_at ) AS most_recent_update
      FROM attendees_app_badges
      JOIN attendees ON attendees_app_badges.attendee_id=attendees.id
      WHERE attendees_app_badges.event_id=? AND app_badge_points_collected IS NOT NULL
      GROUP BY attendee_id
      ORDER BY points DESC, most_recent_update ASC
      LIMIT ? OFFSET ?", event_id, limit, offset])
  end

  # this is used by cms api, and should be shared by newcms
  def self.leaderboard event_id, account_code

    # http://fellowtuts.com/mysql/query-to-obtain-rank-function-in-mysql/
    # it's possible to do the rank calculation purely in SQL, but I've done
    # it in ruby here for simplicity. Above link shows how you can use
    # variables in SQL.

    top_ten = find_by_sql(["
      SELECT SUM(app_badge_points_collected) AS points,
             attendees.first_name, attendees.last_name,
             attendees.account_code, attendees.event_id AS event_id,
             MAX( attendees_app_badges.updated_at ) AS most_recent_update
      FROM attendees_app_badges
      JOIN attendees ON attendees_app_badges.attendee_id=attendees.id
      WHERE attendees_app_badges.event_id=? AND app_badge_points_collected IS NOT NULL
      GROUP BY attendee_id
      ORDER BY points DESC, most_recent_update ASC
      LIMIT 20", event_id])
      .map {|a| a.as_json['attendees_app_badge']} # remove wrapping "attendees_app_badge" key

    rank, i = 1, 0
    top_ten.each {|a|
      i += 1
      # original allowing ties for same number of points
      # a['rank'] = a['points'] != top_ten[i-2]['points'] ? rank = i : rank
      # new version to break ties by updated_at
      a['rank'] = i
    }

    # if account_code wasn't in the top ten, add it so attendee can see their rank
    unless !account_code || top_ten.select {|a| a['account_code'] == account_code }.length > 0
      top_ten << ranking_hash_for(event_id, account_code)
    end
    top_ten
  end

  def self.ranking_hash_for(event_id, account_code)
      result = Attendee
        .select('id, first_name, last_name, account_code, event_id')
        .where(account_code:account_code, event_id:event_id)
        .first
        .as_json
      
      if result
        result           = result['attendee']
        result['points'] = AttendeesAppBadge.points result["id"]
        result['most_recent_update'] = AttendeesAppBadge.most_recent_update result["id"]
        result['rank']   = AttendeesAppBadge.rank( 
          event_id, result['account_code'], result['points'], result['most_recent_update']
        )
        result['not_in_top_ten'] = result['rank'] > 20
      end
    result
  end

  def self.points attendee_id
    AttendeesAppBadge
      .where(attendee_id: attendee_id)
      .pluck(:app_badge_points_collected)
      .reduce(:+) || 0
  end

  def self.most_recent_update attendee_id
    AttendeesAppBadge
      .select('updated_at')
      .where(attendee_id: attendee_id)
      .order('updated_at DESC')
      .first
      .updated_at
  end

  def self.rank event_id, account_code, points, most_recent_update
    # this sum logic is potentially slow, but an unavoidable step
    # since we no longer have direct counts of an attendee's points
    # the additional date comparisons needed for tie breaking
    most_recent_update = most_recent_update.strftime("%F %T")
    find_by_sql(["
      SELECT SUM(app_badge_points_collected) AS points,
             MAX( attendees_app_badges.updated_at ) AS most_recent_update
      FROM attendees_app_badges
      JOIN attendees ON attendees_app_badges.attendee_id=attendees.id
      WHERE attendees_app_badges.event_id=? AND app_badge_points_collected IS NOT NULL AND attendees.account_code <> ? 
      GROUP BY attendee_id
      HAVING points > ? 
        OR (
               points = ? AND DATE(most_recent_update) < DATE(?) OR
               (points = ? AND DATE(most_recent_update) = DATE(?) AND TIME(most_recent_update) < TIME(?))
           )", 
          event_id, account_code, points, points, most_recent_update, points, most_recent_update, most_recent_update]).size + 1
  end

end

