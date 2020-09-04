# frozen_string_literal: true

# rubocop:disable Metrics/MethodLength

# spec/simplecov_helper.rb
require 'active_support/inflector'
require 'simplecov'

class SimpleCovHelper
  def self.report_coverage(base_dir: './coverage_results')
    new(base_dir: base_dir).merge_results
  end

  attr_reader :base_dir

  def initialize(base_dir:)
    @base_dir = base_dir
  end

  def all_results
    Dir["#{base_dir}/.resultset*.json"]
  end

  def merge_results
    results = all_results.map { |file| SimpleCov::Result.from_hash(JSON.parse(File.read(file))) }
    SimpleCov::ResultMerger.merge_results(*results).tap do |result|
      SimpleCov::ResultMerger.store_result(result)
    end
  end
end

# rubocop:enable Metrics/MethodLength
