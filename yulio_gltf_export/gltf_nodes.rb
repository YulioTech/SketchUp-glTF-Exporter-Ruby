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
	
		class GltfNodes
			
			def initialize
				@nodes = []
				@idGen = GltfId.new
				#@is_microsoft = false
			end
			
			def set_microsoft_mode(is_microsoft)
				#@is_microsoft = is_microsoft
			end
			
			def add_node(name, matrix, use_matrix)
			
				# node names are for supporting Microsoft Paint 3D, which doesn't follow the glTF 2.0 Specification
				if name == ''
					name = nil
				end
				#if @is_microsoft == true
				#	if name == nil
				#		name = "node" + @idGen.get_next_id()
				#	end
				#end
				
				node =
				{
				}
				if name != nil
					node["name"] = name
				end
				if use_matrix
					mtx = matrix.to_a
					# check if it is the identity matrix
					if mtx[ 0] == 1 && mtx[ 1] == 0 && mtx[ 2] == 0 && mtx[ 3] == 0 &&
					   mtx[ 4] == 0 && mtx[ 5] == 1 && mtx[ 6] == 0 && mtx[ 7] == 0 &&
						 mtx[ 8] == 0 && mtx[ 9] == 0 && mtx[10] == 1 && mtx[11] == 0 &&
						 mtx[12] == 0 && mtx[13] == 0 && mtx[14] == 0 && mtx[15] == 1
						# do nothing
					else
						node["matrix"] = mtx
					end
				end
				
				index = @nodes.length
				@nodes.push(node)
				return index
			end
			
			
			def add_mesh(node_id, mesh_id)
				@nodes[node_id]["mesh"] = mesh_id
			end
			
			def add_child(node_id, child_node_id)
				node = @nodes[node_id]
				if node["children"] == nil
					node["children"] = []
				end
				node["children"].push(child_node_id)
			end
			
			def get_nodes
				return @nodes
			end
			
		end
	end
end
