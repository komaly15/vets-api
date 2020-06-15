# frozen_string_literal: true

require 'common/models/redis_store'
require 'common/models/concerns/cache_aside'
# Vet360Redis::ReferenceData.new(@current_user)
module EVSSRedis
  # Facade for EVSS::ReferenceData::Service.
  #
  # When reference data is requested from the serializer, it returns either
  # a cached response from Redis or from the EVSS::ReferenceData::Service.
  class ReferenceData < Common::RedisStore
    include Common::CacheAside

    def initialize(user)
      @user = user
    end

    # Redis settings for ttl and namespacing reside in config/redis.yml
    redis_config_key :evss_reference_data_response

    # List of valid EVSS countries
    # @return [EVSS::ReferenceData::CountriesResponse]
    def get_countries
      response_from_redis_or_service(:get_countries)
    end

    # List of valid EVSS states
    # @return [EVSS::ReferenceData::StatesResponse]
    def get_states
      response_from_redis_or_service(:get_states)
    end

    # List of valid EVSS intakesites
    # @return [EVSS::ReferenceData::IntakeSitesResponse]
    def get_separation_locations
      response_from_redis_or_service(:get_separation_locations)
    end

    private

    def response_from_redis_or_service(endpoint)
      # Note: making a call to EVSS requires a header with user data, but the refernece data is not perosnalized so
      # we're caching it once for everybody.
      do_cached_with(key: "evss_reference_data_#{endpoint}") do
        reference_data_service.public_send(endpoint)
      end
    end

    def reference_data_service
      @service ||= EVSS::ReferenceData::Service.new(@user)
    end
  end
end
