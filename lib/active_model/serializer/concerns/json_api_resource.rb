module ActiveModel
  class Serializer
    module JsonApiResource
      extend ActiveSupport::Concern
      # TODOS:
      # * caching
      # * virtual attributes

      def jsonapi_type
        _resource_identifier[:type]
      end

      def jsonapi_id
        _resource_identifier[:id]
      end

      def as_jsonapi(options = {})
        _resource_identifier.tap do |json|
          if attrs = _attrs(options[:fields])
            json[:attributes] = attrs

            related = jsonapi_related(options[:fields])
            unless related.empty?
              json[:relationships] = {}

              related.each_pair do |name, serializer|
                if serializer.is_a?(ActiveModel::Serializer::CollectionSerializer)
                  resource_identifiers = []
                  serializer.send(:serializers).each do |s|
                    resource_identifiers << s._resource_identifier
                  end
                  json[:relationships][name] = resource_identifiers
                else
                  json[:relationships][name] = serializer._resource_identifier
                end
              end
            end
          end
        end
      end

      def jsonapi_related(whitelist)
        @jsonapi_related ||= {}.tap do |related|
          associations.each do |association|
            next if whitelist && !whitelist.include?(association.key)

            if association.serializer && association.serializer.object
              related[association.key] ||= association.serializer
            end
          end
        end
      end

      # private

      # todo: caching
      def _attrs(fields)
        attrs = attributes(fields).except(:id)
        attrs.empty? ? nil : attrs
      end

      def _resource_identifier
        ActiveModelSerializers::Adapter::JsonApi::ResourceIdentifier
          .new(self, {}).as_json # option key_transform
      end
    end
  end
end
