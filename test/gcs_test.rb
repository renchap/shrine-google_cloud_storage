require_relative "test_helper"
require 'securerandom'
require "shrine/storage/linter"
require "date"
require "http"

describe Shrine::Storage::GoogleCloudStorage do
  def gcs(options = {})
    options[:bucket] ||= ENV.fetch("GCS_BUCKET")

    Shrine::Storage::GoogleCloudStorage.new(**options)
  end

  def generate_test_filename
    SecureRandom.hex
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
    @shrine = Class.new(Shrine)
    @shrine.storages = { gcs: @gcs }
    @uploader = @shrine.new(:gcs)
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

  describe "default_acl" do
    it "does set default acl when uploading a new object" do
      filename = generate_test_filename

      gcs = gcs(default_acl: 'publicRead')
      gcs.upload(image, filename)

      response = HTTP.head(gcs.url(filename))
      assert_equal 200, response.code

      assert @gcs.exists?(filename)
    end

    it "does set default acl when copying an object" do
      filename1 = generate_test_filename
      filename2 = generate_test_filename

      gcs = gcs(default_acl: 'publicRead')
      object = @uploader.upload(image, location: filename1)

      gcs.upload(object, filename2)

      # filename1 needs to not be readable
      response = HTTP.head(gcs.url(filename1))
      assert_equal 403, response.code

      # filename2 needs to be readable
      response = HTTP.head(gcs.url(filename2))
      assert_equal 200, response.code

      assert @gcs.exists?(filename1)
    end

    it "allows for the acl to be set on an object level" do
      filename = generate_test_filename

      gcs = gcs(default_acl: 'private')
      gcs.upload(image, filename, acl: 'publicRead')

      response = HTTP.head(gcs.url(filename))
      assert_equal 200, response.code

      assert @gcs.exists?(filename)
    end
  end

  describe "object_options" do
    it "does set the Cache-Control header when uploading a new object" do
      filename = generate_test_filename

      cache_control = 'public, max-age=7200'
      gcs = gcs(default_acl: 'publicRead', object_options: { cache_control: cache_control })
      gcs.upload(image, filename, content_type: 'image/jpeg')

      assert @gcs.exists?(filename)

      response = HTTP.head(gcs.url(filename))
      assert_equal 200, response.code
      assert_equal cache_control, response.headers["Cache-Control"]
      assert_equal "image/jpeg", response.headers["Content-Type"]
    end

    it "does set the configured Cache-Control header when copying an object" do
      filename1 = generate_test_filename
      filename2 = generate_test_filename

      cache_control = 'public, max-age=7200'
      gcs = gcs(default_acl: 'publicRead', object_options: { cache_control: cache_control })
      object = @uploader.upload(image, location: filename1)

      gcs.upload(object, filename2)

      # filename2 needs to have the correct Cache-Control header
      response = HTTP.head(gcs.url(filename2))
      assert_equal 200, response.code
      assert_equal cache_control, response.headers["Cache-Control"]
    end
  end

  describe "#clear!" do
    it "does not empty the whole bucket when a prefix is set" do
      filename = generate_test_filename
      prefix = generate_test_filename

      gcs_with_prefix = gcs(prefix: prefix)
      @gcs.upload(image, filename)
      @gcs.upload(image, prefix) # to ensure a file with the prefix name is not deleted
      gcs_with_prefix.clear!
      assert @gcs.exists?(filename)
      assert @gcs.exists?(prefix)
    end

    it "removes only files for which block returns true" do
      filename1 = generate_test_filename
      filename2 = generate_test_filename
      @gcs.upload(image, filename1)
      @gcs.upload(image, filename2)

      @gcs.clear! { |file| file.name == filename1 }

      assert !@gcs.exists?(filename1)
      assert @gcs.exists?(filename2)
    end
  end

  describe "#presign" do
    it "signs a PUT url with a signing key and issuer" do
      filename = generate_test_filename

      gcs = gcs()
      gcs.upload(image, filename)

      sa = service_account
      Time.stub :now, Time.at(1486649900) do
        presign = gcs.presign(
          filename,
          signing_key: sa[:private_key],
          issuer: sa[:client_email],
        )

        assert_equal :put, presign[:method]
        assert presign[:url].start_with? "https://storage.googleapis.com/#{gcs.bucket}/#{filename}?"
        assert presign[:url].include? "Expires=1486650200"
        assert presign[:url].include? "GoogleAccessId=test-shrine%40test.google"
        assert presign[:url].include? "Signature=" # each tester's discovered signature will be different
        assert_equal({}, presign[:headers])
      end
    end

    it "generated a signed url for a non-existing object" do
      gcs = gcs()

      Time.stub :now, Time.at(1486649900) do
        presign = gcs.presign('nonexisting')
        assert_equal :put, presign[:method]
        assert presign[:url].include? "https://storage.googleapis.com/#{gcs.bucket}/nonexisting?"
        assert presign[:url].include? "Expires=1486650200"
        assert presign[:url].include? "Signature=" # each tester's discovered signature will be different
        assert_equal({}, presign[:headers])
      end
    end

    it "signs a PUT url with discovered credentials" do
      filename = generate_test_filename

      gcs = gcs()
      gcs.upload(image, filename)

      Time.stub :now, Time.at(1486649900) do
        presign = gcs.presign(filename)
        assert_equal :put, presign[:method]
        assert presign[:url].include? "https://storage.googleapis.com/#{gcs.bucket}/#{filename}?"
        assert presign[:url].include? "Expires=1486650200"
        assert presign[:url].include? "Signature=" # each tester's discovered signature will be different
        assert_equal({}, presign[:headers])
      end
    end

    it "adds headers for header parameters" do
      filename = generate_test_filename

      gcs = gcs()

      content = "text"
      md5     = Digest::MD5.base64digest(content)

      presign = gcs.presign(filename,
        content_type: 'text/plain',
        content_md5: md5,
        headers: {
          'x-goog-acl' => 'private',
          'x-goog-meta-foo' => 'bar,baz'
        },
      )

      expected_headers = {
        'Content-Type'    => 'text/plain',
        'Content-MD5'     => md5,
        'x-goog-acl'      => 'private',
        'x-goog-meta-foo' => 'bar,baz',
      }

      assert_equal expected_headers, presign[:headers]

      # upload succeeds
      response = HTTP.headers(presign[:headers]).put(presign[:url], body: content)
      assert_equal 200, response.code

      assert_equal content, HTTP.get(gcs.url(filename, expires: 60)).to_s
    end
  end

  describe "#url" do
    describe "signed" do
      it "url with `expires` signs a GET url with discovered credentials" do
        filename = generate_test_filename

        gcs = gcs()
        gcs.upload(image, filename)

        Time.stub :now, Time.at(1486649900) do
          presigned_url = gcs.url(filename, expires: 300)
          assert presigned_url.include? "https://storage.googleapis.com/#{gcs.bucket}/#{filename}?"
          assert presigned_url.include? "Expires=1486650200"
          assert presigned_url.include? "Signature=" # each tester's discovered signature will be different
        end
      end

      it "url with `expires` signs a GET url with discovered credentials and specified host" do
        filename = generate_test_filename
        host = "123.mycdn.net"
        gcs = gcs(host: host)
        gcs.upload(image, filename)

        Time.stub :now, Time.at(1486649900) do
          presigned_url = gcs.url(filename, expires: 300)
          assert presigned_url.include? "https://#{host}/#{filename}?"
          assert presigned_url.include? "Expires=1486650200"
          assert presigned_url.include? "Signature=" # each tester's discovered signature will be different
        end
      end
    end

    it "provides a storage.googleapis.com url by default" do
      filename = generate_test_filename

      gcs = gcs()
      url = gcs.url(filename)
      assert_equal("https://storage.googleapis.com/#{gcs.bucket}/#{filename}", url)
    end

    it "accepts :host for specifying CDN links" do
      filename = generate_test_filename

      host = "123.mycdn.net"
      gcs = gcs(host: host)
      url = gcs.url(filename)
      assert_equal("https://123.mycdn.net/#{filename}", url)
    end
  end

  describe '#upload' do
    it 'uploads a io stream to google cloud storage' do
      io = StringIO.new("data")

      file_key = random_key

      @gcs.upload(io, file_key)

      assert @gcs.exists?(file_key)
    end

    it 'uploads Rails file objects' do
      io = StringIO.new("data")
      file = RailsFile.new(io)

      file_key = random_key

      @gcs.upload(file, file_key)

      assert @gcs.exists?(file_key)
    end

    it 'copies an existing uploaded file' do
      cache_control = 'public, max-age=7200'

      gcs = gcs(default_acl: 'publicRead', object_options: { cache_control: cache_control })
      gcs.upload(image, 'test.jpg', content_type: 'image/jpeg', cache_control: cache_control)

      uploaded_file = @shrine.uploaded_file(id: 'test.jpg', storage: 'gcs')
      gcs.upload(uploaded_file, 'test1.jpg')

      assert gcs.exists?('test1.jpg')

      response = HTTP.head(gcs.url('test1.jpg'))
      assert_equal 200, response.code

      # Let's ensure it correctly copies the metadata as well
      assert_equal cache_control, response.headers["Cache-Control"]
      assert_equal "image/jpeg", response.headers["Content-Type"]
    end
  end

  describe "#open" do
    it "returns an IO-like object around the file content" do
      filename = generate_test_filename

      gcs.upload(fakeio(filename), filename)
      io = gcs.open(filename)
      assert_equal(32,       io.size)
      assert_equal(filename, io.read)
      assert_instance_of(Google::Cloud::Storage::File, io.data[:file])
    end

    it "accepts :rewindable" do
      gcs.upload(fakeio, 'foo')
      io = gcs.open('foo', rewindable: false)
      assert_raises(IOError) { io.rewind }
    end

    it "accepts additional download options" do
      gcs.upload(fakeio('file'), 'foo')
      io = gcs.open('foo', range: 1..2)
      assert_equal('il', io.read)
    end

    it "raises a Shrine::FileNotFound exception when a file does not exists" do
      assert_raises(Shrine::FileNotFound) { gcs.open('foo')}
    end
  end
end
