# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Upload supporting evidence', type: :request do
  include SchemaMatchers

  describe 'Post /v0/upload_supporting_evidence' do
    context 'with valid parameters' do
      it 'returns a 200 and an upload guid' do
        post '/v0/upload_supporting_evidence',
             params: { supporting_evidence_attachment: { file_data: fixture_file_upload('files/sm_file1.jpg') } }
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['data']['attributes']['guid']).to eq SupportingEvidenceAttachment.last.guid
      end

      it 'returns a 200 for a decrypted file' do
        post '/v0/upload_supporting_evidence',
             params: { supporting_evidence_attachment: {
               file_data: fixture_file_upload('files/locked_pdf_password_is_test.pdf'),
               password: 'test'
             } }
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['data']['attributes']['guid']).to eq SupportingEvidenceAttachment.last.guid
      end
    end

    context 'with invalid parameters' do
      it 'returns a 500 with no parameters' do
        post '/v0/upload_supporting_evidence', params: nil
        expect(response).to have_http_status(:bad_request)
      end

      it 'returns a 500 with no file_data' do
        post '/v0/upload_supporting_evidence', params: JSON.parse('{"supporting_evidence_attachment": {}}')
        expect(response).to have_http_status(:bad_request)
      end
    end
  end
end
