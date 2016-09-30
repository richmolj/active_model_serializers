require 'test_helper'

require 'jsonapi/renderer'
require 'jsonapi/serializable'

module ActiveModel
  class Serializer
    class AsJsonapiTest < ActiveSupport::TestCase
      def serializer_klass
        Class.new(PostSerializer) do
          def blog
            object.blog if object.respond_to?(:blog)
          end
        end
      end

      def setup
        @post = Post.new(id: 1)
        @serializer = serializer_klass.new(@post)
      end

      def test_jsonapi_attributes
        @post.title = 'test title'

        expected = {
          id: '1',
          type: 'posts',
          attributes: {
            title: 'test title',
            body: nil
          }
        }

        assert_equal expected, @serializer.as_jsonapi
      end

      # TODO: this would move to a separate spec
      # Or just be part of current suite
      def test_sideload
        @post.title = 'test title'
        @post.author = Author.new(id: 1, name: 'dhh')
        rendered = JSONAPI.render @serializer,
          include: 'author'

        expected = {
          data: {
            id: '1',
            type: 'posts',
            attributes: {
              title: 'test title',
              body: nil
            },
            relationships: {
              author: {
                id: '1',
                type: 'authors'
              }
            }
          },
          included: [
            {
              id: '1',
              type: 'authors',
              attributes: {
                name: 'dhh'
              }
            }
          ]
        }

        assert_equal expected, rendered
      end
    end
  end
end
