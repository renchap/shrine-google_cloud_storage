# Change Log
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]

## 3.3.0 - 2022-08-14

### Added
- `public` option on storage, which enabled the `publicRead` default ACL, as an easier way to create public objects

### Fixes
- Signed URLs were wrongly generated when `expires` was not provided
- Fixed special character encoding in URLs (thanks @camiloforero)

## 3.2.0 - 2022-01-07

### Added
- Encode filenames in URIs (#47 by @vanboom)

### Changed
- Minimum Ruby version is 2.6
- Multi Factor authentication is now required when publishing on Rubygems

## 3.1.0 - 2021-04-22

### Added
- Allow an ACL to be specicied for an object (#45 by @ianks)

### Fixed
- Ruby 3.0 keyword arguments fixes (#46 by @sho918)

## 3.0.1 - 2020-04-02

### Added
- Allow credentials to be manually specified when creating the Storage (#35 by @ianks)

## 3.0.0 - 2019-10-21

### Changed
- Updated for Shrine 3.0. This is a breaking change. (#37 by @janko)

## 2.0.1 - 2019-10-21

### Fixed
- When copying a file from an existing GCS object, the content type was not properly copied. This is a bug in the `google-cloud-storage` gem, a workaround has been added so it now works currently (issue #36)

## 2.0.0 - 2019-02-12

### Added
- `clear!` now accepts a block for conditional deletion. If a block is provided, it will only delete the files for which the block evaluates to `true` (#31 by @hwo411)

### Changed
- `presign` has been updated to use the new Shrine 2.11 API. This is a breaking change if you use `presign`, and bumps the `shrine` dependency to `>= 2.11` (#25 by @janko)
- This gem now uses `Shrine.with_file`, introduced in Shrine 2.11 (#29 by @janko)

### Fixed
- `clear!` was potentially not deleting every file (#26 by @janko)

## 1.0.1 - 2018-02-13

### Changed
- Moved tests to HTTP.rb (#23 by @janko-m)

### Fixed
- `presign` now correctly returns the headers needed for the `PUT` request (#23 by @janko-m)

## 1.0.0 - 2017-12-29

### Added
- You can specify a project when creating a storage (#16 by @rosskevin)
- Authentication is now delegated to [`google-cloud-ruby`](http://googlecloudplatform.github.io/google-cloud-ruby/#/docs/google-cloud-storage/master/guides/authentication#projectandcredentiallookup), which enables credentials discovery
- `#url` now supports presigning (`url(expires: …)`), matching the S3 storage (#16 by @rosskevin)

### Changed
- switched to `google-cloud-storage` gem (#16 by @rosskevin)
- added a `test/create_test_environment.sh` script to setup a test environment automatically (#16 by @rosskevin)
- use `skip_lookup: true` when instanciating a bucket object to avoid an API call. This reduces the number of API calls for most operations, making them faster. It also allows operating on buckets with a restricted Service Account that does not have access to `storage.buckets.get` but can access the files. (#21)

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
