class ChangeAttendeesFirstNameAndLastNameToUtf8mb4 < ActiveRecord::Migration[6.1]
  def change
     # for each table that will store unicode execute:
    execute "ALTER TABLE attendees CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_bin"
    # for each string/text column with unicode content execute:
    execute "ALTER TABLE attendees MODIFY first_name VARCHAR(191) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci"
    execute "ALTER TABLE attendees MODIFY last_name VARCHAR(191) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci"
    # for database to change collation from utf8 utf8mb4
    execute "ALTER DATABASE #{connection.current_database} CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci"
  end
end
