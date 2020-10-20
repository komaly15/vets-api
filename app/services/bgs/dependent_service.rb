# frozen_string_literal: true

module BGS
  class DependentService < BaseService
    def get_dependents
      @service.claimant.find_dependents_by_participant_id(@user.participant_id, @user.ssn)
    end

    def submit_686c_form(claim)
      # rubocop:disable Rails/DynamicFindBy
      bgs_person = @service.people.find_by_ssn(@user.ssn)
      # rubocop:enable Rails/DynamicFindBy

      vet_info = VetInfo.new(@user, bgs_person)

      BGS::SubmitForm686cJob.perform_async(@user.uuid, claim.id, vet_info.to_686c_form_hash) if claim.submittable_686?
      BGS::SubmitForm674Job.perform_async(@user.uuid, claim.id, vet_info.to_686c_form_hash) if claim.submittable_674?
      VBMS::SubmitDependentsPDFJob.perform_async(claim.id, vet_info.to_686c_form_hash)
    rescue => e
      report_error(e)
    end
  end
end
