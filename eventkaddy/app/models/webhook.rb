class Webhook < ApplicationRecord
  STATUS = ['transaction.authorized', 'transaction.completed', 'transaction.voided', 'transaction.failed', 'transaction.updated']
end
