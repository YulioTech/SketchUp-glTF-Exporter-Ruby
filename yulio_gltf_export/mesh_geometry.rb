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
		class MeshData
			def initialize(has_texture)
				@positions = []
				@normals = []
				@uvs = nil
				@indices = []
				#@hash = {} #Use p+n+{uv} based hash table to do early verteex welding o per mesh per material basis. This reduces the size of the gemerated file, but slows the export process down considerably.
				@count = 0

				if (has_texture)
					@uvs = []
				end
			end

			attr_accessor :positions 
			attr_accessor :normals 
			attr_accessor :uvs 
			attr_accessor :indices 
			#attr_accessor :hash 
			attr_accessor :count

			def add_vertex(x,y,z, nx,ny,nz, uvx,uvy)
				
				#geo = [x,y,z,nx,ny,nz,uvx,uvy]

				#index = @hash[geo]

				#if index != nil
				#	#puts "Using existing vertex with index " + index.to_s
				#	return index, false
				#end

				#index = @hash.length
				#@hash[geo] = index

				index = count
				@indices.push(index)

				positions.push(x)
				positions.push(y)
				positions.push(z)

				normals.push(nx)
				normals.push(ny)
				normals.push(nz)

				if (@uvs != nil)
					uvs.push(uvx)
					uvs.push(uvy)
				end

				@count = @count  + 1

				return index, true
			end

			def has_texture
				return (@uvs != nil)
			end 
		end

		class MeshGeometry
			
			def initialize()
				#Mesh data per mesh per material
				@meshes_data = {}
				
				# Total vertex count
				@vertex_count = 0
			end
			
			attr_reader :meshes_data
			attr_reader :vertex_count

			def add_geometry(mesh_id, material_id, x,y,z, nx,ny,nz, uvx,uvy, has_texture)
			
				if @meshes_data[mesh_id] == nil
					@meshes_data[mesh_id] = {}
				end

				if (@meshes_data[mesh_id][material_id] == nil)
					@meshes_data[mesh_id][material_id] = MeshData.new(has_texture)
				end

				index, is_new = @meshes_data[mesh_id][material_id].add_vertex(x,y,z, nx,ny,nz, uvx,uvy)
				#if (is_new)
					@vertex_count = @vertex_count  + 1
				#end

				return index
			end

		end
	end
end
