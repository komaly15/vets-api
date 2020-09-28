# frozen_string_literal: true

require 'common/client/base'
require_relative 'configuration'
require_relative 'responses/get_debts_response'
require_relative 'responses/financial_status_report_response'

module DMC
  class Service < Common::Client::Base
    attr_reader :file_number

    include Common::Client::Concerns::Monitoring

    configuration DMC::Configuration

    STATSD_KEY_PREFIX = 'api.dmc'

    def initialize(user)
      @user = user
      @file_number = init_file_number
      @debts = init_debts
    end

    def get_debts
      {
        has_dependent_debts: veteran_has_dependent_debts?,
        debts: debts_with_sorted_histories
      }
    end

    def veteran_has_dependent_debts?
      @debts.any? { |debt| debt['payeeNumber'] != '00' }
    end

    def submit_financial_status_report(form)
      FinancialStatusReportResponse(
        perform(:post, 'fsr', form, fileNumber: @file_number).body
      )
    end

    private

    def init_file_number
      bgs_file_number = BGS::PeopleService.new(@user).find_person_by_participant_id[:file_nbr]
      bgs_file_number.presence || @user.ssn
    end

    def debts_with_sorted_histories
      @debts.select do |debt|
        debt['debtHistory'] = sort_by_date(debt['debtHistory'])
        debt['payeeNumber'] == '00'
      end
    end

    def init_debts
      with_monitoring_and_error_handling do
        GetDebtsResponse.new(perform(:post, 'letterdetails/get', fileNumber: @file_number).body).debts
      end
    end

    def sort_by_date(debt_history)
      debt_history.sort_by { |d| Date.strptime(d['date'], '%m/%d/%Y') }.reverse
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

    def handle_error(error)
      case error
      when Common::Client::Errors::ClientError
        handle_client_error(error)
      else
        raise error
      end
    end

    def handle_client_error(error)
      save_error_details(error)

      raise_backend_exception(
        "DMC#{error&.status}",
        self.class,
        error
      )
    end
  end
end
