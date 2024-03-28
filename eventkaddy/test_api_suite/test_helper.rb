require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

   self.set_fixture_class event_file_photo: EventFile
   self.set_fixture_class event_file_cv: EventFile
   self.set_fixture_class event_file_fd: EventFile
   self.set_fixture_class attendee: Attendee


  # Add more helper methods to be used by all tests here...
  def match_schema(schema,response)
      schema_directory = "#{Dir.pwd}/test/schemas"
      schema_path = "#{schema_directory}/#{schema}.json"
      # JSON::Validator.validate!(schema_path, response, strict: true)
      # Don't think we want strict:true here as it was overriding 
      # our required properties in the schema
      JSON::Validator.validate!(schema_path, response)
  end

  def json_response
    JSON.parse(response.body)
  end

  def headers_call
    {"HTTP_AUTHORIZATION" => "Token token=#{API_PROXY_KEY}"}
  end

  def api_pass
    API_PROXY_KEY
  end
end
