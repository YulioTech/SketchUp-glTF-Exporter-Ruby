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
$LOAD_PATH << File.expand_path(File.dirname(__FILE__))
require "mini_magick"
require 'tmpdir'

module Yulio
	module GltfExporter
			
		class GltfImages
			
			def initialize(buffers, buffer_views, errors, buffer_index)
				@errors = errors
				@buffers = buffers
				@buffer_views = buffer_views
				@images = []
				@buffer_index = buffer_index
			end
			
			attr_reader :images 

			# Write image texture to the buffer, create a new buffer view, and add the image to the images array
			def add_image_node(imageType, image_bytes)
				if imageType == 'jpg'
					imageType = 'jpeg'
				end
				
				if imageType != 'jpeg' && imageType != 'png'
					# it is generally fatal to the glTF viewer if the image is not a JPEG or PNG.
					@errors.push("image/" + imageType + ' ' + TRANSLATE('UnsupportedImage'))
				end
				
				#puts "Writing image buffer with index " + @buffer_index.to_s
				offset = @buffers.add_or_append_buffer(@buffer_index, image_bytes, 1)
				view = @buffer_views.add_buffer_view(@buffer_index, offset, image_bytes.length, nil, nil)
				#@buffer_index = @buffer_index + 1
				
				image =
				{
					"bufferView" => view,
					"mimeType"=> "image/" + imageType
				}
				index = @images.length
				@images.push(image)
				return index
			end
			
			
			# Extract the texture from the face for the provided associated material (for either the front or the back of the face)
			def add_image(face, material, is_front_face)
				type,bytes = get_image_bytes(face, material, is_front_face)
				return add_image_node(type,bytes)
			end


			# Helper function to get the texture from a face.
			# warning, if the w in uvw is not 1, this will get a distorted imitation of the original texture.
			# in that case, a todo here is to create a new face, apply the texture, then export.
			# The problem with that is that it changes the model, so an undo is required.

			# Lev : we pass the material separetly here, since we might be processing either the front of the back side material (hence, the boolean 'is_front_face' parameter as well)
			def get_image_bytes(face, material, is_front_face)
				
				texturewriter = Sketchup.create_texture_writer
				
				# get the extension of the texture filename
				#file_name=face.material.texture.filename
				ext = material.texture.filename.split('.').last
				if (ext == nil)
					# Lev: looks like it's possible to have a valid texture object with an epmty filename string (need to investigate this further).
					# So we'll just assume it's a jpeg image, since most image loaders rely on tyhe actual header anyway (as opposed to the file extension).
					ext = "jpg"
				else
					ext.downcase!
				end

				# create a random file in the tmp directory
				n = Random.rand(100000) + 100000
				file =  File.join(Dir.tmpdir() , n.to_s + "."+ ext)
				#puts 'Temporary image file: ' + file
				
				# load the texture, and write it to the file (why does this need to be separate operations?)
				# todo: put out a feature request so unmangled textures can be read straight into memory
				if (face.class == Sketchup::Face)
					texturewriter.load face, is_front_face
					txtWrt = texturewriter.write face, is_front_face, file
				else
					texturewriter.load face
					txtWrt=texturewriter.write face, file
				end

				if (txtWrt != 0) # If failed use default texture instead
					ext="jpg"
					defaultTexture=__dir__+"/Grey_Texture.jpg"
					file=file.split(".").first+"."+ext
					FileUtils.copy(defaultTexture,file)			
					#puts 'Using default texture: ' + file		
				end

				if (ext != 'jpg' && ext!= 'png')
					type="png"
					temp_file=MiniMagick::Image.open(file)
					File.delete(file)
					temp_file.format(type)		
					file=temp_file.path
					ext=file.split(".").last
					ext.downcase!	
				end
				
				# read the file into memory
				bytes = File.binread(file)
				
				# we don't need the file, so delete it
				File.delete(file)
				
				return ext, bytes
			end

		end
	end
end

