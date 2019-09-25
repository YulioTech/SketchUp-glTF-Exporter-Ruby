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

require "json"
require 'langhandler'
require 'sketchup'
require 'profiler'

Sketchup.require 'yulio_gltf_export/gltf_nodes'
Sketchup.require 'yulio_gltf_export/gltf_buffers'
Sketchup.require 'yulio_gltf_export/gltf_buffer_views'
Sketchup.require 'yulio_gltf_export/gltf_accessors'
Sketchup.require 'yulio_gltf_export/gltf_meshes'
Sketchup.require 'yulio_gltf_export/gltf_materials'
Sketchup.require 'yulio_gltf_export/gltf_textures'
Sketchup.require 'yulio_gltf_export/gltf_nodes'
Sketchup.require 'yulio_gltf_export/gltf_images'
Sketchup.require 'yulio_gltf_export/mesh_geometry'
Sketchup.require 'yulio_gltf_export/mesh_geometry_collect'
Sketchup.require 'yulio_gltf_export/gltf_cameras'


module Yulio
	module GltfExporter
		#extend self
		
		
		# add item if menu is not already loaded
		unless file_loaded?(__FILE__)
			main_menu = UI.menu("Plugins").add_submenu(TRANSLATE['menuMain'])
			main_menu.add_item(TRANSLATE['menuGltf']) { GltfExport.new.export(false,false,"") }
			main_menu.add_item(TRANSLATE['menuGlb']) { GltfExport.new.export(true,false,"") }
			#main_menu.add_item(TRANSLATE['menuGlb']) { GltfExport.new.exportRecursive("C:\\sketchupStuff") }
			#main_menu.add_item("glTF /w matrix") { GltfExport.new.exportWithMatrix(false,false,"") }
			#main_menu.add_item("glb /w matrix") { GltfExport.new.exportWithMatrix(true,false,"") }
			#main_menu.add_item(TRANSLATE['menuGlbMicrosoft']) { GltfExport.new.export(true,true,"") }
			file_loaded(__FILE__)
		end

		
		class GltfExport
		
			GL_UNSIGNEDBYTE = 5120
			GL_UNSIGNEDSHORT = 5123
			GL_FLOAT = 5126
			
			MINMAX_PRECISION = 16
			
			def initialize()
				@use_matrix = false
				
				@errors = []

				@current_buffer_index = 0
				
				# construct the needed objects
				@buffers = GltfBuffers.new
				@buffer_views = GltfBufferViews.new
				@accessors = GltfAccessors.new
				@images = GltfImages.new(@buffers, @buffer_views, @errors, @current_buffer_index)
				@buffers.add_or_append_buffer(@current_buffer_index, '', 1) #Init an empty buffer to keep the indices consistent (since there might be no textures exported)
				#@current_buffer_index = @current_buffer_index + 1 #Increment the current buffer index whenever we want to create a new separate buffer (e.g. for textures, geometry, etc.)
				@textures = GltfTextures.new(@images)
				@nodes = GltfNodes.new
				@meshes = GltfMeshes.new
				@cameras=GltfCameras.new(@nodes)
				@materials = GltfMaterials.new(@textures)
				@mesh_geometry = MeshGeometry.new
				@mesh_geometry_collect = MeshGeometryCollect.new(@nodes,@meshes,@materials,@mesh_geometry,@use_matrix,@errors)
			end
			
			def exportWithMatrix(is_binary, is_microsoft, filename)
				@use_matrix = true
			end
			
			def exportRecursive(path)
					
				#puts path
				#Dir.chdir(path)
				#puts "next"
				directories = []
				Dir.foreach(path) do |fname|
					next if fname == '.' or fname == '..'
					skpFile = File.join(path,fname)
					if File.directory?(skpFile)
						directories << skpFile
					else
						ext = skpFile.split('.').last
						if ext == "skp"
							puts "#{skpFile}"
							glbFile = skpFile.gsub('.skp','.glb')
							if File.exist?(glbFile)
								# a xaml file exists for this sketchup file, compare the timestamp of each file
								# alternatively could check for the presence of a .skb backup file
								dtGlb = File.mtime(glbFile)
								dtSkp = File.mtime(skpFile)
								if dtSkp > dtGlb
									# skp file has been modified, rebuild the glb
									if Sketchup.open_file skpFile
										GltfExport.new.export(true,false,glbFile)
									end
								end
							else
								if Sketchup.open_file skpFile
									GltfExport.new.export(true,false,glbFile)
								end
							end
						end
					end
				end
				directories.each do |dir|
					puts dir
					exportRecursive(dir)
				end
			end
			
			def count_faces(entity, faces)
				faces += 1 if entity.is_a?(Sketchup::Face)
				if entity.is_a?(Sketchup::ComponentInstance) || entity.is_a?(Sketchup::Group)
					entity.definition.entities.each do |ent|
						faces = count_faces(ent, faces)
					end
				end
				return faces
			end
			  
			def get_scene_face_count(model)
				#model = Sketchup.active_model
				face_count = 0

				model.entities.each { |ent| face_count = count_faces(ent, face_count) }

				return face_count
			end

			def export(is_binary, is_microsoft, filename)
				@is_microsoft = is_microsoft
				@nodes.set_microsoft_mode(is_microsoft)
				@meshes.set_microsoft_mode(is_microsoft)
				@materials.set_microsoft_mode(is_microsoft)
				@mesh_geometry_collect.set_microsoft_mode(is_microsoft)
				
				#SKETCHUP_CONSOLE.show
				
				model = Sketchup.active_model
				if model == nil
					# Apparently this condition can occur on a Mac
					return
				end
				#puts 'WebGL (gltf) Export started'
				
				filePrompt = false
				
				if filename == ""
				
					filePrompt = true
					model_filename = File.basename(model.path)
					if model_filename != ""
						filename = model.path.split(".")[0]
					else
						#UI.messagebox(TRANSLATE["saveModel"], MB_OK)
						filename = TRANSLATE["untitled"];
					end
					
					if(is_binary)
						filename = filename + '.glb'
					else
						filename = filename + '.gltf'
					end
					
					# now show the save-as dialog for the user to change the exported filename
					filename = UI.savepanel(nil, model.path, filename)
					# it would really have been nice if the user could then select the model type from savepanel.. :(
					
					if filename == nil
						return	# user cancelled the export
					end
				end
				
				begin
			
					#Test code ->
					enable_profiler = false
					if enable_profiler
					mode = "wb"
					file = File.open("e:/Downloads/glTF_exporter_profile.txt", mode)
					Profiler__::start_profile
					puts "Profiling started at " + Time.now.getutc.to_s + " for " + filename
					file.write("Profiling started at " + Time.now.getutc.to_s + " for " + filename + "\n")
					end
					#<-

					#Test code ->
					starting = Process.clock_gettime(Process::CLOCK_MONOTONIC)
					#<-

					matrix = get_default_matrix()
				
					# Lev: get the scene's total face count (might be used later to limit exporting to moderately sized scenes only)
					#face_count = get_scene_face_count(model)
					#puts 'Scene face count: ' + face_count.to_s

					#puts 'Collating geometry and materials'
					root_node_id = @nodes.add_node('root', matrix, @use_matrix)
					@mesh_geometry_collect.collate_geometry(root_node_id, matrix, model.active_entities, nil, nil)
					
					#puts 'Generating Buffers'
					index_count = prepare_buffers_for_writing()
					
					#puts 'Writing to file'
					@cameras.add_camera_nodes
					
					asset = {
						"version" => "2.0",
						"minVersion" => "2.0", #Min version required to load the file (optional field)
						"generator" => "Sketchup glTF Exporter v2.2.2 by Yulio Technogies Inc."
					}
					
					# set the glTF copyright field, use model.description
					if model.description != nil
						if model.description != ""
							asset["copyright"] = model.description
						end
					end
					
					scenes =
					[
						{
						"nodes" => [0]
						}
					]
					
					#Samplers are not used in the current implementation, so no need to add them
					
					# this hash will be exported as the body of json used in the glTF file
					export = {}
					export["asset"] = asset
					export["scene"] = 0
					export["scenes"] = scenes
					export["nodes"] = @nodes.nodes
					#glTF spec doesn't allow for an empty camera list (or any empty list for that matter) => the validator will throw an error in such a case
					if (@cameras.cameras.length > 0)
						export["cameras"] = @cameras.cameras
					end
					export["materials"] = @materials.materials
					
					if (@images.images.length > 0)
						export["images"] = @images.images
					end

					if (@textures.textures.length > 0)
						export["textures"] = @textures.textures
						#All textures are using the default 0-indexed sampler in the current implementation
						samplers =
						[
							{
							}
						]
						export["samplers"] = samplers
					end
					
					export["meshes"] = @meshes.meshes
					export["accessors"] = @accessors.accessors
					export["bufferViews"] = @buffer_views.buffer_views
					
					if (is_binary)
						write_glb(filename, export)
					else
						write_gltf(filename, export)
					end
					
					#Test code ->
					ending = Process.clock_gettime(Process::CLOCK_MONOTONIC)
					elapsed = ending - starting
					puts "glTF export to \'" + filename + "\' took " + elapsed.to_s + " seconds"
					#return
					#<-

					#Test code ->
					if enable_profiler
					puts "Profiling stopped at " + Time.now.getutc.to_s
					file.write("Profiling stopped at " + Time.now.getutc.to_s + "\n----------------------------------------------------------------\n")
					Profiler__::stop_profile
					#Profiler__::print_profile($stderr)
					Profiler__::print_profile(file)

					#puts file.read
					file.close()
					end
					#<-
				
					summary = TRANSLATE["exportSummary"]
					summary << "\n"
					
					summary << "\n " + TRANSLATE["images"] + ": " + (export["images"] != nil ? export["images"].length.to_s : 0.to_s)
					summary << "\n " + TRANSLATE["textures"] + ": " + (export["textures"] != nil ? export["textures"].length.to_s : 0.to_s)
					summary << "\n " + TRANSLATE["materials"] + ": " + export["materials"].length.to_s
					
					summary << "\n " + TRANSLATE["nodes"] + ": " + export["nodes"].length.to_s
					summary << "\n " + TRANSLATE["meshes"] + ": " + export["meshes"].length.to_s
					summary << "\n " + TRANSLATE["cameras"] + ": " + (export["cameras"] != nil ? export["cameras"].length.to_s : 0.to_s)
					summary << "\n " + TRANSLATE["accessors"] + ": " + export["accessors"].length.to_s
					summary << "\n " + TRANSLATE["bufferViews"] + ": " + export["bufferViews"].length.to_s
					summary << "\n " + TRANSLATE["buffers"] + ": " + export["buffers"].length.to_s
					summary << "\n"
					summary << "\n" + TRANSLATE["triangles"] + ": " + (index_count/3).to_s
					summary << "\n" + TRANSLATE["vertices"] + ": " + (@mesh_geometry.vertex_count).to_s
					summary << "\nPath: "+ filename
					summary << "\n"
					@errors.each { |error|
						summary << "\n" + error
					}
					if filePrompt
						UI.messagebox(summary, MB_MULTILINE, TRANSLATE["title"])
					end
					return summary
					
				rescue => e
					# something went wrong, log the error so the user can give feedback to me
					#puts e.backtrace
					backtrace = "\n\t#{e.backtrace.join("\n\t")}"
					msg = e.inspect << "\n" << backtrace
					if filePrompt
						UI.messagebox(msg, MB_MULTILINE, TRANSLATE["title"])
					end
					return msg

				end
			end

			
			def write_gltf(filename, export)
				export["buffers"] = @buffers.encode_buffers()
				json = JSON.pretty_generate(export)
				file = File.open(filename, "wb")
				file.write(json)
				file.close()
			end
			
			#total length:3345884
			#buffer length:3216464
			#json length:129392

			def write_glb(filename, export)
				buffers, bins = @buffers.get_buffers()
				export["buffers"] = buffers
				
				json = export.to_json
				json_len = json.bytes.length	# use bytes.length to get the underlying size in bytes (json.length is the length of the string in characters)
				
				while(json_len % 4 != 0)
					json = json << ' '
					json_len = json_len + 1
				end

				bins_length = 0
				bins.each { |bin|
					while(bin.length % 4 != 0)
						bin = bin << 0
					end
					bins_length = bins_length + bin.length
				}
				
				header = 0x46546C67
				jsonContent = 0x4E4F534A
				binaryBuffer = 0x004E4942
			
				headerArray = []
				headerArray.push(header)
				headerArray.push(2)
				headerArray.push(bins_length + json_len + 28)
				
				headerArray.push(json_len)
				headerArray.push(jsonContent)
				header = headerArray.pack('V*')
				
				bufferArray = []
				bufferArray.push(bins_length)
				bufferArray.push(binaryBuffer)
				buffer = bufferArray.pack('V*')
				
				#puts 'total length:' + (bin.length + json_len + 28).to_s
				#puts 'buffer length:' + bin.length.to_s
				#puts 'json length:' + json_len.to_s
				#puts 'json bytes:' + json.bytes.length.to_s
				
				file = File.open(filename, "wb")
				file.write(header)
				file.write(json)
				
				file.write(buffer)
				bins.each { |bin|
					file.write(bin)
				}
				file.close()
			end
			
			
			def get_default_matrix
				trans = Geom::Transformation.new
				
				# rotate the model to bring it in line with OpenGL axis representations
				trans = trans * Geom::Transformation.rotation([0,0,0], [0,1,0], Math::PI)
				trans = trans * Geom::Transformation.rotation([0,0,0], [1,0,0], -Math::PI/2.0)
				trans = trans * Geom::Transformation.rotation([0,0,0], [0,0,1], Math::PI)
				
				# scale the model to metres
				trans = trans * Geom::Transformation.scaling(0.0254,0.0254,0.0254)
				return trans
			end

			# check if any index value requires a 32-bit index array instead of a 16-bit index arrays
			def get_index_size(indices)
				index_size = 2
				#if @is_microsoft
				#	index_size = 2
				#end
				indices.each { |i|
					if (i > 65535)
						return 4
					end
					#if (i > 255)
					#	index_size = 2
					#end
				}
				return index_size
			end
			
			
			def add_buffer_view_for_indices(indices, buffer_index)
				index_size = get_index_size(indices)	
				if index_size == 4
					packed = indices.pack 'V*'	# 32-bit indexes
					offset = @buffers.add_or_append_buffer(buffer_index, packed, 4)
					indexType = 5125	# 32-bit ulong
					byte_count = 4
				elsif index_size == 2
					packed = indices.pack 'v*'	# 16-bit
					offset = @buffers.add_or_append_buffer(buffer_index, packed, 2)	# was 2
					indexType = 5123	# 16-bit ushort
					byte_count = 2
				elsif index_size == 1
					packed = indices.pack 'C*'	# 8-bit
					offset = @buffers.add_or_append_buffer(buffer_index, packed, 1)	# 1 byte alignment?
					indexType = 5121	# 8-bit ubyte
					byte_count = 1
				end
				
				buffer_view_index = @buffer_views.add_buffer_view(buffer_index, offset, packed.length, 34963, nil)
				return buffer_view_index, indexType, byte_count
			end
			
			
			
			
			def pack_buffer(entries, glType, strideBytes, buffer_index = 0)
				if glType == GL_FLOAT
					packed = entries.pack 'e*'	# e = single precision, little endian
					buffer_offset = @buffers.add_or_append_buffer(buffer_index, packed, strideBytes)
					buffer_view = @buffer_views.add_buffer_view(buffer_index, buffer_offset, packed.length, 34962, strideBytes)
					return buffer_view
				end
				
				if glType == GL_UNSIGNEDBYTE
					# todo, this needs proper implementation
					byte_array = []
					entries.each { |v|
						if v > 1.0
							v = 1.0
						end
						if v < 0.0
							v = 0.0
						end
						b = (v * 255.0).to_i
						byte_array.push(b)
					}
					packed = byte_array.pack 'C*'	# pack as bytes
					buffer_offset = @buffers.add_or_append_buffer(buffer_index, packed, 4)
					buffer_view = @buffer_views.add_buffer_view(buffer_index, buffer_offset, packed.length, 34962, strideBytes)
					return buffer_view
				end
			end
			
			
			
			def prepare_buffers_for_writing()
				#puts 'Preparing all the buffers, bufferviews, accessors, etc. to be written to the output file.'

				index_count = 0

				@mesh_geometry.meshes_data.each_key { |mesh_id|
					@mesh_geometry.meshes_data[mesh_id].each_key { |material_id|
						mesh_data = @mesh_geometry.meshes_data[mesh_id][material_id]
						position_buffer_view_index = pack_buffer(mesh_data.positions, GL_FLOAT, 12, @current_buffer_index)
						normals_buffer_view_index = pack_buffer(mesh_data.normals, GL_FLOAT, 12, @current_buffer_index)

						minp,maxp = write_min_max_vec3(mesh_data.positions)

						positions_accessor = @accessors.add_accessor(position_buffer_view_index,0,GL_FLOAT,mesh_data.positions.length / 3,"VEC3",minp,maxp)
						normals_accessor = @accessors.add_accessor(normals_buffer_view_index,0,GL_FLOAT,mesh_data.normals.length / 3,"VEC3",nil,nil)

						if (mesh_data.has_texture)
							uvs_buffer_view_index = pack_buffer(mesh_data.uvs, GL_FLOAT, 8, @current_buffer_index)
							#mint,maxt = write_min_max_vec2(mesh_data.uvs)
							uvs_accessor = @accessors.add_accessor(uvs_buffer_view_index,0,GL_FLOAT,mesh_data.uvs.length / 2,"VEC2",nil,nil)
						end
						#@current_buffer_index = @current_buffer_index + 1

						index_count = index_count + mesh_data.indices.length

						#puts "Adding buffer view for " + mesh_data.indices.length.to_s + " indices for mesh with ID " + mesh_id.to_s + " and material ID " + material_id.to_s
						buffer_view_index,index_type,byte_count = add_buffer_view_for_indices(mesh_data.indices, @current_buffer_index)

						if (mesh_data.has_texture)
							iAccess = @accessors.add_accessor(buffer_view_index, 0 * byte_count, index_type, mesh_data.indices.size, "SCALAR", nil, nil)
							@meshes.add_mesh_primitive(mesh_id, positions_accessor, normals_accessor, uvs_accessor, iAccess, material_id)
						else
							iAccess = @accessors.add_accessor(buffer_view_index, 0 * byte_count, index_type, mesh_data.indices.size, "SCALAR", nil, nil)
							@meshes.add_mesh_primitive(mesh_id, positions_accessor, normals_accessor, nil, iAccess, material_id)
						end

					}
				}

				return index_count
			end

			
			# the glTF validator is very fussy about the minimum and maximum values, so round up/down as appropriate.
			def floor2(n,exp)
				multiplier = 10 ** exp
				((n * multiplier).floor).to_f/multiplier.to_f
			end
			def ceil2(n,exp)
				multiplier = 10 ** exp
				((n * multiplier).ceil).to_f/multiplier.to_f
			end
			def round_down(v,digits)
				dig = 0.1 ** digits
				return floor2(v-dig,digits)
			end
			
			def round_up(v,digits)
				dig = 0.1 ** digits
				return ceil2(v+dig,digits)
			end
			
			# returns the minimum and maximum values in an array according the the offset, step, and precision required
			def minmax(array,offset,step,precis)
				min_x = 1.0e10
				max_x = -1.0e10
				i = offset
				while i < array.length
					x = array[i].to_f
					if x < min_x
						min_x = x
						#puts min_x
					end
					if x > max_x
						max_x = x
					end
					i = i + step
				end
				return min_x, max_x
				#return round_down(min_x,precis),round_up(max_x,precis)
			end
			
			# for the positions and normals accessors, get the minimum and maximum values
			def write_min_max_vec3(positions)
				min_x,max_x = minmax(positions,0,3,MINMAX_PRECISION)
				min_y,max_y = minmax(positions,1,3,MINMAX_PRECISION)
				min_z,max_z = minmax(positions,2,3,MINMAX_PRECISION)
				return [min_x,min_y,min_z],[max_x,max_y,max_z]
			end

			# for the texture (UV) accessors, get the minimum and maximum values
			def write_min_max_vec2(uv)
				minU,maxU = minmax(uv,0,2,MINMAX_PRECISION)
				minV,maxV = minmax(uv,1,2,MINMAX_PRECISION)
				return [minU,minV],[maxU,maxV]
			end
			
			def write_min_max_vec2_normalized_byte(uv)
				i = 0
				max_u = 0
				max_v = 0
				min_u = 255
				min_v = 255
				
				while i < uv.length
					uf = uv[i]
					vf = uv[i+1]
					if uf > 1.0
						uf = 1.0
					end
					if uf < 0.0
						uf = 0.0
					end
					if vf > 1.0
						vf= 1.0
					end
					if vf < 0.0
						vf = 0.0
					end
					u = (uf * 255.0).to_i
					v = (vf * 255.0).to_i
					if u > max_u
						max_u = u
					end
					if v > max_v
						max_v = v
					end
					if u < min_u
						min_u = u
					end
					if v < min_v
						min_v = v
					end
					i = i + 2
				end
				if min_u < 0
					min_u = 0
				end
				if max_u > 255
					max_u = 255
				end
				if min_v < 0
					min_v = 0
				end
				if max_v > 255
					max_v = 255
				end
				return [min_u,min_v], [max_u,max_v]
			end
			
			# not used
			def write_min_max_vec1(integers)
				min_x = 999999999
				max_x = -999999999
				i = 0
				while i < integers.length
					x = integers[i]
					if x < min_x
						min_x = x
					end
					if x > max_x
						max_x = x
					end
					i = i + 1
				end
				return [min_x],[max_x]
			end
			

		end
	end
end