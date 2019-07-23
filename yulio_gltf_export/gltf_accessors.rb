#-----------------------------------------------------------------------------------
# MIT License
#
# Copyright (c) 2019 Yulio Technologies Inc.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#-----------------------------------------------------------------------------------

module Yulio
	module GltfExporter
		class GltfAccessors
			
			def initialize
				@accessors = []
			end
			
			attr_reader :accessors 

			# Add an accessor to the accessor list
			def add_accessor(bufferView, byteOffset, componentType, count, type, min, max)
				accessor =
				{
					"bufferView" => bufferView,
					"componentType" => componentType,
					"count" => count,
					"type" => type
				}
				if(byteOffset != 0)
					accessor["byteOffset"] = byteOffset
				end
				if(min != nil && max != nil)
					accessor["min"] = min
					accessor["max"] = max
				end
				index = @accessors.length
				#puts 'Creating Accessor ' + index.to_s + ' for buffer view ' + bufferView.to_s + ' at offset ' + byteOffset.to_s
				@accessors.push(accessor)
				return index
			end
			
		end
	end
end
