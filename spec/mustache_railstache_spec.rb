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


describe Mustache::Railstache do

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
    
  end
end