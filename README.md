[![Gem Version](https://badge.fury.io/rb/shrine-google_cloud_storage.svg)](https://badge.fury.io/rb/shrine-google_cloud_storage)

# Shrine::Storage::GoogleCloudStorage

Provides [Google Cloud Storage] (GCS) storage for [Shrine].

## Installation

```ruby
gem "shrine-google_cloud_storage"
```

## Authentication

The GCS plugin uses the `google-cloud-storage` gem. Please refer to [its documentation for setting up authentication](http://googleapis.github.io/google-cloud-ruby/docs/google-cloud-storage/latest/file.AUTHENTICATION.html).

## Usage

```rb
require "shrine/storage/google_cloud_storage"

Shrine.storages = {
  cache: Shrine::Storage::GoogleCloudStorage.new(bucket: "cache"),
  store: Shrine::Storage::GoogleCloudStorage.new(bucket: "store"),
}
```

You can set a predefined ACL on created objects, as well as custom headers using the `object_options` parameter:

```rb
Shrine::Storage::GoogleCloudStorage.new(
  bucket: "store",
  default_acl: 'publicRead',
  object_options: {
    cache_control: 'public, max-age: 7200'
  },
)
```


## Contributing

### Test setup

#### Option 1 - use the script

Review the script `test/create_test_environment.sh`. It will:
- create a Google Cloud project
- associate it with your billing account
- create a service account
- add the `roles/storage.admin` iam policy
- download the json credentials
- create a test bucket
- add the needed variables to your `.env` file

To run, it assumes you have already run `gcloud auth login`.
It also needs a `.env` file in the project root containing the project name
and the billing account to use:

```sh
cp .env.sample .env
# Edit .env to fill in your project and billing accounts
./test/create_test_environment.sh
```

#### Option 2 - manual setup

Create your own bucket and provide variables that allow for [project and credential lookup](http://googlecloudplatform.github.io/google-cloud-ruby/#/docs/google-cloud-storage/v1.6.0/guides/authentication#projectandcredentiallookup).
For example:

```sh
GCS_BUCKET=shrine-gcs-test-my-project
GOOGLE_CLOUD_PROJECT=my-project
GOOGLE_CLOUD_KEYFILE=/Users/user/.gcp/my-project/shrine-gcs-test.json
```

**Warning**: all content of the bucket is cleared between tests, create a new one only for this usage!

### Running tests

After setting up your bucket, run the tests:

```sh
$ bundle exec rake test
```

For additional debug, add the following to your `.env` file:

```sh
GCS_DEBUG=true
```

## License

[MIT](http://opensource.org/licenses/MIT)

[Google Cloud Storage]: https://cloud.google.com/storage/
[Shrine]: https://github.com/shrinerb/shrine
