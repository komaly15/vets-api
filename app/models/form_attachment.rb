# frozen_string_literal: true

class FormAttachment < ApplicationRecord
  include SetGuid
  include SentryLogging

  attr_encrypted(:file_data, key: Settings.db_encryption_key)
  attr_encrypted(:file_password, key: Settings.db_encryption_key)

  validates(:file_data, :guid, presence: true)

  before_destroy { |record| record.get_file.delete }

  def set_file_data!(file, file_password_arg = nil)
    attachment_uploader = get_attachment_uploader
    attachment_uploader.store!(file)
    self.file_password = file_password_arg
    self.file_data = { filename: attachment_uploader.filename }.to_json
  rescue CarrierWave::IntegrityError => e
    log_exception_to_sentry(e, nil, nil, 'warn')
    raise Common::Exceptions::UnprocessableEntity.new(detail: e.message,
                                                      source: 'FormAttachment')
  end

  def parsed_file_data
    @parsed_file_data ||= JSON.parse(file_data)
  end

  def get_file
    attachment_uploader = get_attachment_uploader
    attachment_uploader.retrieve_from_store!(
      parsed_file_data['filename']
    )
    attachment_uploader.file
  end

  private

  def get_attachment_uploader
    self.class::ATTACHMENT_UPLOADER_CLASS.new(guid)
  end
end
