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
		class GltfTextures
			
			# requires reference to GltfImages object
			def initialize(images)
				@images = images
				
				@textures = []
				@textures_hash = {}
			end
			
			def add_texture(face)
				if(face.material == nil)
					return nil
				end
				if(face.material.texture == nil)
					return nil
				end
				index = @textures_hash[face.material.texture]
				if(index != nil)
					return index
				end
				
				image_source_id = @images.add_image(face)
				index = @textures.length
				texture =
				{
					"source"=> image_source_id,
					"sampler" => 0
				}
				
				#if sampler != nil
				#	texture["sampler"] = sampler
				#end
				@textures_hash[texture] = index
				@textures.push(texture)
				return index
			end
			
			#def add_metallic_texture()
			#	index = @textures_hash['metal']
			#	if index != nil
			#		return index
			#	end
			#	metal_id = @images.add_metallic_image()
			#	texture =
			#	{
			#		"source"=> metal_id
			#	}
			#	index = @textures.length
			#	@textures_hash['metal'] = index
			#	@textures.push(texture)
			#	return index
			#end
			
			def get_textures
				return @textures
			end

		end

	end
end
