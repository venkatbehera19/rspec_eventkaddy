class Domain < ApplicationRecord
  # attr_accessible :domain, :domain_type_id, :event_id, :subdomain

  belongs_to :domain_type

  def full_domain
    "https://#{subdomain}.#{domain}"
  end
end
