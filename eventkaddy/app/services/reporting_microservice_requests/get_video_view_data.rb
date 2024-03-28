class GetVideoViewData < GetReport

  def post_initialize(event_id)
    @event_id = event_id
  end

  private

  attr_reader :event_id

  def params
    "/session_view_data?proxy_key=#{proxy_key}&event_id=#{event_id}"
  end

end
