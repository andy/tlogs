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
