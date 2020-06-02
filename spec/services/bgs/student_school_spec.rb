# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BGS::StudentSchool do
  let(:user) { FactoryBot.create(:user, :loa3) }
  let(:proc_id) { '3828879' }
  let(:vnp_participant_id) { '148166' }
  let(:payload) do
    root = Rails.root.to_s
    f = File.read("#{root}/spec/services/bgs/support/final_payload.json")
    JSON.parse(f)
  end
  let(:child_response) do
    {
      :vnp_child_school_id => "22020",
      :course_name_txt => "An amazing program",
      :curnt_hours_per_wk_num => "37",
      :curnt_school_addrs_one_txt => "2037 29th St",
      :curnt_school_addrs_three_txt => "Yet another line",
      :curnt_school_addrs_two_txt => "another line",
      :curnt_school_addrs_zip_nbr => "61201",
      :curnt_school_nm => "My Great School",
      :curnt_school_postal_cd=>nil
    }
  end
  let(:school_response) do
    {
      :agency_paying_tuitn_nm => "Some Agency",
      :govt_paid_tuitn_ind => "Y",
      :next_year_annty_income_amt => "3989",
      :next_year_emplmt_income_amt => "12000",
      :next_year_other_income_amt => "984",
      :next_year_ssa_income_amt => "3940",
      :other_asset_amt => "4566",
      :real_estate_amt => "5623",
      :rmks => "Some remarks about the student's net worth",
      :saving_amt => "3455",
      :stock_bond_amt => "3234",
      :term_year_annty_income_amt => "30595",
      :term_year_emplmt_income_amt => "12000",
      :term_year_other_income_amt => "5596",
      :term_year_ssa_income_amt => "3453"
    }
  end
  describe '#create' do
    it 'creates a child school and a child student' do
      VCR.use_cassette('bgs/student_school/create') do
        student_school = BGS::StudentSchool.new(
          proc_id: proc_id,
          vnp_participant_id: vnp_participant_id,
          payload: payload,
          user: user
        ).create

        expect(student_school).to match(
          [
            a_hash_including(child_response),
            a_hash_including(school_response),
          ]
        )
      end
    end
  end
end