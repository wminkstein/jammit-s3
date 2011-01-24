require 'jammit/command_line'
require 'jammit/s3_assets_versioning'
require 'jammit/s3_command_line'
require 'jammit/s3_uploader'

module Jammit
  def self.upload_to_s3!(options = {})
    S3Uploader.new(options).upload
  end

  if defined?(Rails)
    class JammitRailtie < Rails::Railtie
      class << self
        include Jammit::S3AssetsVersioning
      end
      rake_tasks do
        load "tasks/jammit-s3.rake"
      end
      config.before_configuration do
        # Set asset_host and asset_path used in ActionView::Helpers::AssetTagHelper.
        # Since the block is executed before_configuration, it is possible
        # to override these values inside config/production.rb.
        config.action_controller.asset_host = self.asset_host
        if self.version_assets?
          config.action_controller.asset_path = Proc.new do |source|
            self.versioned_path(source)
          end
        end
      end
    end
  end
end
