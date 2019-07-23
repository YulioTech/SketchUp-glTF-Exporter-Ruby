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
		class GltfBufferViews
			
			def initialize
				@buffer_views = []
			end
			
			attr_reader :buffer_views 

			def add_buffer_view(buffer, byteOffset, byteLength, target, byteStride)
				
				# Create a new buffer_view
				buffer_view = {}
				buffer_view["buffer"] = buffer
				if byteOffset != 0
					buffer_view["byteOffset"] = byteOffset
				end
				buffer_view["byteLength"] = byteLength
				if target != nil
					buffer_view["target"] = target
				end
				if byteStride != nil
					buffer_view["byteStride"] = byteStride
				end

				index = @buffer_views.length
				@buffer_views.push(buffer_view)
				
				#puts 'Creating buffer view ' + index.to_s + ' for offset ' + byteOffset.to_s + ' and length ' + byteLength.to_s + ' bytes'
				return index
			end

		end
	end
end
