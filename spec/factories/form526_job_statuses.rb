# frozen_string_literal: true

FactoryBot.define do
  factory :form526_job_status do
    form526_submission_id { 123 }
    job_id { SecureRandom.hex(12) }
    job_class { 'SubmitForm526IncreaseOnly' }
    status { 'success' }
    error_class { nil }
    error_message { nil }
  end

  trait :retryable_error do
    status { 'retryable_error' }
    error_class { 'Common::Exceptions::GatewayTimeout' }
    error_message { 'Did not receive a timely response from an upstream server' }
  end

  trait :non_retryable_error do
    status { 'non_retryable_error' }
    error_class { 'NoMethodError' }
    error_message { 'undefined method foo for nil class' }
  end

  trait :evss_error do
    status { 'non_retryable_error' }
    error_class { 'NoMethodError' }
    error_message {
      '[{"key"=>"form526.serviceInformation.servicePeriods[0].ActiveDutyEndDateMoreThan180Days" ' \
      '"severity"=>"ERROR" "text"=>"Service members cannot submit a claim until they are within 180 days' \
      ' of their separation date"}{"key"=>"form526.submit.establishClaim.serviceError" "severity"=>"FATAL" ' \
      '"text"=>"Claim not established. System error with BGS. GUID: febe7a46-0fec-414a-bfe5"}]'
    }
  end
end
