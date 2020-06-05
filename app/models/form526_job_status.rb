# frozen_string_literal: true

require 'upsert/active_record_upsert'

class Form526JobStatus < ApplicationRecord
  belongs_to :form526_submission

  alias_attribute :submission, :form526_submission

  STATUS = {
    try: 'try',
    success: 'success',
    retryable_error: 'retryable_error',
    non_retryable_error: 'non_retryable_error',
    exhausted: 'exhausted'
  }.freeze

  # This regex will parse out the errors returned from EVSS.
  # The error message will be in an ugly stringified hash. There can be multiple
  # errors in a message. Each error will have a `key` and a `text` key. The
  # following regex will group all key/text pairs together that are present in
  # the string.
  EVSS_MESSAGES_REGEX = /key\"=>\"(.*?)\".*?text\"=>\"(.*?)\"/.freeze

  def success?
    status == STATUS[:success]
  end

  def error_messages_for_reporting
    # Check if its an EVSS error and parse, otherwise store the entire message
    if error_message.include?('=>') &&
       error_class != 'Common::Exceptions::BackendServiceException'
      messages = error_message.scan(EVSS_MESSAGES_REGEX)
      messages.collect do |message|
        # strip the GUID from BGS errors
        # as well as the count for things like 'form526.treatments[0]'
        "#{message[0].gsub(/\[\d*\]/, '')}: #{message[1].gsub(/GUID.*/, '')}"
      end
    else
      [error_message]
    end
  end
end
