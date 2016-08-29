require_relative "test_helper"
require "shrine/storage/linter"

describe Shrine::Storage::GoogleCloudStorage do
  def gcs(options = {})
    options[:bucket] ||= ENV.fetch("GCS_BUCKET")

    Shrine::Storage::GoogleCloudStorage.new(options)
  end

  before do
    @gcs = gcs
  end

  after do
    @gcs.clear!
  end

  it "passes the linter" do
    Shrine::Storage::Linter.new(gcs).call(-> { image })
  end

  it "passes the linter with prefix" do
    Shrine::Storage::Linter.new(gcs(prefix: 'pre')).call(-> { image })
  end

  describe "clear!" do
    it "does not empty the whole bucket when a prefix is set" do
      gcs_with_prefix = gcs(prefix: 'pre')
      @gcs.upload(image, 'foo')
      @gcs.upload(image, 'pre') # to ensure a file with the prefix name is not deleted
      gcs_with_prefix.clear!
      assert @gcs.exists?('foo')
      assert @gcs.exists?('pre')
    end
  end
end
