class GetGame

  def initialize(args)
    post_initialize(args)
  end

  def call
    start_get
  end

  private

  def http_failure_message
    "#{self.class.name} HTTP failure at #{Time.now}"
  end

  def proxy_key
    '2o39uj0a9wcjaw3490ru29f2jajfb3akjwbc45aksjznc8775xjkdhfa'
  end

  def start_get
    result = get
    puts result['message'] if result.is_a?(Hash) && result['status'] == false
    result['result']
  end

  def url
    base_url + params
  end

  def base_url
    'https://game.eventkaddy.net'
  end

  def get
    resp = Curl.get url
    JSON.parse resp.body_str
  rescue => e
    puts http_failure_message; puts e
  end

  ## Overwritten by children
  def post_initialize

  end

  def params
    ''
  end

end