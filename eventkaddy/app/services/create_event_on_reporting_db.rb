class CreateEventOnReportingDb

  def initialize(event)
    @event = event
  end

  def call
    create_event
  end

  private

  attr_reader :event

  def create_event
    create_event_response.body_str
  end

  def url
    'https://reporting.eventkaddy.net/add_event'
  end

  def data
    {"proxy_key" => 'o2i9j3f8a9jkasdlck1ansejfh23ugf98273bcijw2b3claw83', "event" => {'name' => event.name, 'id' => event.id}}.to_json
  end

  def create_event_response
    Curl::Easy.http_post(url, data) do |curl|
      curl.headers['Accept']       = 'application/json'
      curl.headers['Content-Type'] = 'application/json'
      curl.headers['Api-Version']  = '2.2'
    end
  end

end