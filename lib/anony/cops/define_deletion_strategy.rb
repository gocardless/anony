# frozen_string_literal: true

require "rubocop"

require_relative "../version"

module RuboCop
  module Cop
    module Lint
      # This cop checks whether an ActiveRecord model implements the `.anonymise`
      # preference (using the Anony gem).
      #
      # @example Good
      #   class User < ApplicationRecord
      #     anonymise do
      #       overwrite do
      #         email :email
      #         hex :given_name
      #       end
      #     end
      #   end
      #
      # @example Bad
      #   class MyNewThing < ApplicationRecord; end
      class DefineDeletionStrategy < Cop
        MSG = "Define .anonymise for %<model>s, see https://github.com/gocardless/" \
              "anony/blob/#{Anony::VERSION}/README.md for details".freeze

        def_node_search :uses_anonymise?, "(send nil? :anonymise)"

        def on_class(node)
          return unless model?(node)
          return if uses_anonymise?(node)

          add_offense(node, message: sprintf(MSG, model: class_name(node)))
        end

        def model?(node)
          return unless (superclass = node.children[1])

          superclass.const_name == model_superclass_name
        end

        def class_name(node)
          node.children[0].const_name
        end

        def model_superclass_name
          cop_config["ModelSuperclass"] || "ApplicationRecord"
        end
      end
    end
  end
end
