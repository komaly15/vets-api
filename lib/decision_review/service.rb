# frozen_string_literal: true

require 'common/client/base'
require 'common/client/concerns/monitoring'

require 'decision_review/configuration'
require 'decision_review/responses/response'
require 'decision_review/service_exception'

# Proxy Service for calling Lighthouse Decision Reviews API
module DecisionReview
  class Service < Common::Client::Base
    include SentryLogging
    include Common::Client::Concerns::Monitoring

    configuration DecisionReview::Configuration

    STATSD_KEY_PREFIX = 'api.decision_review'

    # Create a higher-level review for a veteran
    def create_higher_level_review(user:, request_body:)
      with_monitoring_and_error_handling do
        raw_response = perform(
          :post,
          'higher_level_reviews',
          request_body,
          create_higher_level_review_headers(user)
        )
        DecisionReview::Responses::Response.new(raw_response.status, raw_response.body, 'intake_status')
      end
    end

    # Retrieve a submitted higher-level review's details/status
    def show_higher_level_review(uuid)
      with_monitoring_and_error_handling do
        raw_response = perform(:get, "higher_level_reviews/#{uuid}", nil)
        DecisionReview::Responses::Response.new(raw_response.status, raw_response.body, 'review')
      end
    end

    # Get a list of issues that could be contested for the given decision review and benefit types
    def get_contestable_issues(decision_review_type:, user:, benefit_type:)
      with_monitoring_and_error_handling do
        raw_response = perform(
          :get,
          "#{decision_review_type}s/contestable_issues/#{benefit_type}",
          nil,
          {
            'X-VA-SSN' => user.ssn,
            'X-VA-Receipt-Date' => Time.current.strftime('%Y-%m-%d')
          }
        )
        DecisionReview::Responses::Response.new(raw_response.status, raw_response.body, 'contestable_issues')
      end
    end

    private

    def create_higher_level_review_headers(user)
      required = {
        'X-VA-SSN' => user.ssn,
        'X-VA-First-Name' => user.first_name,
        'X-VA-Last-Name' => user.last_name,
        'X-VA-Birth-Date' => user.birth_date
       }

      not_required = {
        'X-VA-Middle-Initial' => user.middle_name && user.middle_name.first,
        'X-VA-File-Number' => nil,
        'X-VA-Service-Number' => nil,
        'X-VA-Insurance-Policy-Number' => nil
      }.compact

      required.merge not_required
    end

    def with_monitoring_and_error_handling
      with_monitoring(2) do
        yield
      end
    rescue => e
      handle_error(e)
    end

    def save_error_details(error)
      Raven.tags_context(
        external_service: self.class.to_s.underscore
      )

      Raven.extra_context(
        url: config.base_path,
        message: error.message,
        body: error.body
      )
    end

    def raise_backend_exception(key, source, error = nil)
      raise DecisionReview::ServiceException.new(
        key,
        { source: source.to_s },
        error&.status,
        error&.body
      )
    end

    def handle_error(error)
      case error
      when Faraday::ParsingError
        Raven.extra_context(
          message: error.message,
          url: config.base_path
        )
        raise_backend_exception('DR_502', self.class)
      when Common::Client::Errors::ClientError
        save_error_details(error)
        raise Common::Exceptions::Forbidden if error.status == 403
        raise raise_backend_exception('DR_401', self.class, error) if error.status == 401

        code = error.body['errors'].first.dig('code')
        raise_backend_exception("DR_#{code}", self.class, error)
      else
        raise error
      end
    end
  end
end
