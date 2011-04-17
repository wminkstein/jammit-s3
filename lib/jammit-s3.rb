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
        if self.separate_asset_host?
          config.action_controller.asset_host = self.asset_host
        end
        if self.version_assets?
          config.action_controller.asset_path = Proc.new do |source|
            self.versioned_path(source)
          end
        end
      end
    end
  end
end

if defined?(Rails)
  module Jammit
    class JammitRailtie < Rails::Railtie
      initializer "set asset host and asset id" do
        config.before_initialize do
          if Jammit.configuration[:use_cloudfront] && Jammit.configuration[:cloudfront_cname].present? && Jammit.configuration[:cloudfront_domain].present?
            asset_hostname = Jammit.configuration[:cloudfront_cname]
            asset_hostname_ssl = Jammit.configuration[:cloudfront_domain]
          elsif Jammit.configuration[:use_cloudfront] && Jammit.configuration[:cloudfront_domain].present?
            asset_hostname = asset_hostname_ssl = Jammit.configuration[:cloudfront_domain]            
          else
            asset_hostname = asset_hostname_ssl = "#{Jammit.configuration[:s3_bucket]}.s3.amazonaws.com"
          end

          if Jammit.package_assets and asset_hostname.present?
            puts "Initializing Cloudfront"                      
            ActionController::Base.asset_host = Proc.new do |source, request|
              if Jammit.configuration.has_key?(:ssl)
                protocol = Jammit.configuration[:ssl] ? "https://" : "http://"
              else
                protocol = request.protocol
              end
              if request.protocol == "https://"
                "#{protocol}#{asset_hostname_ssl}"
              else 
                "#{protocol}#{asset_hostname}"  
              end              
            end
          end
        end
      end
    end
  end
end