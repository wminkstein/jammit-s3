namespace :jammit do
  namespace :s3 do

    desc "Upload Jammit assets to Amazon S3"
    task :upload do
      Jammit::S3CommandLine.new
    end

    desc "Upload Jammit assets to Amazon S3 and set RAILS_ASSET_ID on heroku to the last git commit"
    task :heroku, :app do |t, args|
      puts "Warning! your git directory is not clean." unless git_status.empty?
      asset_version = last_commit
      ENV["RAILS_ASSET_ID"] = asset_version
      Jammit::S3CommandLine.new
      set_heroku_var_cmd = "heroku config:add RAILS_ASSET_ID=#{asset_version}"
      set_heroku_var_cmd << " --app #{args[:app]}" unless args[:app].nil? or args[:app].empty? # no Rails loaded for .blank?/present?
      system(set_heroku_var_cmd) or fail("Could not set RAILS_ASSET_ID")
    end
  end

  def last_commit
    `git rev-parse HEAD`.chomp[0..6]
  end

  def git_status
    `git status --porcelain`.chomp
  end

end
