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

Sketchup.require 'yulio_gltf_export/gltf_id'

module Yulio
	module GltfExporter
	
		class GltfMeshes
			
			def initialize
				@meshes = []
				@id_gen = GltfId.new
				#@is_microsoft = false
				#@id_primitive = GltfId.new
			end
			
			def set_microsoft_mode(is_microsoft)
				#@is_microsoft = is_microsoft
			end
			
			# add_mesh is called during Geometry collection
			def add_mesh(name)
				#if name == nil
				
				#if @is_microsoft
				#	name = "mesh" + @id_gen.get_next_id()
				#end
				#end
				
				mesh =
				{
					"primitives" =>
					[
					]
				}
				if name != nil
					mesh["name"] = name
				end
				
				index = @meshes.length
				@meshes.push(mesh)
				return index
			end
			
			# add_mesh_primitive is called during final buffer consolidation
			def add_mesh_primitive(mesh_id, position_accessor_id, normal_accessor_id, tex_coord_accessor_id, indices_accessor_id, material_id)
				primitive =
				{
					"attributes" => 
					{
						"POSITION" => position_accessor_id,
						"NORMAL" => normal_accessor_id
					},
					"indices" => indices_accessor_id,
					"mode" => 4,
					"material" => material_id
				}
				if tex_coord_accessor_id != nil
					primitive["attributes"]["TEXCOORD_0"] = tex_coord_accessor_id
				end
				@meshes[mesh_id]["primitives"].push(primitive)
			end
			
			def get_meshes
				return @meshes
			end

		end
	end
end
