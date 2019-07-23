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

require 'base64'
module Yulio
	module GltfExporter
        class GltfBuffers
            def initialize()
                #@buffers = {} # Can use hash indexed buffers in you want to initialize & use them out of order, but no real need for that
                @buffers = []
            end
            
            def add_or_append_buffer(index, bytes, alignment)

                # if (@buffers[index] == nil)
                #     puts 'Creating a new buffer with index ' + index.to_s
                #     buffer = ''
                #     @buffers[index] = buffer
                # else
                #     puts 'Using the existing buffer with index ' + index.to_s
                #     buffer = @buffers[index]
                # end

                if (index < @buffers.length)
                    #puts 'Using the existing buffer with index ' + index.to_s
                    buffer = @buffers[index]
                else
                    #puts 'Creating a new buffer with index ' + @buffers.length.to_s
                    buffer = ''
                    @buffers.push(buffer)
                end

                while buffer.length % alignment != 0
					#puts 'Padding the buffer'
					buffer = buffer << 0
				end

                offset = buffer.length

                #puts 'Adding ' + bytes.length.to_s + ' bytes to buffer at offset ' + offset.to_s + ' with alignment of ' + alignment.to_s
				
				buffer << bytes
				return offset
            end

            def get_buffers
				buffers = []
                @buffers.each do |item|
				    buf =
				    {
					    "byteLength" => item.length
				    }
                    buffers.push(buf)
                end
				return buffers, @buffers
			end
			
			def encode_buffers()
                buffers = []
                @buffers.each do |item|
				    buf =
				    {
					    "uri" => "data:application/octet-stream;base64," + Base64.strict_encode64(item),
					    "byteLength" => item.length
				    }
                    buffers.push(buf)
                end
				return buffers
			end
        end
    end
end
