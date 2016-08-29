# Shrine::Storage::GCS

Provides [Google Cloud Storage] (GCS) storage for [Shrine].

## Installation

```ruby
gem "shrine-google_cloud_storage"
```

## Authentication

The GCS plugin uses Google's [Application Default Credentials]. Please check
documentation for the various ways to provide credentials.

## Usage

```rb
require "shrine/storage/gcs"

Shrine.storages = {
  cache: Shrine::Storage::GoogleCloudStorage.new(bucket: "cache"),
  store: Shrine::Storage::GoogleCloudStorage.new(bucket: "store"),
}
```

## Contributing

Firstly you need to create an `.env` file with a dedicated GCS bucket:

```sh
# .env
GCS_BUCKET="..."
```

Warning: all content of the bucket is cleared between tests, create a new one only for this usage!

Afterwards you can run the tests:

```sh
$ bundle exec rake test
```

## License

[MIT](http://opensource.org/licenses/MIT)

[Google Cloud Storage]: https://cloud.google.com/storage/
[Shrine]: https://github.com/janko-m/shrine
[Application Default Credentials]: https://developers.google.com/identity/protocols/application-default-credentials
