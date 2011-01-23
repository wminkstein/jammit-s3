require 'jammit/compressor'

module Jammit
  module S3AssetsVersioning
    # Returned value is set directly to config.action_controller.asset_host.
    # By default returns the host of Amazon bucket, or, if configured,
    # the value of s3_cloudfront_host property from config/assets.yml.
    # For more complex needs set the value of config.action_controller.asset_host
    # to something else (like a Proc) inside config/environments/production.rb
    def asset_host
      host = Jammit.configuration[:s3_cloudfront_host]
      host.present? ? host : "#{Jammit.configuration[:s3_bucket]}.s3.amazonaws.com"
    end

    # Called from a proc attached to config.action_controller.asset_path
    # Return path with asset_version inserted before the extension.
    # ==== Examples
    #   assets_version = 1
    #   versioned_path("images/logo.png") #=> "images/logo.1.png"
    def versioned_path(path)
      version = assets_version
      ext = File.extname(path)
      path_without_ext = path.chomp(ext)
      version = ".#{version}" unless (version.nil? || version.empty?)
      "#{path_without_ext}#{version}#{ext}"
    end

    def assets_version
      ENV["RAILS_ASSET_ID"] || ''
    end

    def assets_version=(value)
      ENV["RAILS_ASSET_ID"] = value
    end
  end
end

if Jammit.package_assets
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
      Helper.versioned_path(path)
    end
  end
end

