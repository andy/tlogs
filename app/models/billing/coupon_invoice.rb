# == Schema Information
# Schema version: 20110816190509
#
# Table name: invoices
#
#  id         :integer(4)      not null, primary key
#  user_id    :integer(4)      not null, indexed
#  state      :string(255)     not null
#  type       :string(255)     not null
#  metadata   :string(255)     not null
#  amount     :float           default(0.0), not null
#  revenue    :float           default(0.0), not null
#  days       :integer(4)      default(0), not null
#  remote_ip  :string(255)
#  created_at :datetime
#  updated_at :datetime
#
# Indexes
#
#  index_invoices_on_user_id  (user_id)
#

class CouponInvoice < Invoice
  def summary
    "Скидочный купон на сумму #{self.amount} руб."
  end
end
