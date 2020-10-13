# frozen_string_literal: true

RSpec.shared_examples 'contestable issues index requests' do |options|
  describe '#index' do
    context 'when using SSN header as veteran identifier' do
      it 'GETs contestable_issues from Caseflow successfully' do
        VCR.use_cassette("caseflow/#{options[:appeal_type]}/contestable_issues") do
          get_issues(ssn: '872958715', options: options)
          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json['data']).not_to be nil
        end
      end
    end

    context 'when using file_number header as veteran identifier' do
      it 'GETs contestable_issues from Caseflow successfully' do
        VCR.use_cassette("caseflow/#{options[:appeal_type]}/contestable_issues-by-file-number") do
          get_issues(file_number: '123456789', options: options)
          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json['data']).not_to be nil
        end
      end
    end

    context 'unusable response' do
      before do
        allow_any_instance_of(Caseflow::Service).to(
          receive(:get_contestable_issues).and_return(
            Struct.new(:status, :body).new(
              200,
              '<html>Some html!</html>'
            )
          )
        )
      end

      it 'returns a 502 when Caseflow returns an unusable response' do
        get_issues(options: options)
        expect(response).to have_http_status(:bad_gateway)
        expect(JSON.parse(response.body)['errors']).to be_an Array
      end
    end

    context 'Caseflow 4XX response' do
      let(:status) { 400 }
      let(:body) { { hello: 'world' }.as_json }

      before do
        allow_any_instance_of(Caseflow::Service).to(
          receive(:get_contestable_issues).and_return(
            Struct.new(:status, :body).new(status, body)
          )
        )
      end

      it 'lets 4XX responses passthrough' do
        get_issues(options: options)
        expect(response.status).to be status
        expect(JSON.parse(response.body)).to eq body
      end
    end
  end

  private

  def get_issues(ssn: '872958715', file_number: nil, options:)
    headers = { 'X-VA-Receipt-Date' => '2019-12-01' }

    if file_number.present?
      headers['X-VA-File-Number'] = file_number
    elsif ssn.present?
      headers['X-VA-SSN'] = ssn
    end

    get("/services/appeals/v1/decision_reviews/#{options[:appeal_type]}/contestable_issues/#{options[:benefit_type]}",
        headers: headers)
  end
end
