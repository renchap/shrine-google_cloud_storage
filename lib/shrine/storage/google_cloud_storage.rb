require "shrine"
require "googleauth"
require "google/apis/storage_v1"

class Shrine
  module Storage
    class GoogleCloudStorage
      attr_reader :bucket, :prefix, :host

      def initialize(bucket:, prefix: nil, host: nil)
        @bucket = bucket
        @prefix = prefix
        @host = host
      end

      def upload(io, id, shrine_metadata: {}, **_options)
        # uploads `io` to the location `id`

        if copyable?(io)
          storage_api.copy_object(io.storage.bucket, io.storage.object_name(io.id), @bucket, object_name(id))
        else
          storage_api.insert_object(
            @bucket,
            { name: object_name(id) },
            content_type: shrine_metadata["mime_type"],
            upload_source: io.to_io,
            options: { uploadType: 'multipart' },
          )
        end
      end

      def url(id, **_options)
        # URL to the remote file, accepts options for customizing the URL
        host = @host || "storage.googleapis.com/#{@bucket}"

        "https://#{host}/#{object_name(id)}"
      end

      def download(id)
        tempfile = Tempfile.new(["googlestorage", File.extname(id)], binmode: true)
        storage_api.get_object(@bucket, object_name(id), download_dest: tempfile)
        tempfile.tap(&:open)
      end

      def open(id)
        # returns the remote file as an IO-like object
        io = storage_api.get_object(@bucket, object_name(id), download_dest: StringIO.new)
        io.rewind
        io
      end

      def exists?(id)
        # checks if the file exists on the storage
        storage_api.get_object(@bucket, object_name(id)) do |_, err|
          if err
            if err.status_code == 404
              false
            else
              raise err
            end
          else
            true
          end
        end
      end

      def delete(id)
        # deletes the file from the storage
        storage_api.delete_object(@bucket, object_name(id))

      rescue Google::Apis::ClientError => e
        # The object does not exist, Shrine expects us to be ok
        return true if e.status_code == 404

        raise e
      end

      def multi_delete(ids)
        batch_delete(ids.map { |i| object_name(i) })
      end

      def clear!
        ids = []

        storage_api.fetch_all do |token, s|
          prefix = "#{@prefix}/" if @prefix
          s.list_objects(
            @bucket,
            prefix: prefix,
            fields: "items/name",
            page_token: token,
          )
        end.each do |object|
          ids << object.name

          if ids.size >= 100
            # Batches are limited to 100, so we execute it and reset the ids
            batch_delete(ids)
            ids = []
          end
        end

        # We delete the remaining ones
        batch_delete(ids) unless ids.empty?
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

      def copyable?(io)
        io.is_a?(UploadedFile) &&
          io.storage.is_a?(Storage::GoogleCloudStorage)
        # TODO: add a check for the credentials
      end

      def batch_delete(object_names)
        storage_api.batch do |storage|
          object_names.each do |name|
            storage.delete_object(@bucket, name)
          end
        end
      end

      def storage_api
        if !@storage_api || @storage_api.authorization.expired?
          service = Google::Apis::StorageV1::StorageService.new
          scopes = ['https://www.googleapis.com/auth/devstorage.read_write']
          authorization = Google::Auth.get_application_default(scopes)
          authorization.fetch_access_token!
          service.authorization = authorization
          @storage_api = service
        end
        @storage_api
      end
    end
  end
end
