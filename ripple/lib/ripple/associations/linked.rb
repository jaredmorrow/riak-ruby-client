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
# limitations under the License

require 'ripple/associations'

module Ripple
  module Associations
    module Linked
      def replace(value)
        @reflection.verify_type!(value, @owner)
        @owner.robject.links -= links
        Array(value).compact.each do |doc|
          doc.save if doc.new?
          @owner.robject.links << doc.robject.to_link(@reflection.link_tag)
        end
        loaded
        @target = value
      end

      protected
      def links
        @owner.robject.links.select(&@reflection.link_filter)
      end

      def robjects
        @owner.robject.walk(*Array(@reflection.link_spec)).first || []
      rescue
        []
      end
    end
  end
end
