# Copyright 2010-2011 Sean Cribbs and Basho Technologies, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'active_support/concern'
require 'active_model/callbacks'

module Ripple
  # Adds lifecycle callbacks to {Ripple::Document} models, in the typical
  # ActiveModel fashion.
  module Callbacks
    extend ActiveSupport::Concern

    included do
      extend ActiveModel::Callbacks
      define_model_callbacks :create, :update, :save, :destroy
      define_callbacks :validation, :terminator => "result == false", :scope => [:kind, :name]
    end

    module ClassMethods
      # Defines a callback to be run before validations.
      def before_validation(*args, &block)
        options = args.last
        if options.is_a?(Hash) && options[:on]
          options[:if] = Array(options[:if])
          options[:if] << "@_on_validate == :#{options[:on]}"
        end
        set_callback(:validation, :before, *args, &block)
      end

      # Defines a callback to be run after validations.
      def after_validation(*args, &block)
        options = args.extract_options!
        options[:prepend] = true
        options[:if] = Array(options[:if])
        options[:if] << "!halted && value != false"
        options[:if] << "@_on_validate == :#{options[:on]}" if options[:on]
        set_callback(:validation, :after, *(args << options), &block)
      end
    end

    # @private
    module InstanceMethods
      # @private
      def really_save(*args, &block)
        run_save_callbacks do
          super
        end
      end

      def run_save_callbacks
        state = new? ? :create : :update
        run_callbacks(:save) do
          run_callbacks(state) do
            yield
          end
        end
      end

      # @private
      def destroy(*args, &block)
        run_callbacks(:destroy) do
          super
        end
      end

      # @private
      def valid?(*args, &block)
        @_on_validate = new? ? :create : :update
        run_callbacks(:validation) do
          super
        end
      end
    end
  end
end
