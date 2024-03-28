class GetReport

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
    'o2i9j3f8a9jkasdlck1ansejfh23ugf98273bcijw2b3claw83'
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
    'https://reporting.eventkaddy.net'
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