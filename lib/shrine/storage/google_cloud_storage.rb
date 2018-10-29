require "shrine"
require "google/cloud/storage"
require "down/chunked_io"

class Shrine
  module Storage
    class GoogleCloudStorage
      attr_reader :bucket, :prefix, :host

      # Initialize a Shrine::Storage for GCS allowing for auto-discovery of the Google::Cloud::Storage client.
      # @param [String] project Provide if not using auto discovery
      # @see http://googlecloudplatform.github.io/google-cloud-ruby/#/docs/google-cloud-storage/v1.6.0/guides/authentication#environmentvariables for information on discovery
      def initialize(project: nil, bucket:, prefix: nil, host: nil, default_acl: nil, object_options: {})
        @project = project
        @bucket = bucket
        @prefix = prefix
        @host = host
        @default_acl = default_acl
        @object_options = object_options
        @storage = nil
      end

      # If the file is an UploadFile from GCS, issues a copy command, otherwise it uploads a file.
      # @param [IO] io - io like object
      # @param [String] id - location
      def upload(io, id, shrine_metadata: {}, **options)
        if copyable?(io)
          existing_file = get_bucket(io.storage.bucket).file(io.storage.object_name(io.id))
          file = existing_file.copy(
              @bucket, # dest_bucket_or_path - the bucket to copy the file to
              object_name(id), # dest_path - the path to copy the file to in the given bucket
              acl: @default_acl
          ) do |f|
            # update the additional options
            @object_options.merge(options).each_pair do |key, value|
              f.send("#{key}=", value)
            end
          end
          file
        else
          with_file(io) do |file|
              get_bucket.create_file(
                  file,
                  object_name(id), # path
                  @object_options.merge(
                      content_type: shrine_metadata["mime_type"],
                      acl: @default_acl
                  ).merge(options)
              )
          end
        end
      end

      # URL to the remote file, accepts options for customizing the URL
      def url(id, **options)
        if options.key? :expires
          signed_url = storage.signed_url(@bucket, object_name(id), options)
          signed_url.gsub!(/storage.googleapis.com\/#{@bucket}/, @host) if @host
          signed_url
        else
          host = @host || "storage.googleapis.com/#{@bucket}"
          "https://#{host}/#{object_name(id)}"
        end
      end

      # Downloads the file from GCS, and returns a `Tempfile`.
      def download(id)
        tempfile = Tempfile.new(["googlestorage", File.extname(id)], binmode: true)
        get_file(id).download tempfile.path
        tempfile.tap(&:open)
      end

      # Opens the remote file and returns it as `Down::ChunkedIO` object.
      # @return [Down::ChunkedIO] object
      # @see https://github.com/janko-m/down#downchunkedio
      def open(id)
        file = get_file(id)

        # create enumerator which lazily yields chunks of downloaded content
        chunks = Enumerator.new do |yielder|
          # trick to get google client to stream the download
          proc_io = ProcIO.new { |data| yielder << data }
          file.download(proc_io, verify: :none)
        end

        # wrap chunks in an IO-like object which downloads when needed
        Down::ChunkedIO.new(
          chunks: chunks,
          size:   file.size,
          data:   { file: file }
        )
      end

      # checks if the file exists on the storage
      def exists?(id)
        file = get_file(id)
        return false if file.nil?
        file.exists?
      end

      # deletes the file from the storage
      def delete(id)
        file = get_file(id)
        file.delete unless file.nil?
      end

      # Otherwise deletes all objects from the storage.
      def clear!
        prefix = "#{@prefix}/" if @prefix
        files = get_bucket.files prefix: prefix
        loop do
          batch_delete(files.lazy.map(&:name))
          files = files.next or break
        end
      end

      # returns request data (:method, :url, and :headers) for direct uploads
      def presign(id, **options)
        url = storage.signed_url(@bucket, object_name(id), method: "PUT", **options)

        headers = {}
        headers["Content-Type"] = options[:content_type] if options[:content_type]
        headers["Content-MD5"]  = options[:content_md5] if options[:content_md5]
        headers.merge!(options[:headers]) if options[:headers]

        { method: :put, url: url, headers: headers }
      end

      def object_name(id)
        @prefix ? "#{@prefix}/#{id}" : id
      end

      private

      def get_file(id)
        get_bucket.file(object_name(id))
      end

      def get_bucket(bucket_name = @bucket)
        storage.bucket(bucket_name, skip_lookup: true)
      end

      # @see http://googlecloudplatform.github.io/google-cloud-ruby/#/docs/google-cloud-storage/v1.6.0/guides/authentication
      def storage
        @storage ||= if @project.nil?
                       Google::Cloud::Storage.new
                     else
                       Google::Cloud::Storage.new(project: @project)
                     end
      end

      def copyable?(io)
        io.is_a?(UploadedFile) &&
          io.storage.is_a?(Storage::GoogleCloudStorage)
        # TODO: add a check for the credentials
      end

      def with_file(io)
        if io.respond_to?(:tempfile) # ActionDispatch::Http::UploadedFile
          yield tempfile
        else
          Shrine.with_file(io) { |file| yield file }
        end
      end

      def batch_delete(object_names)
        bucket = get_bucket
        object_names.each do |name|
          bucket.file(name).delete
        end
      end

      # This class provides a writable IO wrapper around a proc object, with
      # #write simply calling the proc, which we can pass in as the destination
      # IO for download.
      class ProcIO
        def initialize(&proc)
          @proc = proc
        end

        def write(data)
          @proc.call(data)
          data.bytesize # match return value of other IO objects
        end

        # TODO: Remove this once google/google-api-ruby-client#638 is merged.
        def flush
          # google-api-client calls this method
        end
      end
    end
  end
end
