require 'jammit/compressor'

module Jammit
  module S3AssetsVersioning

    # Need to only apply versioning when package_assets enabled and using
    # Amazon's CloudFront CDN service, since it does not honor
    # cache-busting query string to static assets.
    # One approach is to send invalidation request to Amazon CloudFront service (not implemented here).
    # Another approach is to embed the cache busting asset_version to the asset file name/path.
    # Rails calculates the cache busting token based on the file's File.mtime, but that is
    # resource expensive and may not be doable since the assets may only be hosted in CloudFront.
    # The most straight-forward solution is to use some release identifier and either insert
    # it in the file name or use it as the assets root for this release.
    # Currently S3AssetVersioning supports the separate assets root per release approach:
    # The final layout of the bucket when using CloudFront distribution:
    # <bucketname>/
    #   <assets_version1>/
    #     assets/...
    #     images/...
    #     javascripts/...
    #   <assets_verion2>/
    #     assets/...
    #     images/...
    #     javascripts/...

    # Returns true if need to apply filename/path versioning technique
    def version_assets?
      Jammit.package_assets && Jammit.configuration[:s3_cloudfront_host]
    end

    # By default returns the host of Amazon bucket, or, if configured,
    # the value of s3_cloudfront_host property from config/assets.yml.
    # Returned value is set directly to config.action_controller.asset_host.
    # For more complex needs set the value of config.action_controller.asset_host
    # to something else (like a Proc) inside config/environments/production.rb
    def asset_host
      host = Jammit.configuration[:s3_cloudfront_host]
      host.present? ? host : "#{Jammit.configuration[:s3_bucket]}.s3.amazonaws.com"
    end

    # Called from a proc attached to config.action_controller.asset_path,
    # from monkey-patched Jammit::Compressor and from S3Uploader
    # to calculate asset paths
    def versioned_path(path, version_relative_paths=false)
      return path unless self.version_assets?
      return path if path.empty? || (Pathname.new(path).relative? && !version_relative_paths)
      version = assets_version
      return path if version.nil? || version.empty?
      version = Pathname.new(path).relative? ? "#{version}/" : "/#{version}"
      "#{version}#{path}"
    end

    # Returns a token used to version assets
    # Use RAILS_ASSET_ID var (as already used by Rails) if defined
    # or check heroku's COMMIT_HASH (undocumented) var,
    # or return an empty string
    def assets_version
      ENV["RAILS_ASSET_ID"] || ENV['COMMIT_HASH'] || try_git_log_command || ''
    end

    # Force to use a specific token to version assets
    def assets_version=(value)
      ENV["RAILS_ASSET_ID"] = value
    end

    def try_git_log_command
      # should work on local dev environments
      # and during packaging/uploading of assets with jammit-s3
      `git log --pretty=format:'%h' -1`.chomp
    end
  end
end

# reopen class Compressor from jammit
class Jammit::Compressor
  # lets not pollute Compressor's namespace with AssetTagHelper
  class Helper;
    class << self
      include Jammit::S3AssetsVersioning;
    end
  end

  # monkey patch path calculations done in Jammit::Compressor
  # This method is used to calculate path to images referenced in stylesheets with url(path).
  alias old_rewrite_asset_path rewrite_asset_path

  def rewrite_asset_path(path, file_path)
    if Helper.version_assets?
      versioned_path = Helper.versioned_path(path)
      # make sure devs see what's being changed
      puts "Rewriting #{path} as #{versioned_path}" unless path == versioned_path
      versioned_path
    else
      old_rewrite_asset_path(path, file_path)
    end
  end
end

