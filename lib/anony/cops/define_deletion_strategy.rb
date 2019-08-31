# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # This cop checks whether an ActiveRecord model implements the `.anonymise`
      # preference (from the Anony library).
      #
      # For data deletion purposes, this will be mandatory going forwards.
      #
      # @example
      #
      # # good
      # class User < ApplicationRecord
      #   anonymise do
      #     email :email
      #     hex :given_name
      #   end
      # end
      #
      # # bad
      # class MyNewThing < ApplicationRecord; end
      class DefineDeletionStrategy < Cop
        MSG = "Define .anonymise for %<model>s, see ./lib/anony/README.md for details"

        def_node_matcher :only_models, <<~PATTERN
          (class
            (const _ $_)
            (const nil? :ApplicationRecord)
          ...)
        PATTERN

        def_node_search :uses_anonymise?, "(send _ :anonymise)"

        def on_class(node)
          only_models(node) do |model|
            unless uses_anonymise?(node)
              add_offense(node, message: sprintf(MSG, model: model))
            end
          end
        end
      end
    end
  end
end
