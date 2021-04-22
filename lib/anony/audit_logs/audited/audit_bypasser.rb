module Anony
  module AuditLogs
    module Audited
      class AuditBypasser
        def initialize(model_class)
          @model_class = model_class
        end

        def without_auditing
          @model_class.without_auditing do
            yield
          end
        end
      end
    end
  end
end