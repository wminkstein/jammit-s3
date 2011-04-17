require 'spec_helper'

class TestS3AssetsVersioning
    include Jammit::S3AssetsVersioning
end
describe TestS3AssetsVersioning do
  describe "versioned_path method" do
    describe "when assets versioning disabled" do
      before do
        subject.stub!(:use_versioned_assets?).and_return(false)
        subject.should_not_receive(:assets_version)
      end

      it "should return paths as they are" do
        subject.versioned_path("").should == ""
        subject.versioned_path("/").should == "/"
        subject.versioned_path("file").should == "file"
        subject.versioned_path("file.ext").should == "file.ext"
        subject.versioned_path("/file.ext").should == "/file.ext"
        subject.versioned_path("dir/file.ext").should == "dir/file.ext"
        subject.versioned_path("/dir/file.ext").should == "/dir/file.ext"
        subject.versioned_path("./dir/file.ext").should == "./dir/file.ext"
        subject.versioned_path("../dir/file.ext").should == "../dir/file.ext"
      end

    end

    describe "when assets versioning enabled and no assets_version defined" do
      before do
        subject.stub!(:use_versioned_assets?).and_return(true)
        subject.stub!(:assets_version).and_return('')
      end

      it "should return paths as they are" do
        subject.versioned_path("").should == ""
        subject.versioned_path("/").should == "/"
        subject.versioned_path("file").should == "file"
        subject.versioned_path("file.ext").should == "file.ext"
        subject.versioned_path("/file.ext").should == "/file.ext"
        subject.versioned_path("dir/file.ext").should == "dir/file.ext"
        subject.versioned_path("/dir/file.ext").should == "/dir/file.ext"
        subject.versioned_path("./dir/file.ext").should == "./dir/file.ext"
        subject.versioned_path("../dir/file.ext").should == "../dir/file.ext"
      end

    end

    describe "when assets versioning enabled and assets_version defined" do
      before do
        subject.stub!(:use_versioned_assets?).and_return(true)
        subject.stub!(:assets_version).and_return('v1')
      end

      it "should return paths for use in Rails AssetTagHelper methods (i.e. image_tag, stylesheet_tag etc)" do
        # All calls from AssetTagHelpers are expected to have rooted (starting with /) path
        subject.versioned_path("/").should == "/v1/"
        subject.versioned_path("/file.ext").should == "/v1/file.ext"
        subject.versioned_path("/dir/file.ext").should == "/v1/dir/file.ext"
      end

      it "should return paths for use in S3Uploader" do
        # Incoming paths are expected to be relative and yet be versioned
        # with a relative url as well
        subject.versioned_path("", true).should == ""
        subject.versioned_path("file", true).should == "v1/file"
        subject.versioned_path("file.ext", true).should == "v1/file.ext"
        subject.versioned_path("dir/file.ext", true).should == "v1/dir/file.ext"
        subject.versioned_path("./dir/file.ext", true).should == "v1/./dir/file.ext"
        subject.versioned_path("../dir/file.ext", true).should == "v1/../dir/file.ext"
      end

      it "should return paths for use from Jammit::Compressor" do
        # incoming paths are extracted from css's url(path)
        # and can be relative and absolute. Relative paths should be returned as is.
        # Rooted paths should be returned versioned
        subject.versioned_path("").should == ""
        subject.versioned_path("/").should == "/v1/"
        subject.versioned_path("file").should == "file"
        subject.versioned_path("file.ext").should == "file.ext"
        subject.versioned_path("/file.ext").should == "/v1/file.ext"
        subject.versioned_path("dir/file.ext").should == "dir/file.ext"
        subject.versioned_path("/dir/file.ext").should == "/v1/dir/file.ext"
        subject.versioned_path("./dir/file.ext").should == "./dir/file.ext"
        subject.versioned_path("../dir/file.ext").should == "../dir/file.ext"
      end
    end
  end
end