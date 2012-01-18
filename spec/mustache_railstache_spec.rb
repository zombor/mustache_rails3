require_relative '../lib/mustache_railstache.rb'
require 'fakefs/safe'

module Rails; end

class EmptyStache < Mustache::Railstache
end

class FullStache < Mustache::Railstache
  def one
    1
  end
  def two
    2
  end
  private
    def three
      3
    end
end

class InitialStache < Mustache::Railstache
  def initialize
  end
  def init
  end
end

class ExtraFieldHash < Mustache::Railstache
  expose_to_hash :foo
end

class MultipleExposedFieldsHash < Mustache::Railstache
  expose_to_hash :bar, :lava
end

describe Mustache::Railstache do
  describe ".expose_to_hash" do
    it "should add to fields_for_hash" do
      ExtraFieldHash.fields_for_hash.should =~ [:foo]
    end

    it "should support adding multiple fields to fields_for_hash" do
      MultipleExposedFieldsHash.fields_for_hash =~ [:bar, :lava]
    end
  end

  describe "#to_hash" do
    it "should return an empty hash for an empty class" do
      e = EmptyStache.new
      e.to_hash.should == {}
    end

    it "should return a hash containing all public methods" do
      f = FullStache.new
      f.to_hash.should == {
        :one => 1,
        :two => 2,
      }
    end

    it "should not include initialize or init" do
      i = InitialStache.new
      i.to_hash.should == {}
    end

    it "should include fields added with expose_to_hash" do
      e = ExtraFieldHash.new
      e[:foo] = 'bar'
      e.to_hash.should == {foo: 'bar'}

      m = MultipleExposedFieldsHash.new
      m[:bar] = 'man'
      m[:lava] = 'lamp'
      m.to_hash.should == {bar: 'man', lava: 'lamp'}
    end
  end

  describe "#partials" do
    before(:each) do
      FakeFS.activate!

      @f = FullStache.new

      @template_extension = "html.mustache"

      rails_root = "/tmp/this_doesnt_exist"
      @template_root = "#{rails_root}/app/templates"
      @template_path = "#{@template_root}/sample"
      @shared_path = "#{@template_root}/shared"
      @other_path = "#{@template_root}/other_dir"

      FileUtils.mkdir_p "#{@template_root}"
      FileUtils.mkdir_p "#{@template_path}"
      FileUtils.mkdir_p "#{@shared_path}"
      FileUtils.mkdir_p "#{@other_path}"

      Rails.stub(:root).and_return(Pathname.new(rails_root))

      @f.stub(:template_file).and_return("#{@template_path}/test.html.mustache")
    end

    after(:each) do
      FakeFS.deactivate!
    end

    it "should try to find the parial in template dir" do
      @file = "base_template"
      @filename = "_#{@file}.#{@template_extension}"

      File.open("#{@template_path}/#{@filename}", 'w') { |f| f.write('template_dir') }

      @f.partial(@file).should == "template_dir"
    end

    it "should try to find partials in shared dir" do
      @file = "shared_template"
      @filename = "_#{@file}.#{@template_extension}"

      File.open("#{@shared_path}/#{@filename}", 'w') { |f| f.write('shared_dir') }

      @f.partial(@file).should == "shared_dir"
    end

    it "should try to find the partial in other directories if a \/ is  detected" do
      @filename = "other_dir/_other_template.#{@template_extension}"

      File.open("#{@template_root}/#{@filename}", 'w') { |f| f.write('other_dir') }

      @f.partial(@file).should == "other_dir"
    end
  end
end