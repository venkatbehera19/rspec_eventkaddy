class AddVerifierIdAndVerifiedAtToResponses < ActiveRecord::Migration[6.1]
  def change
    add_column :responses, :verifier_id, :integer
    add_column :responses, :verified_at, :datetime
  end
end
