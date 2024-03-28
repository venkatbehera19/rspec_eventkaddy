class AttendeeScan < ApplicationRecord
  # attr_accessible :attendee_scan_type_id, :event_id, :initiating_attendee_id, :target_attendee_id, :session_id, :exhibitor_id, :location_mapping_id, :exhibitor_name, :session_code
  
  belongs_to :attendee_scan_type
  belongs_to :event
  belongs_to :session
  belongs_to :exhibitor
  belongs_to :location_mapping
  belongs_to :attendee, :foreign_key => 'initiating_attendee_id', :class_name => "Attendee"
  belongs_to :attendee, :foreign_key => 'target_attendee_id', :class_name => "Attendee"

  def self.iattend_scans_data event_id
    find_by_sql ["SELECT s.account_code AS sender_account_code,
             t.account_code AS target_account_code,
             CONCAT_WS(' ', s.first_name, s.last_name) AS sender_name,
             t.first_name AS target_first_name,
             t.last_name  AS target_last_name,
             sessions.session_code AS session_code,
             sessions.title AS session_title,
             sessions.date AS session_date,
             sessions.start_at AS session_begins,
             sessions.end_at AS session_ends,
             location_mappings.name AS location_name,
             IF(
                (SELECT id FROM sessions_attendees
                  WHERE sessions_attendees.session_id_int=attendee_scans.session_id
                  AND sessions_attendees.attendee_id=attendee_scans.target_attendee_id), TRUE, FALSE
             ) AS favourited,
             attendee_scans.created_at
      FROM attendee_scans
      LEFT OUTER JOIN attendees s         ON attendee_scans.initiating_attendee_id = s.id
      LEFT OUTER JOIN attendees t         ON attendee_scans.target_attendee_id     = t.id
      LEFT OUTER JOIN sessions            ON attendee_scans.session_id             = sessions.id
      LEFT OUTER JOIN location_mappings   ON attendee_scans.location_mapping_id    = location_mappings.id
      WHERE attendee_scans.event_id=? AND attendee_scans.attendee_scan_type_id=5
      GROUP BY attendee_scans.id
      ORDER BY attendee_scans.location_mapping_id, sessions.session_code, sessions.start_at", event_id]
  end

  def self.stats_for_event event_id
    select("
           s.account_code AS sender_account_code,
           t.account_code AS target_account_code,
           CONCAT_WS(' ', s.first_name, s.last_name) AS sender_name,
           CONCAT_WS(' ', t.first_name, t.last_name) AS target_name,
           sessions.session_code AS session_code,
           sessions.title AS session_title,
           t.company AS company_name,
           location_mappings.name AS location_name,
           attendee_scan_types.name AS type_name,
           t.title AS title,
           t.email AS email,
           t.mobile_phone AS phone_number
    ").
      where(event_id: event_id).
      joins("LEFT OUTER JOIN attendees s         ON attendee_scans.initiating_attendee_id = s.id").
      joins("LEFT OUTER JOIN attendees t         ON attendee_scans.target_attendee_id     = t.id").
      joins("LEFT OUTER JOIN exhibitors          ON attendee_scans.exhibitor_id           = exhibitors.id").
      joins("LEFT OUTER JOIN sessions            ON attendee_scans.session_id             = sessions.id").
      joins("LEFT OUTER JOIN location_mappings   ON attendee_scans.location_mapping_id    = location_mappings.id").
      joins("LEFT OUTER JOIN attendee_scan_types ON attendee_scans.attendee_scan_type_id  = attendee_scan_types.id").
      as_json
  end

  # account_code, attendee_name, attendee_group, total_count, count for each type, count for each group
  def self.stats_summary_for_event event_id
    # this method may need to take an argument which specifies
    # the column to be grouped by; and its matching report may
    # need to determine that by a new table
    find_by_sql([
      "SELECT initiating_attendee_id,
              CONCAT_WS(' ', ia.first_name, ia.last_name) AS name,
              ia.id,
              ia.account_code,
              ia.business_unit                       AS 'group',
              COUNT(target_attendee_id)              AS meetings_count,
              COUNT(session_id)                      AS session_scans_count,
              COUNT(exhibitor_id)                    AS exhibitor_scans_count,
              COUNT(location_mapping_id)             AS location_scans_count,
              COUNT(initiating_attendee_id)          AS total
       FROM attendee_scans
       LEFT OUTER JOIN attendees ia ON ia.id=initiating_attendee_id
       WHERE attendee_scans.event_id=?
       GROUP BY initiating_attendee_id", event_id
    ]).as_json(root: true)
  end
end
       # LEFT OUTER JOIN attendees ta ON ta.id = target_attendee_id
              # GROUP_CONCAT( ta.id ) AS group_ids
              # (SELECT GROUP_CONCAT(t.g_count) AS group_counts
              #    FROM (SELECT CONCAT_WS(':', a.business_unit, COUNT(a.id)) AS g_count
              #          FROM attendees a
              #          WHERE a.id IN (
              #            SELECT id
              #            FROM attendees ab
              #            WHERE ab.id=ta.id
              #          )
              #          GROUP BY a.business_unit) t) AS group_counts
    # select("initiating_attendee_id,
    #        CONCAT_WS(' ', ia.first_name, ia.last_name) AS name,
    #        ia.id,
    #        ia.account_code,
    #        ia.business_unit                       AS 'group',
    #        COUNT(target_attendee_id)              AS meetings_count,
    #        COUNT(session_id)                      AS session_scans_count,
    #        COUNT(exhibitor_id)                    AS exhibitor_scans_count,
    #        COUNT(location_mapping_id)             AS location_scans_count,
    #        COUNT(initiating_attendee_id)          AS total,
    #        GROUP_CONCAT( ta.id ) AS group_ids,
    #        (SELECT GROUP_CONCAT(t.g_count) AS group_counts
    #           FROM (SELECT CONCAT_WS(':', a.business_unit, COUNT(a.id)) AS g_count
    #                 FROM attendees a
    #                 WHERE a.id IN (GROUP_CONCAT( ta.id ))
    #                 GROUP BY a.business_unit) t) AS group_counts
    #        ").
    #   where(event_id: event_id).
    #   joins('LEFT OUTER JOIN attendees ia ON ia.id=initiating_attendee_id').
    #   joins('LEFT JOIN attendees ta ON ta.id = target_attendee_id').
    #   group("initiating_attendee_id").
    #   as_json. # misnomer, to_json is a string of json, as_json is a ruby hash
    #   map {|a| a['attendee_scan'] }

      # joins("LEFT OUTER JOIN (SELECT t.id, GROUP_CONCAT(t.g_count) AS group_counts
      #         FROM (SELECT a.id, CONCAT_WS(':', a.business_unit, COUNT(a.id)) AS g_count
      #               FROM attendees a
      #               GROUP BY a.business_unit) t) t2 ON t2.id=target_attendee_id").

           # (SELECT GROUP_CONCAT(t.g_count) AS group_counts
           #    FROM (SELECT CONCAT_WS(':', a.business_unit, COUNT(a.id)) AS g_count
           #          FROM attendees a
           #          WHERE a.id IN (GROUP_CONCAT( ta.id ))
           #          GROUP BY a.business_unit) t) AS group_counts

           # ( 
           #       SELECT CONCAT_WS(':', a.business_unit, COUNT(*)) AS g_count
           #       FROM attendees a
           #       WHERE a.id IN (GROUP_CONCAT( ta.id ))
           #       GROUP BY a.business_unit
           # )) AS group_counts

           # GROUP_CONCAT(target_attendees.g_count) AS group_counts

      # joins("JOIN ( 
      #           SELECT a.id, CONCAT_WS(':', a.business_unit, COUNT(*)) AS g_count
      #           FROM attendees a
      #           GROUP BY business_unit
      # ) target_attendees ON target_attendees.id=target_attendee_id").


# AttendeeScan.stats_summary_for_event(170).first
 # AttendeeScan.stats_summary_for_event(170).first
 #   [1m[36mAttendeeScan Load (149.1ms)[0m  [1mSELECT initiating_attendee_id,
 #  CONCAT_WS(' ', ia.first_name, ia.last_name) AS name,
 #  ia.id,
 #  ia.account_code,
 #  ia.business_unit AS 'group',
 #  COUNT(target_attendee_id) AS meetings_count,
 #  COUNT(session_id) AS session_scans_count,
 #  COUNT(exhibitor_id) AS exhibitor_scans_count,
 #  COUNT(location_mapping_id) AS location_scans_count,
 #  COUNT(initiating_attendee_id) AS total,
 #  GROUP_CONCAT( ta.id ) AS group_ids,
 #  t2.group_counts
 #  FROM `attendee_scans` LEFT OUTER JOIN attendees ia ON ia.id=initiating_attendee_id LEFT JOIN attendees ta ON ta.id = target_attendee_id LEFT OUTER JOIN (SELECT t.id, GROUP_CONCAT(t.g_count) AS group_counts
 #  FROM (SELECT a.id, CONCAT_WS(':', a.business_unit, COUNT(a.id)) AS g_count
 #  FROM attendees a
 #  GROUP BY a.business_unit) t) t2 ON t2.id=target_attendee_id WHERE `attendee_scans`.`event_id` = 170 GROUP BY initiating_attendee_id[0m
 #   [1m[35mAttendeeScan Load (142.9ms)[0m  SELECT initiating_attendee_id,
 #  CONCAT_WS(' ', ia.first_name, ia.last_name) AS name,
 #  ia.id,
 #  ia.account_code,
 #  ia.business_unit AS 'group',
 #  COUNT(target_attendee_id) AS meetings_count,
 #  COUNT(session_id) AS session_scans_count,
 #  COUNT(exhibitor_id) AS exhibitor_scans_count,
 #  COUNT(location_mapping_id) AS location_scans_count,
 #  COUNT(initiating_attendee_id) AS total,
 #  GROUP_CONCAT( ta.id ) AS group_ids,
 #  t2.group_counts
 #  FROM `attendee_scans` LEFT OUTER JOIN attendees ia ON ia.id=initiating_attendee_id LEFT JOIN attendees ta ON ta.id = target_attendee_id LEFT OUTER JOIN (SELECT t.id, GROUP_CONCAT(t.g_count) AS group_counts
 #  FROM (SELECT a.id, CONCAT_WS(':', a.business_unit, COUNT(a.id)) AS g_count
 #  FROM attendees a
 #  GROUP BY a.business_unit) t) t2 ON t2.id=target_attendee_id WHERE `attendee_scans`.`event_id` = 170 GROUP BY initiating_attendee_id
 # {"account_code"=>"ourcode254523", "exhibitor_scans_count"=>0, "group"=>"Biller", "group_counts"=>nil, "group_ids"=>"254703,254799,254698,254843,254814,254862,254548,254635,254638", "id"=>254523, "initiating_attendee_id"=>254523, "location_scans_count"=>0, "meetings_count"=>9, "name"=>"Mike Aaron", "session_scans_count"=>0, "total"=>9}
 # 
