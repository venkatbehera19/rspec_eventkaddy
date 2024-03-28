# desc 'Say hello!'
# task :hello_world do
#   puts "Hello"
# end

namespace :db do
  desc "Verify Legacy/Existing Users with role SuperAdmin/Client."
   task :verify_users => :environment do
    # get only SuperAdmin and Client type Users
    # users = User.joins(:users_roles).where(users_roles: { role_id: [ SUPER_ADMIN_ROLE_ID,CLIENT_ROLE_ID ] })
    begin
      User.all.each do |u|
        # Make users as confirmed
        u.confirmed_at = Time.now
        u.save!
      end
      puts "Users are confirmed!"
    rescue => error
      puts error.inspect
    end
  end
end