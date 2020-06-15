# frozen_string_literal: true

require 'rails_helper'
require 'common/exceptions'

describe EVSSRedis::ReferenceData do
  subject { EVSSRedis::ReferenceData.new(user) }

  let(:user) { build(:user, :loa3) }

  context 'cached attributes' do
    describe '#get_separation_locations' do
      context 'when the cache is empty' do
        it 'caches and return the response', :aggregate_failures do
          VCR.use_cassette('evss/reference_data/intakesites') do
            expect(subject.redis_namespace).to receive(:set).once
            response = subject.get_separation_locations
            expect(response.separation_locations).to be_a(Array)
          end
        end
      end

      context 'when there is cached data' do
        let(:faraday_response) { instance_double('Faraday::Response') }

        it 'returns the cached data', :aggregate_failures do
          allow(faraday_response).to receive(:body).and_return({ intake_sites: [] })
          subject.cache(
            'evss_reference_data_get_separation_locations',
            EVSS::ReferenceData::IntakeSitesResponse.new(200, faraday_response)
          )

          expect_any_instance_of(EVSS::ReferenceData::Service).not_to receive('get_separation_locations')
          expect(subject.get_separation_locations).to be_a(response_type)
        end
      end
    end
  end
end
