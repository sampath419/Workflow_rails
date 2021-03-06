module RailsWorkflow
  module Processes
    # = DependencyResolver
    #
    # New operation can be added to process if all it's dependencies are satisfied.
    # For example current operation can depend on some existing process operation which
    # should be completed - then current operation can be build

    module DependencyResolver
      extend ActiveSupport::Concern

      included do
        # This methods get's operations that depends on given one.
        # Operation::DependencyResolver resolves operation template dependencies
        # but we can define dependencies not only by template but by some other
        # business logic on process level. That is why I splitted operation
        # dependencies on process and operation level
        #
        def build_dependencies operation

          new_operations = []

          matched_templates(operation).each do |operation_template|
            completed_dependencies = [operation]

            if operation_template.resolve_dependency operation
              new_operations << operation_template.build_operation!(self, completed_dependencies)
            end

          end

          new_operations.each do |new_operation|
            if incomplete_statuses.include?(status)
              self.operations << new_operation
              new_operation.start
            end
          end

        rescue => exception
          RailsWorkflow::Error.create_from(
              exception, {
                           parent: self,
                           target: self,
                           method: :build_dependencies,
                           args: [operation]
                       }
          )

        end

        private

        def matched_templates operation
          template.dependent_operations(operation) - operations.map(&:template)
        end






      end
    end
  end
end