# Change Log
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]

### Added
- You can specify a project when creating a storage (#16 by @rosskevin)
- Authentication is now delegated to [`google-cloud-ruby`](http://googlecloudplatform.github.io/google-cloud-ruby/#/docs/google-cloud-storage/master/guides/authentication#projectandcredentiallookup), which enables credentials discovery
- `#url` now supports presigning (`url(expires: …)`), matching the S3 storage (#16 by @rosskevin)

### Changed
- switched to `google-cloud-storage` gem (#16 by @rosskevin)
- added a `test/create_test_environment.sh` script to setup a test environment automatically (#16 by @rosskevin)

### Removed
- removed support for `multi_delete`, as this feature has been deprecated in Shrine

## 0.2.0 - 2017-06-23
### Changed
- moved batching to `batch_delete`, so it is used for `multi_delete` (#11 by @janko-m)
- updated `google-api-client` to 0.13

## 0.1.0 - 2017-05-22
### Added
- First released version
- Base functionality (create objects, delete, copy, ...)
- Support for presigned URLs
- Support for default ACLs
- Support for setting custom headers
