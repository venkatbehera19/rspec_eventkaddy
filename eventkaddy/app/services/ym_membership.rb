class YmMembership 
  API_BASE_URL = 'https://ws.yourmembership.com'

  def initialize

    configuration_file_path = File.expand_path('config/your_membership.yml')
    client_configuration    = YAML::load(File.open(configuration_file_path))
    environment             = "default"

    @username  = client_configuration[environment]["username"]
    @password  = client_configuration[environment]["password"] 
    @client_id = client_configuration[environment]["client_id"] 

    @access_token = nil
    @member_id = nil
    @sessionid = nil

  end

  def call auth_code
    # getting the accesstoken
    token_data = get_access_token auth_code
    if token_data["AccessToken"].present?
      # authenicating the member
      authenticate_member = authenticate token_data["AccessToken"]
      if authenticate_member && @member_id.present? && @sessionid.present?
        member = JSON.parse get_member_data
        if member["PersonalInformation"].present? && member["AccountInformation"].present?
          if member["AccountInformation"]["Membership"] != "Compost U Scholar non-USCC-member" || member["AccountInformation"]["Membership"] != "Compost Discussion Group Participant"
            if member["AccountInformation"]["MembershipExpires"] && validate_date(member["AccountInformation"]["MembershipExpiresDate"])
              return {
                status: true,
                message: 'Member details fetched successfully',
                data: {
                  email: member["PersonalInformation"]['Email'],
                  first_name: member["PersonalInformation"]['FirstName'],
                  last_name: member["PersonalInformation"]['LastName'],
                  country: member["PersonalInformation"]['HomeAddressCountry'],
                  city: member["PersonalInformation"]['HomeAddressCity'],
                  mobile_phone: member["PersonalInformation"]["HomePhoneAreaCode"] + member["PersonalInformation"]["HomePhoneNumber"],
                  membership_id: member["AccountInformation"]["MembershipID"],
                  membership: member["AccountInformation"]["Membership"],
                  membership_expires: member["AccountInformation"]["MembershipExpires"],
                  membership_expires_date: member["AccountInformation"]["MembershipExpiresDate"]
                }
              }
            elsif !member["AccountInformation"]["MembershipExpires"]
              return {
                status: true,
                message: 'Member details fetched successfully',
                data: {
                  email: member["PersonalInformation"]['Email'],
                  first_name: member["PersonalInformation"]['FirstName'],
                  last_name: member["PersonalInformation"]['LastName'],
                  country: member["PersonalInformation"]['HomeAddressCountry'],
                  city: member["PersonalInformation"]['HomeAddressCity'],
                  mobile_phone: member["PersonalInformation"]["HomePhoneAreaCode"] + member["PersonalInformation"]["HomePhoneNumber"],
                  membership_id: member["AccountInformation"]["MembershipID"],
                  membership: member["AccountInformation"]["Membership"],
                  membership_expires: member["AccountInformation"]["MembershipExpires"],
                  membership_expires_date: member["AccountInformation"]["MembershipExpiresDate"]
                }
              }
            else
              return { status: false, message: 'Membership Expired'}
            end
          else
            return { status: false, message: 'Invalid membership' }
          end
        else
          return { status: false, message: 'Unable to fetch the member' }
        end
      else
        return { status: false, message: 'Authorization Failed' }
      end
    else
      return { status: false, message: token_data["ResponseStatus"]["Message"] }
    end
  end

  private

  def get_access_token auth_code

    begin
      uri = URI("#{API_BASE_URL}/OAuth/GetAccessToken")
      https = Net::HTTP.new(uri.host, uri.port)
      https.use_ssl = true

      request = Net::HTTP::Post.new(uri.path, initheader = {'Content-Type' =>'application/json'})
  
      request.body = {
        "GrantType": "Code",
        "Code":      auth_code,
        "AppId":     @username,
        "AppSecert": @password
      }.to_json

      response = https.request(request)
      # binding.pry
      if response.code == "200" && response.class.name == "Net::HTTPOK" && response.message == "OK"
        response_data = JSON.parse response.body
        return response_data
      else
        response_data = JSON.parse response.body
        return response_data
      end
      
    rescue => exception
      puts exception
    end

  end

  def authenticate access_token

    begin
      uri   = URI("#{API_BASE_URL}/Ams/Authenticate")
      https = Net::HTTP.new(uri.host, uri.port)
      https.use_ssl = true
      request = Net::HTTP::Post.new(uri.path, initheader = {'Content-Type' =>'application/json'})
      
      request.body = {
        "UserType":       "Member",
        "ClientID":       @client_id,
        "ConsumerKey":    @username,
        "ConsumerSecret": @password,
        "AccessToken":    access_token
      }.to_json

      response = https.request(request)
      if response.code == "200" && response.class.name == "Net::HTTPOK" && response.message == "OK"
        response_data = JSON.parse response.body
        @member_id = response_data["MemberID"]
        @sessionid = response_data["SessionId"]
        return true
      else
        return false
      end
    rescue exception => e
      puts e
    end

  end

  def get_member_data 

    begin
      url   = URI("#{API_BASE_URL}/Ams/#{@client_id}/Member/#{@member_id}/MemberProfile")
      http  = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true

      request = Net::HTTP::Get.new(url)

      request["Accept"] = 'application/json'
      request["X-SS-ID"]      = @sessionid.to_s
      request['Accept-Encoding'] = 'gzip, deflate, br'

      response = http.request(request)
      if response['Content-Encoding'] == 'deflate'
        body = Zlib::Inflate.new(-Zlib::MAX_WBITS).inflate(response.body)
        return body
      else
        return response.body
      end
    rescue => e
      puts e
    end

  end

  def validate_date expires_date
    parsed_expired_date = Time.parse expires_date
    if parsed_expired_date - Time.now  > 0
      return true
    end
    return false
  end

end