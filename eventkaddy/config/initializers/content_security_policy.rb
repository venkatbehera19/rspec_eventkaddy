# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy
# For further information see the following documentation
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy

# Rails.application.config.content_security_policy do |policy|
#   policy.default_src :self, :https
#   policy.font_src    :self, :https, :data
#   policy.img_src     :self, :https, :data
#   policy.object_src  :none
#   policy.script_src  :self, :https
#   policy.style_src   :self, :https
#   # If you are using webpack-dev-server then specify webpack-dev-server host
#   policy.connect_src :self, :https, "http://localhost:3035", "ws://localhost:3035" if Rails.env.development?

#   # Specify URI for violation reports
#   # policy.report_uri "/csp-violation-report-endpoint"
# end

# If you are using UJS then enable automatic nonce generation
# Rails.application.config.content_security_policy_nonce_generator = -> request { SecureRandom.base64(16) }

# Set the nonce only to specific directives
# Rails.application.config.content_security_policy_nonce_directives = %w(script-src)

# Report CSP violations to a specified URI
# For further information see the following documentation:
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy-Report-Only
# Rails.application.config.content_security_policy_report_only = true

Rails.application.config.content_security_policy do |policy|
  # define the video portal url for iframes
  policy.frame_ancestors :self, 'http://localhost:3001', 'https://aphrodite.eventkaddy.net', 'https://nj-paralegal-21.eventkaddy.net', 'https://bcbswlf21.eventkaddy.net','https://bcbshoa21.eventkaddy.net','https://sdafp2021.eventkaddy.net','https://bhi2021.eventkaddy.net'
end


# Rails.application.config.content_security_policy do |policy|
# 	unless Rails.env.development?
# 		policy.default_src :self, :https
# 		policy.font_src    :self, :https, :data
# 		policy.img_src     :self, :https, :data
# 		policy.object_src  :none
# 		policy.script_src  :self, :https, :unsafe_inline, "https://railschataphrodite.eventkaddy.net" # added rails chat for faye
# 		policy.style_src   :self, :https, :unsafe_inline, "https://railschataphrodite.eventkaddy.net" # added rails chat for faye
# 		policy.connect_src :self, :https, :wss, "https://railschataphrodite.eventkaddy.net" # added rails chat for faye
# 		#policy.report_uri "/csp-violation-report-endpoint"
# 	end

# 	# define the video portal url for iframes
# 	policy.frame_ancestors :self, 'http://localhost:3001', 'https://aphrodite.eventkaddy.net', 'https://nj-paralegal-21.eventkaddy.net', 'https://bcbswlf21.eventkaddy.net','https://bcbshoa21.eventkaddy.net','https://sdafp2021.eventkaddy.net','https://bhi2021.eventkaddy.net'
# end


OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
