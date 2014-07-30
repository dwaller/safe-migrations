module SafeMigrations
  module MigrationExt
    module ClassMethods
      UNSAFE_METHODS = [:drop_table, :remove_column]

      def self.extended(base)
        class << base
          alias_method_chain :method_missing, :safety
        end
      end

      def safety_assured(&block)
        @safety = true
        yield
      ensure
        @safety = false
      end

      def safe?
        !!@safety
      end

      def bypassing_safety_checks?
        ENV['FORCE'] && ENV['FORCE'] != ''
      end

      def method_missing_with_safety(method, *args, &block)
        if safe? || bypassing_safety_checks?
          return method_missing_without_safety(method, *args, &block)
        end

        case method
        when :remove_column
          raise UnsafeRemoveColumn
        when :drop_table
          raise UnsafeDropTable
        when :add_index
          options = args[2]
          unless (options && options[:algorithm] == :concurrently)
            raise UnsafeAddIndex
          end
        end

        method_missing_without_safety(method, *args, &block)
      end
    end

  end
end
