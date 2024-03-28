class SurveyCeCertificate < ApplicationRecord
  belongs_to :survey
  belongs_to :ce_certificate
end
