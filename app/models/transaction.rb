# == Schema Information
#
# Table name: transactions
#
#  id         :integer(4)      not null, primary key
#  user_id    :integer(4)      not null
#  amount     :integer(4)      not null
#  state      :string(255)     default("pending"), not null
#  created_at :datetime
#  updated_at :datetime
#

class Transaction < ActiveRecord::Base
  ## associations
  belongs_to :user
  
  ## named scopes
  named_scope :pending, :conditions => { :state => 'pending' }
  named_scope :success, :conditions => { :state => 'success' }
  named_scope :fail, :conditions => { :state => 'fail' }
  
  ## validations
  validates_inclusion_of :state, :in => %w(pending success fail)
end
