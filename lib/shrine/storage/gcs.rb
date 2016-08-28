require "shrine"
require "googleauth"
require "google/apis/storage_v1"

class Shrine
  module Storage
    class GCS
      def initialize(bucket:)
        @bucket_name = bucket
      end

      def upload(io, id, shrine_metadata: {}, **options)
        # uploads `io` to the location `id`
        storage_api.insert_object(@bucket_name, { name: id }, content_type: shrine_metadata["mime_type"], upload_source: io,
                                                options: { uploadType: 'multipart' })
      end

      def url(id, **options)
        # URL to the remote file, accepts options for customizing the URL
        "https://#{@bucket_name}.storage.googleapis.com/#{id}"
      end

      def download(id)
        tempfile = Tempfile.new(["googlestorage", File.extname(id)], binmode: true)
        storage_api.get_object(@bucket_name, id, download_dest: tempfile)
        tempfile.tap(&:open)
      end

      def open(id)
        # returns the remote file as an IO-like object
        io = storage_api.get_object(@bucket_name, id, download_dest: StringIO.new)
        io.rewind
        io
      end

      def exists?(id)
        # checks if the file exists on the storage
        storage_api.get_object(@bucket_name, id) do |_, err|
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
        storage_api.delete_object(@bucket_name, id)
      end

      def multi_delete(ids)
        storage_api.batch do |storage|
          ids.each do |id|
            storage.delete_object(@bucket_name, id)
          end
        end
      end

      def clear!
        ids = []
        storage_api.fetch_all do |token, s|
          s.list_objects(
            @bucket_name,
            fields: "items/name",
            page_token: token,
          )
        end.each do |object|
          ids << object.name

          if ids.size >= 100
            # Batches are limited to 100, so we execute it and reset the ids
            multi_delete(ids)
            ids = []
          end
        end

        # We delete the remaining ones
        multi_delete(ids) if ids.size > 0
      end

      private

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
