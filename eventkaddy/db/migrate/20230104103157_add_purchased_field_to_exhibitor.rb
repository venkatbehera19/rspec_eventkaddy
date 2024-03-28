class AddPurchasedFieldToExhibitor < ActiveRecord::Migration[6.1]
  def change
    add_column :exhibitors, :reg_payment_required, :boolean, default: 'false' #reg_payment_required
    add_column :exhibitors, :reg_payment_done, :boolean, default: 'false'#reg_payment_done
  end
end
