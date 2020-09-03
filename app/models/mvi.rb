# frozen_string_literal: true

require 'mvi/responses/find_profile_response'
require 'common/models/redis_store'
require 'common/models/concerns/cache_aside'

# Facade for MVI. User model delegates MVI correlation id and VA profile (golden record) methods to this class.
# When a profile is requested from one of the delegates it is returned from either a cached response in Redis
# or from the MVI SOAP service.
class Mvi < Common::RedisStore
  include Common::CacheAside

  REDIS_CONFIG_KEY = :mvi_profile_response
  redis_config_key REDIS_CONFIG_KEY

  # @return [User] the user to query MVI for.
  attr_accessor :user

  # Creates a new Mvi instance for a user.
  #
  # @param user [User] the user to query MVI for
  # @return [Mvi] an instance of this class
  def self.for_user(user)
    mvi = Mvi.new
    mvi.user = user
    mvi
  end

  # A DOD EDIPI (Electronic Data Interchange Personal Identifier) MVI correlation ID
  # or nil for users < LOA 3
  #
  # @return [String] the edipi correlation id
  delegate :edipi, to: :profile, allow_nil: true

  # A ICN (Integration Control Number - generated by the Master Patient Index) MVI correlation ID
  # or nil for users < LOA 3
  #
  # @return [String] the icn correlation id
  delegate :icn, to: :profile, allow_nil: true

  # A ICN (Integration Control Number - generated by the Master Patient Index) MVI correlation ID
  # combined with its Assigning Authority ID.  Or nil for users < LOA 3.
  #
  # @return [String] the icn correlation id with its assigning authority id.
  #   For example:  '12345678901234567^NI^200M^USVHA^P'
  #
  delegate :icn_with_aaid, to: :profile, allow_nil: true

  # A MHV (My HealtheVet) MVI correlation id
  # or nil for users < LOA 3
  #
  # @return [String] the mhv correlation id
  delegate :mhv_correlation_id, to: :profile, allow_nil: true

  # A VBA (Veterans Benefits Administration) or participant MVI correlation id.
  #
  # @return [String] the participant id
  delegate :participant_id, to: :profile, allow_nil: true

  # A BIRLS (Beneficiary Identification and Records Locator System) MVI correlation id.
  #
  # @return [String] the birls id
  delegate :birls_id, to: :profile, allow_nil: true

  # A Vet360 Correlation ID
  #
  # @return [String] the Vet360 id
  delegate :vet360_id, to: :profile, allow_nil: true

  # A list of ICN's that the user has been identitfied by historically
  #
  # @return [Array[String]] the list of historical icns
  delegate :historical_icns, to: :profile, allow_nil: true

  # The search token given in the original MVI 1306 response message
  #
  # @return [String] the search token
  delegate :search_token, to: :profile, allow_nil: true

  # The profile returned from the MVI service. Either returned from cached response in Redis or the MVI service.
  #
  # @return [MVI::Models::MviProfile] patient 'golden record' data from MVI
  def profile
    return nil unless user.loa3?

    mvi_response&.profile
  end

  # The status of the last MVI response or not authorized for for users < LOA 3
  #
  # @return [String] the status of the last MVI response
  def status
    return MVI::Responses::FindProfileResponse::RESPONSE_STATUS[:not_authorized] unless user.loa3?

    mvi_response.status
  end

  # The error experienced when reaching out to the MVI service.
  #
  # @return [Common::Exceptions::BackendServiceException]
  def error
    return Common::Exceptions::Unauthorized.new(source: self.class) unless user.loa3?

    mvi_response.try(:error)
  end

  # @return [MVI::Responses::FindProfileResponse] the response returned from MVI
  def mvi_response
    @mvi_response ||= response_from_redis_or_service
  end

  # The status of the MVI Add Person call. An Orchestrated MVI Search needs to be made before an MVI add person
  # call is made. The response is recached afterwards so the new ids can be accessed on the next call.
  #
  # @return [MVI::Responses::AddPersonResponse] the response returned from MVI Add Person call
  def mvi_add_person
    search_response = MVI::OrchSearchService.new.find_profile(user)
    if search_response.ok?
      @mvi_response = search_response
      add_response = mvi_service.add_person(user)
      add_ids(add_response) if add_response.ok?
    else
      add_response = MVI::Responses::AddPersonResponse.with_failed_orch_search(
        search_response.status, search_response.error
      )
    end
    add_response
  end

  private

  def add_ids(response)
    # set new ids in the profile and recache the response
    profile.birls_id = response.mvi_codes[:birls_id].presence
    profile.participant_id = response.mvi_codes[:participant_id].presence

    cache(user.uuid, mvi_response) if mvi_response.cache?
  end

  def response_from_redis_or_service
    do_cached_with(key: user.uuid) do
      mvi_service.find_profile(user)
    end
  end

  def mvi_service
    @service ||= MVI::Service.new
  end

  def save
    saved = super
    expire(record_ttl) if saved
    saved
  end

  def record_ttl
    if status == MVI::Responses::FindProfileResponse::RESPONSE_STATUS[:ok]
      # ensure default ttl is used for 'ok' responses
      REDIS_CONFIG[REDIS_CONFIG_KEY][:each_ttl]
    else
      # assign separate ttl to redis cache for failure responses
      REDIS_CONFIG[REDIS_CONFIG_KEY][:failure_ttl]
    end
  end
end
