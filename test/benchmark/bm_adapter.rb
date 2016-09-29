require_relative './benchmarking_support'
require_relative './app'

require 'jsonapi'
require 'jsonapi/serializable'

time = 10
disable_gc = true
ActiveModelSerializers.config.key_transform = :unaltered
has_many_relationships = (0..60).map do |i|
  HasManyRelationship.new(id: i, body: 'ZOMG A HAS MANY RELATIONSHIP')
end
has_one_relationship = HasOneRelationship.new(
  id: 42,
  first_name: 'Joao',
  last_name: 'Moura'
)
primary_resource = PrimaryResource.new(
  id: 1337,
  title: 'New PrimaryResource',
  virtual_attribute: nil,
  body: 'Body',
  has_many_relationships: has_many_relationships,
  has_one_relationship: has_one_relationship
)
serializer = PrimaryResourceSerializer.new(primary_resource)

class HasOneResource < JSONAPI::Serializable::Resource
  type 'has_one_resources'

  id do
    @ho.id.to_s
  end

  relationship :primary_resources do
    data do
      PrimaryResourceResource.new(primary: @ho.primary_resources)
    end
  end

  relationship :has_many_relationships do
    data do
      @ho.has_many_relationships.map do |r|
        HasManyResource.new(hm: r)
      end
    end
  end
end

class HasManyResource < JSONAPI::Serializable::Resource
  type 'has_many_resources'

  id do
    @hm.id.to_s
  end

  relationship :has_one_relationship do
    data do
      HasOneResource.new(ho: @hm.has_one_relationship)
    end
  end

  relationship :primary_resource do
    data do
      PrimaryResourceResource.new(@hm.primary_resource)
    end
  end
end

class VirtualResource < JSONAPI::Serializable::Resource
  type 'virtual_resources'

  id do
    @va.id.to_s
  end

  attribute :name do
    @va.name
  end
end

class PrimaryResourceResource < JSONAPI::Serializable::Resource
  type 'primary_resources'

  id do
    @primary.id.to_s
  end

  attribute :title do
    @primary.title
  end

  attribute :body do
    @primary.body
  end

  relationship :has_many_relationships do
    data do
      @primary.has_many_relationships.map do |r|
        HasManyResource.new(hm: r)
      end
    end
  end

  relationship :has_one_relationship do
    data do
      HasOneResource.new(ho: @primary.has_one_relationship)
    end
  end

  relationship :virtual_attribute do
    data do
      va = VirtualAttribute.new(id: 999, name: 'Free-Range Virtual Attribute')
      VirtualResource.new(va: va)
    end
  end
end

#Benchmark.ams('attributes', time: time, disable_gc: disable_gc) do
  #attributes = ActiveModelSerializers::Adapter::Attributes.new(serializer)
  #attributes.as_json
#end
resource = PrimaryResourceResource.new(primary: primary_resource)

#old = ActiveModelSerializers::Adapter::JsonApi.new(serializer)
#puts old.as_json.inspect

#new = JSONAPI.render resource, include: 'has_one_relationship,has_many_relationships,virtual_attribute'
#puts new.inspect

Benchmark.ams('resource', time: time, disable_gc: disable_gc) do
  resource = PrimaryResourceResource.new(primary: primary_resource)
  JSONAPI.render resource,
      include: 'has_one_relationship,has_many_relationships,virtual_attribute'
end

Benchmark.ams('json_api', time: time, disable_gc: disable_gc) do
  json_api = ActiveModelSerializers::Adapter::JsonApi.new(serializer)
  json_api.as_json
end

#Benchmark.ams('json', time: time, disable_gc: disable_gc) do
  #json = ActiveModelSerializers::Adapter::Json.new(serializer)
  #json.as_json
#end
