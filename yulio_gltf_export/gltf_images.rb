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

require 'tmpdir'

module Yulio
	module GltfExporter
			
		class GltfImages
			
			def initialize(buffer, buffer_views, errors)
				@errors = errors
				@buffer = buffer
				@buffer_views = buffer_views
				@images = []
			end

			# Write image texture to the buffer, create a new buffer view, and add the image to the images array
			def add_image_node(imageType, image_bytes)
				if imageType == 'jpg'
					imageType = 'jpeg'
				end
				
				if imageType != 'jpeg' && imageType != 'png'
					# it is generally fatal to the glTF viewer if the image is not a JPEG or PNG.
					@errors.push("image/" + imageType + ' ' + TRANSLATE('UnsupportedImage'))
				end
				
				offset = @buffer.add_buffer(image_bytes, 1)
				view = @buffer_views.add_buffer_view(0, offset, image_bytes.length,  nil,nil)
				
				image =
				{
					"bufferView" => view,
					"mimeType"=> "image/" + imageType
				}
				index = @images.length
				@images.push(image)
				return index
			end
			
			
			# Extract the texture from the face
			def add_image(face)
				type,bytes = get_image_bytes(face)
				return add_image_node(type,bytes)
			end


			# Helper function to get the texture from a face.
			# warning, if the w in uvw is not 1, this will get a distorted imitation of the original texture.
			# in that case, a todo here is to create a new face, apply the texture, then export.
			# The problem with that is that it changes the model, so an undo is required.
			def get_image_bytes(face)
				
				texturewriter = Sketchup.create_texture_writer
				
				# get the extension of the texture filename
				ext = face.material.texture.filename.split('.').last
				ext.downcase!

				# create a random file in the tmp directory
				n = Random.rand(100000) + 100000
				file =  File.join(Dir.tmpdir() , n.to_s + "."+ ext)
				
				# load the texture, and write it to the file (why does this need to be separate operations?)
				# todo: put out a feature request so unmangled textures can be read straight into memory
				if face.class == Sketchup::Face
					texturewriter.load face, true
					texturewriter.write face, true, file
				else
					texturewriter.load face
					texturewriter.write face, file
				end
				
				
				# read the file into memory
				bytes = File.binread(file)
				
				# we don't need the file, so delete it
				File.delete(file)
				
				return ext, bytes
			end
			
			def get_images
				return @images
			end

		end
	end
end

