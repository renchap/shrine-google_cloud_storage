require "shrine"
require "google/cloud/storage"
require "google/apis/storage_v1"

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
      end

      # If the file is an UploadFile from GCS, issues a copy command, otherwise it uploads a file.
      def upload(io, id, shrine_metadata: {}, **_options)
        # uploads `io` to the location `id`

        if copyable?(io)
          existing_file = get_bucket(io.storage.bucket).file(io.storage.object_name(io.id))
          existing_file.copy(
              dest_bucket_or_path: @bucket,
              dest_path: object_name(id),
              acl: @default_acl
          )
        else
          get_bucket.create_file(
              file: io,
              path: object_name(id),
              content_type: shrine_metadata["mime_type"],
              acl: @default_acl
          )
        end
      end

      # URL to the remote file, accepts options for customizing the URL
      def url(id, **_options)
        host = @host || "storage.googleapis.com/#{@bucket}"

        "https://#{host}/#{object_name(id)}"
      end

      # Downloads the file from GCS, and returns a `Tempfile`.
      def download(id)
        tempfile = Tempfile.new(["googlestorage", File.extname(id)], binmode: true)
        storage_api.get_object(@bucket, object_name(id), download_dest: tempfile)
        get_file(id).download tempfile.path
        tempfile.tap(&:open)
      end

      # Download the remote file to an in-memory StringIO object
      # @return [StringIO] object
      def open(id)
        io = get_file(id).download
        io.rewind
        io
      end

      # checks if the file exists on the storage
      def exists?(id)
        get_file(id).exists?
      end

      # deletes the file from the storage
      def delete(id)
        get_file(id).delete
      end

      # Deletes multiple files at once from the storage.
      def multi_delete(ids)
        batch_delete(ids.map { |i| object_name(i) })
      end

      # Otherwise deletes all objects from the storage.
      def clear!
        prefix = "#{@prefix}/" if @prefix
        all_objects = get_bucket.files prefix: prefix
        batch_delete(all_objects.lazy.map(&:name))
      end

      def presign(id, **options)
        method = options[:method] || "GET"
        content_md5 = options[:content_md5] || ""
        content_type = options[:content_type] || ""
        expires = (Time.now.utc + (options[:expires] || 300)).to_i
        headers = nil
        path = "/#{@bucket}/" + object_name(id)

        to_sign = [method, content_md5, content_type, expires, headers, path].compact.join("\n")

        signing_key = options[:signing_key]
        signing_key = OpenSSL::PKey::RSA.new(signing_key) unless signing_key.respond_to?(:sign)
        signature = Base64.strict_encode64(signing_key.sign(OpenSSL::Digest::SHA256.new, to_sign)).delete("\n")

        signed_url = "https://storage.googleapis.com#{path}?GoogleAccessId=#{options[:issuer]}" \
          "&Expires=#{expires}&Signature=#{CGI.escape(signature)}"

        OpenStruct.new(
          url: signed_url,
          fields: {},
        )
      end

      def object_name(id)
        @prefix ? "#{@prefix}/#{id}" : id
      end

      private

      def get_file(id)
        get_bucket.file(object_name(id))
      end

      def get_bucket(bucket_name = @bucket)
        new_storage.bucket(bucket_name)
      end

      # @see http://googlecloudplatform.github.io/google-cloud-ruby/#/docs/google-cloud-storage/v1.6.0/guides/authentication
      def new_storage
        if @project.nil?
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

      def batch_delete(object_names)
        bucket = get_bucket
        object_names.each do |name|
          bucket.file(name).delete
        end
      end
    end
  end
end
