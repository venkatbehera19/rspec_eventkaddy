class EventStatusOnReportingDb

  def initialize(event)
    @event = event
  end

  def call
    check_event_status
  end

  private

  attr_reader :event

  def check_event_status
    JSON.parse(event_status.body_str)['status']
  end

  def url
    'https://reporting.eventkaddy.net/event_has_reporting'
  end

  def data
    {"proxy_key" => 'o2i9j3f8a9jkasdlck1ansejfh23ugf98273bcijw2b3claw83', "event" => {'id' => event.id}}.to_json
  end

  def event_status
    Curl::Easy.http_post(url, data) do |curl|
      curl.headers['Accept']       = 'application/json'
      curl.headers['Content-Type'] = 'application/json'
      curl.headers['Api-Version']  = '2.2'
    end
  end

end