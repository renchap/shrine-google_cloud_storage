[![Gem Version](https://badge.fury.io/rb/shrine-google_cloud_storage.svg)](https://badge.fury.io/rb/shrine-google_cloud_storage)

# Shrine::Storage::GoogleCloudStorage

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

Review the script `test/test_env_setup.sh`.  It will:
- create a service account
- add the `roles/storage.admin` iam policy
- download the json credentials
- create a test bucket
- create a private `.env` file with relevant variables

To run, it assumes you have already run `gcloud auth login`.

```sh
GOOGLE_CLOUD_PROJECT=[my project id]
./test/test_env_setup.sh
```

#### Option 2 - manual setup

Create your own bucket and provide variables that allow for [project and credential lookup](http://googlecloudplatform.github.io/google-cloud-ruby/#/docs/google-cloud-storage/v1.6.0/guides/authentication#projectandcredentiallookup).
For example:

```sh
GCS_BUCKET=shrine-gcs-test-my-project
GOOGLE_CLOUD_PROJECT=my-project
GOOGLE_CLOUD_KEYFILE=/Users/kross/.gcp/my-project/shrine-gcs-test.json
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
[Shrine]: https://github.com/janko-m/shrine
[Application Default Credentials]: https://developers.google.com/identity/protocols/application-default-credentials
