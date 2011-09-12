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

class Invoice < ActiveRecord::Base
  ## attributes and constants
  serialize :metadata, HashWithIndifferentAccess


  ## associations
  belongs_to :user
  
  
  ## named scopes
  named_scope     :for_user,
                  lambda { |user| { :conditions => "user_id = #{user.id}" } }

  named_scope     :pending,
                  :conditions => { :state => 'pending' }

  named_scope     :successful,
                  :conditions => { :state => 'successful' }

  named_scope     :failed,
                  :conditions => { :state => 'failed' }

  
  ## validations
  validates_inclusion_of  :state,
                          :in => %w(pending successful failed)

  validates_presence_of   :user

  validates_presence_of   :amount
  
  validates_presence_of   :revenue
  
  validates_presence_of   :days

  validates_presence_of   :metadata


  ## callbacks
  after_create            :expand_premium_for_user!, :if => :is_successful?


  ## public methods
  def is_pending?
    state == 'pending'
  end

  def is_successful?
    state == 'successful'
  end
  
  def success!
    update_attribute :state, 'successful'
  end
  
  def fail!
    update_attribute :state, 'failed'
  end

  def is_failed?
    state == 'failed'
  end

  def deliver!(current_service)
    Emailer.deliver_invoice(current_service, self) if is_successful?
  end

  def summary
    ''
  end

  def extra_summary
    ''
  end
  
  def pref_key
    nil
  end
  
  def pref_options
    nil
  end

  def expand_premium_for_user!
    user.update_attribute(:premium_till, ((user.premium_till || Time.now) + self.days.days).end_of_day + 8.hours)
  end 
  
  ## protected methods
  protected
end
