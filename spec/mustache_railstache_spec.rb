require_relative '../lib/mustache_railstache.rb'

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
end