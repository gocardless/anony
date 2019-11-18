# frozen_string_literal: true

require "rubocop"

require_relative "../version.rb"

module RuboCop
  module Cop
    module Lint
      # This cop checks whether an ActiveRecord model implements the `.anonymise`
      # preference (using the Anony gem).
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
        MSG = "Define .anonymise for %<model>s, see https://github.com/gocardless/" \
              "anony/blob/#{Anony::VERSION}/README.md for details"

        def_node_matcher :only_models, <<~PATTERN
          (class
            (const _ $_)
            (const nil? :ApplicationRecord)
          ...)
        PATTERN

        def_node_search :uses_anonymise?, "(send _ :anonymise)"

        def on_class(node)
          only_models(node) do |model|
            add_offense(node, message: sprintf(MSG, model: model)) unless uses_anonymise?(node)
          end
        end
      end
    end
  end
end
