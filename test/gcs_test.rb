require "test_helper"
require "shrine/storage/linter"

describe Shrine::Storage::GCS do
  def gcs(options = {})
    options[:bucket] ||= ENV.fetch("GCS_BUCKET")

    Shrine::Storage::GCS.new(options)
  end

  before do
    @gcs = gcs
  end

  after do
    #@gcs.clear!
  end

  it "passes the linter" do
    Shrine::Storage::Linter.new(@gcs).call(-> { image })
  end
  #
  # describe "#download" do
  #   it "preserves the extension" do
  #     @gridfs.upload(fakeio, id = "foo.jpg")
  #     tempfile = @gridfs.download(id)
  #
  #     assert_equal ".jpg", File.extname(tempfile.path)
  #   end
  # end
end
