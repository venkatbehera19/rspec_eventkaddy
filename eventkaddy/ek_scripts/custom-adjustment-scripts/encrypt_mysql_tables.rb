require_relative '../settings.rb' #config

require 'active_record'

require_relative '../../config/environment.rb'


ActiveRecord::Base.establish_connection(
  :adapter => "mysql2",
  :host => @db_host,
  :username => @db_user,
  :password => @db_pass,
  :database => @db_name
)


def encrypt_tables()
  sql = "SELECT DISTINCT TABLE_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = 'rails5api';"
  tnames = ActiveRecord::Base.connection.execute(sql)
  print tnames
  tnames.each do |tn|
    sql = "ALTER TABLE #{tn.join} ENCRYPTION='Y';"
    ActiveRecord::Base.connection.execute(sql)
  end
end

encrypt_tables()