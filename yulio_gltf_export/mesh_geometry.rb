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
		class MeshGeometry
			
			def initialize()
				@geometry_positions = []
				@geometry_normals = []
				@geometry_tex_coords = []
				@geometry_tex_positions = []
				@geometry_tex_normals = []
				
				@geometry = {}
				@geometry_tex = {}
				
				@indices = []
				@vertex_count = 0
				#@indices = {}	# [nodeID,materialID] = [idxN,idxN+1,...]
			end
			
			# start a new mesh/attribute collection of indices (per material per group)
			def begin_collection
				@indices = []
			end
			def end_collection
				return @indices
			end
			
			def get_geometry
				return @geometry_positions, @geometry_normals, @geometry_tex_positions, @geometry_tex_normals, @geometry_tex_coords
			end
			def get_vertex_count
				return @vertex_count
			end
			
			def add_geometry(x,y,z,nx,ny,nz,uvx,uvy,hasTexture)
			
				
				index = 0
				if hasTexture
					geo = [x,y,z,nx,ny,nz,uvx,uvy]
					index = @geometry_tex[geo]
					if index == nil
						@vertex_count = @vertex_count  + 1
						index = @geometry_tex.length
						@geometry_tex[geo] = index
						
						@geometry_tex_positions.push(x)
						@geometry_tex_positions.push(y)
						@geometry_tex_positions.push(z)
						@geometry_tex_normals.push(nx)
						@geometry_tex_normals.push(ny)
						@geometry_tex_normals.push(nz)
						@geometry_tex_coords.push(uvx)
						@geometry_tex_coords.push(uvy)
					end
				else
					geo = [x,y,z,nx,ny,nz]
					index = @geometry[geo]
					if index == nil
						@vertex_count = @vertex_count  + 1
						index = @geometry.length
						@geometry[geo] = index
						
						@geometry_positions.push(x)
						@geometry_positions.push(y)
						@geometry_positions.push(z)
						@geometry_normals.push(nx)
						@geometry_normals.push(ny)
						@geometry_normals.push(nz)
					end
				end
				
				@indices.push(index)
				return index
			end

		end
	end
end
