# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Form526JobStatus do
  describe '.upsert' do
    let(:form526_submission) { create(:form526_submission) }
    let(:failed_form526_submission) { create(:form526_submission, :with_notretryable_error) }
    let(:jid) { SecureRandom.uuid }
    let(:values) do
      {
        form526_submission_id: form526_submission.id,
        job_id: jid,
        job_class: EVSS::DisabilityCompensationForm::SubmitForm526.class.name.demodulize,
        status: Form526JobStatus::STATUS[:success],
        updated_at: Time.now.utc
      }
    end

    it 'creates a record' do
      expect do
        Form526JobStatus.upsert({ job_id: jid }, values)
      end.to change(Form526JobStatus, :count).by(1)
    end
  end

  describe '.error_messages_for_reporting' do
    let(:form526_submission_with_error) { create(:form526_submission, :with_evss_error) }

    it 'strips guids and array count' do
      expect(form526_submission_with_error.form526_job_statuses.first.error_messages_for_reporting).to eq(
        [
          'form526.serviceInformation.servicePeriods.ActiveDutyEndDateMoreThan180Days: Service members cannot submit a'\
          ' claim until they are within 180 days of their separation date',
          'form526.submit.establishClaim.serviceError: Claim not established. System error with BGS. '
        ]
      )
    end
  end
end
