require_relative "test_helper"
require "shrine/storage/linter"
require "date"

describe Shrine::Storage::GoogleCloudStorage do
  def gcs(options = {})
    options[:bucket] ||= ENV.fetch("GCS_BUCKET")

    Shrine::Storage::GoogleCloudStorage.new(options)
  end

  def service_account
    {
      private_key: "-----BEGIN PRIVATE KEY-----
MIICdwIBADANBgkqhkiG9w0BAQEFAASCAmEwggJdAgEAAoGBANW9uQf69ivd+txc
v5iMYkTVkGcQIereNz/lYeuZv2s7OZ4I9pdebleUmpxPn/CopRxS3O7JrXBPzAMK
i0tFs/dnn5Ny6AIzZvo1eMSptoKmcHswoYTP9ftTG7cDa8/12woEFu+fX9ob4isF
IaKvbD8kEhcyynWPUH3pP1g0ssUPAgMBAAECgYAtQhgM5Yn8resxf/4d2hPwyVvj
Rto3tkfyoqqCTbLnjMndeb5lPNyWdOPsFzwhpEQZ5D3d3hx4fJ0RQ8lM7fx2EiwD
+gjiOzLu9Fy+9XiVPbqIR20R63sHlA2jmzTuno9TLRdi+YyBS3XUVjckSE9mqTNO
RDmDgRbwQURjsgFH2QJBAP9oNQrNQI2Q+b7ufA8pnf2ZWBX0ASFz99Y1WVR+ip7o
3pByI7EMK3g9h3Ua3yEU+g5WVb/1Zaj6Bx7p4lRL540CQQDWPMC2yXO9wnsw1Nyy
1gtD18hcPBwDbIoQIK+J/AOLtSryKrCAEvOnLsxU1krYAj6ZP5MwrruLmnTLUXCE
+ZoLAkEA2kJuGZX/VTsQAbcBc1+oMOCLIu+Ky9CzeW3LseYVhekQ0TWJBLKWr0E9
cbiN91JawkfLLaiCwJ0x2pwaGtlmvQJAK8PFapHEvyMXn2Ycn7vyGS3flFgDMP/f
RGQo9/svjj64QzhNThyRAbohq8MLDw2GVDAUlYFcdqxa553/amrC+QJBAOYsfZTF
0ICBD2rt+ukhgSmZq/4oWxlM505kDh4z+x2oT3nFSi+fce5IWuNswR2qTRhjIAj8
wXh0ExlzwgD2xJ0=
-----END PRIVATE KEY-----",
      client_email: 'test-shrine@test.google',
    }
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

  describe "presign" do
    it "works on a GET url" do
      sa = service_account

      storage = Shrine::Storage::GoogleCloudStorage.new(bucket: "shrine-test")

      Time.stub :now, Time.at(1486649900) do
        presign = storage.presign(
          'test_presign.txt',
          method: "GET",
          expires: 60 * 5,
          signing_key: sa[:private_key],
          issuer: sa[:client_email],
        )

        assert_equal "https://storage.googleapis.com/shrine-test/test_presign.txt?GoogleAccessId=test-shrine@test.google&Expires=1486650200&Signature=O8tYOAJCtk0fXpO9MDhRO7ikVsIRqjALK01naly2rEJBCM2uRHl7meqEaXzu%2Bl9V17zw9P2%2FGb0K2miF%2FyEuZ6mnRIiuH6aI2tg24CV%2FKtuNU5jSqwqMU83iPzuptwakgFNxMGJj73i0SGbB%2F4wodNR7DNQ6KFhSlpJJ1mgD4hI%3D", presign.url
        assert_equal({}, presign.fields)
      end
    end
  end
end
