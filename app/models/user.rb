# frozen_string_literal: true
class User < RedisStore
  NAMESPACE = REDIS_CONFIG['user_store']['namespace']
  REDIS_STORE = Redis::Namespace.new(NAMESPACE, redis: Redis.current)
  DEFAULT_TTL = REDIS_CONFIG['user_store']['each_ttl']

  # id.me attributes
  attribute :uuid
  attribute :email
  attribute :first_name
  attribute :last_name
  attribute :zip

  # vaafi attributes
  attribute :edipi
  attribute :issue_instant
  attribute :participant_id
  attribute :ssn

  # Add additional MVI attributes
  alias redis_key uuid

  validates :uuid, presence: true
  validates :email, presence: true

  def self.sample_claimant
    User.new(
      first_name: 'Jane',
      last_name: 'Doe',
      issue_instant: '2015-04-17T14:52:48Z',
      edipi: '1105051936',
      participant_id: '123456789'
    )
  end
end
