require "spec_helper"

describe Fog::Collection do
  class TestModel < Fog::Model
    identity :id
    attribute :value
  end

  class TestCollection < Fog::Collection
    model TestModel

    def all(options = {})
      data = service.fetch_objects
      load data
    end
  end

  class TestCollectionService
    def initialize(objects)
      @objects = objects
    end

    def fetch_objects
      @objects
    end
  end

  describe "Array compatibility" do
    [
      # [method, objects, block, args...]
      [:size,  []],
      [:size,   [{id: 1, value: "one"}]],
      [:size,   [{id: 1, value: "one"}, { id: 2, value: "two"}]],
      [:count,  []],
      [:count,  [{id: 1, value: "one"}]],
      [:count,  [{id: 1, value: "one"}, { id: 2, value: "two"}]],
      [:count,  [{id: 1, value: "one"}], ->(o) { o.value == "two" }],
      [:count,  [{id: 1, value: "one"}, { id: 2, value: "two"}], ->(o) { o.value == "two" }],
      [:select, [{id: 1, value: "one"}], ->(o) { o.value == "two" }],
      [:select, [{id: 1, value: "one"}, { id: 2, value: "two"}], ->(o) { o.value == "two" }],
      [:reject, [{id: 1, value: "one"}], ->(o) { o.value == "two" }],
      [:reject, [{id: 1, value: "one"}, { id: 2, value: "two"}], ->(o) { o.value == "two" }],
      [:to_a,   []],
      [:to_a,   [{id: 1, value: "one"}]],
      [:to_a,   [{id: 1, value: "one"}, { id: 2, value: "two"}]],
      [:to_ary, []],
      [:to_ary, [{id: 1, value: "one"}]],
      [:to_ary, [{id: 1, value: "one"}, { id: 2, value: "two"}]],
    ].each do |method, objects, block, *args|
      expected = objects.map { |obj| TestModel.new obj }.to_a.public_send(method, *args, &block)
      it "#{method} returns #{expected} when service fetches #{objects}" do
        collection = TestCollection.new service: TestCollectionService.new(objects)
        actual = collection.public_send(method, *args, &block)

        assert_equal expected, actual
        puts "#{method} #{expected.inspect} == #{actual.inspect}"
      end
    end
  end

  describe "overriden methods" do
    describe "#inspect" do
      it "formats" do
        objects = [{ id: 1, value: "one"}]
        collection = TestCollection.new service: TestCollectionService.new(objects)
        assert_equal Fog::Formatador.format(collection), collection.inspect
      end
    end
  end
end