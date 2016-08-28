# Shrine::Storage::GCS

Provides [Google Cloud Storage] storage for [Shrine].

Cloudinary provides storage and advanced processing for images and videos, both
on-demand and on upload, automatic and intelligent responsive breakpoints, and
an HTML widget for direct uploads.

## Installation

```ruby
gem "shrine-gcs"
```

## Authentication

The GCS plugin uses Google's [Application Default Credentials]. Please check Google's
documentation for the various ways to provide credentials.

## Usage

```rb
require "shrine/storage/gcs"

Shrine.storages = {
  cache: Shrine::Storage::GCS.new(bucket: "cache"), # for direct uploads
  store: Shrine::Storage::GCS.new(bucket: "store"),
}
```

## Contributing

Firstly you need to create an `.env` file with a dedicaced GCS bucket:

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

[GCS]: https://cloud.google.com/storage/
[Shrine]: https://github.com/janko-m/shrine
[Application Default Credentials]: https://developers.google.com/identity/protocols/application-default-credentials
