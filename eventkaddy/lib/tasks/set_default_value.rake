namespace :set_default_value do
  desc "Set sessions unpublished column default value to false"
  task :sessions_unpublished_on_demand_and_premium_access_to_false => :environment do
    Session.where(unpublished: nil).update_all(unpublished: false)
    Session.where(premium_access: nil).update_all(premium_access: false)
    Session.where(on_demand: nil).update_all(on_demand: false)

  end
end
