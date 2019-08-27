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

require 'sketchup'

module Yulio
	module GltfExporter

		class MeshGeometryCollect
		
			def initialize(nodes,meshes,materials,mesh_geometry,use_matrix,errors)
				@warning = false
				@errors = errors
				
				@nodes = nodes
				@meshes = meshes
				@materials = materials
				@mesh_geometry = mesh_geometry
				
				@use_matrix = use_matrix
				@mesh_per_material = false
			end
			

#Something for @danrathbun or actually anyone with some elementary ruby programming experience in Sketchup.
			
#Seems like a simple question, I want to know how to get the material for a face.
# Well duh! that is face.material right? but it is not so simple....
# The face could have a nil material, but be part of a group that is painted with a material.
# In my glTF exporter I would read the face material, and if null, use the group material.
# if the group material was also nil, the face would be exported with the default material.
# Which is a problem, because a face could be embedded within a group, within a component, within a group, etc.

# So, I'm trying to come up with a simple function to recurse through the parent objects to find the face material...
# But I'm becoming unstuck when it comes to determining what is the parent of a component.
			
			def find_entity_material_face(e)
				if e.is_a?(Sketchup::Face)
					if e.material != nil
						return e
					end
					return find_entity_material_face(e.parent)
				end
				
				if e.is_a?(Sketchup::ComponentDefinition)
					if e.material != nil
						return e
					end
					return find_entity_material_face(e.parent)
				end
				
				if e.is_a?(Sketchup::ComponentInstance)
					if e.material != nil
						return e
					end
					if e.definition.material != nil
						return e.definition
					end
					temp = find_entity_material_face(e.parent)
					if temp == nil
						temp = find_entity_material_face(e.definition)
					end
					return temp
				end

				if e.is_a?(Sketchup::Group)
					if e.material != nil
						return e
					end
					return find_entity_material_face(e.parent)
				end
				
				#debug what I'm traversing
				puts e.class
				
				# class might be a model
				return nil
			end
			
			
			def set_microsoft_mode(mesh_per_material)
				@mesh_per_material = mesh_per_material
			end
			
			
			# # return the array of all mesh IDs generated during the model export
			# def get_mesh_ids()
			# 	mesh_ids = []
			# 	@indicies_per_material_per_mesh.each_key { |mesh_id|
			# 		mesh_ids.push(mesh_id)
			# 	}
			# 	return mesh_ids
			# end
			
			
			# # returns the array of materials within the given mesh
			# def get_mesh_materials(mesh_id)
			# 	materials = []
			# 	@indicies_per_material_per_mesh[mesh_id].each_key { |material_id|
			# 		materials.push(material_id)
			# 	}
			# 	return materials
			# end
			
			
			# # returns the array of indexes per mesh-material
			# def get_mesh_indices(mesh_id, material_id)
			# 	return @indicies_per_material_per_mesh[mesh_id][material_id]
			# end
			
			
			# # Get the stored flag for if the mesh is textured
			# def is_mesh_textured(mesh_id, material_id)
			# 	return @mesh_textured[mesh_id][material_id]
			# end
			
			
			# check if a material has a texture, returns true if it has
			def material_has_texture(group, face)
				materialFace = find_entity_material_face(face)
				if materialFace == nil
					return false
				end
				if materialFace.material == nil
					return false
				end
				if materialFace.material.texture != nil
					return true
				end
				return false
				
				#if face.material == nil
				#	if group == nil
				#		return false
				#	end
				#	if group.material == nil
				#		return false
				#	end
				#	if group.material.texture != nil
				#		return true
				#	end
				#	return false
				#end
				#if face.material.texture != nil
				#	return true
				#end
				#return false
			end
			
			def determinant(a)
				determ = a[0*4+0] * a[1*4+1] * a[2*4+2] + a[0*4+1] * a[1*4+2] * a[2*4+0] + a[0*4+2] * a[1*4+0] * a[2*4+1] - a[0*4+2] * a[1*4+1] * a[2*4+0] - a[0*4+1] * a[1*4+0] * a[2*4+2] - a[0*4+0] * a[1*4+2] * a[2*4+1]
				return determ
			end
			
			# Recursively scan through the sketchup model, get every face for export, group by material
			def collate_geometry(nodeId, transformation, entities, group, group_with_material)
				
				face_by_material = {}
				group_with_mat = group_with_material

				entities.each { |e|
				#for e in entities #Lev: 'for' is marginally slower than 'each'
					#next if e.deleted? == true
					#next if e.valid? == false
					#next if e.hidden? == true # skip this entity if it is hidden
					
					#Lev: commented out for performance reasons ->
					if (e.hidden? == true || e.deleted? == true || e.valid? == false)
						next
					end

					# Do not export faces/groups/components on hidden layers
					if (e.layer != nil && e.layer.visible? == false)
						next
					end
					#<-
					
					materialNotNil = e.material != nil #Lev: to optimize the object checks against nil (seems like they are expensive in Ruby)

					if (e.class == Sketchup::Group)
						#puts "e.class == Sketchup::Group"
						group_node_id = @nodes.add_node(e.name, e.transformation, @use_matrix)
						@nodes.add_child(nodeId, group_node_id)
						trn = transformation * e.transformation
						if @use_matrix
							trn = e.transformation
						end
						if materialNotNil
							collate_geometry(group_node_id, trn, e.entities, e, e)
						else
							collate_geometry(group_node_id, trn, e.entities, e, group_with_material)
						end
					elsif (e.class == Sketchup::ComponentInstance)
						#puts "e.class == Sketchup::ComponentInstance"
						group_node_id = @nodes.add_node(e.definition.name, e.transformation, @use_matrix)
						@nodes.add_child(nodeId, group_node_id)
						trn = transformation * e.transformation
						if @use_matrix
							trn = e.transformation
						end
						if materialNotNil
							group_with_mat = e
							collate_geometry(group_node_id, trn, e.definition.entities, e, e)
						else
							collate_geometry(group_node_id, trn, e.definition.entities, e, group_with_material)
						end
					elsif (e.class == Sketchup::Face)
						face = e
						faceWithMaterial = face
						if !materialNotNil
							if group_with_mat != nil
								if group_with_mat.material != nil
									faceWithMaterial = group_with_mat
								end
							end
						else
							if (face.material.alpha == 0.0)
								# Special case: a material with alpha of zero is sometimes used for blending groups together... don't export it.
								next
							end

							# Lev: a hack to filter out CET exported geometry representing the insides of objects. Such geometry has a double-sided materials with certain properties:
							# Front faces will have a material named "Color_#xxxxxx", where xxxxxx is a hexadecimal RGB value.
							# Back faces will have a material name staring the "Transparent" and the opacity value of 0.0.
							# Note, that skipping all of the faces of a mesh will likely produce empty parent nodes in the resulting glTF file.
							# It's not a big deal (this is not classified as an error in the glTF spec), but we should address it at some point (likely in the common glTF exporter back-end implementation).
							if (face.back_material != nil)
								# Put the easiest to evaluate conditions on the left for performance reasons
								if (#face.back_material.alpha == 0.0 &&
									face.back_material.name.match(/^Transparent/) && 
									face.material.name.match(/^Color_#([a-fA-F0-9]{6})/))
									#puts "CET face match found: " + face.material.name 
									next
								end
							end
						end
						
						material_id = @materials.add_material(faceWithMaterial)
						
						#if face.material != nil
						#	material_id = @materials.add_material(face)
						#else
						#	# material is nil, check if the group or component has a material
						#	if group.class == Sketchup::ComponentInstance
						#		puts 'Face is inside a component instance'
						#		material_id = @materials.add_material(group.definition)
						#	else
						#		# use the group material if it has one
						#		puts 'Face is inside a group'
						#		material_id = @materials.add_material(group)
						#	end
						#end
					
					
						faces = face_by_material[material_id]
						if faces == nil
							faces = []
							face_by_material[material_id] = faces
						end
						faces.push(face)
					end
				}
				#end
				
				if (face_by_material.length == 0)
					return
				end
				
				#if @mesh_per_material == false
				mesh_id = @meshes.add_mesh(nil)
				@nodes.add_mesh(nodeId, mesh_id)
				#puts "Added a mesh with ID " + mesh_id.to_s + " and a node with ID " + nodeId.to_s
				#end
				
				face_by_material.each_key { |material_id|
				
					# mesh per material is required for the current buggy version of Microsoft Paint 3D
					# todo: remove this once Microsoft gets out a fix.
					
					#if @mesh_per_material == true
					#	sub_node_id = @nodes.add_node(nil, Geom::Transformation.new, @use_matrix)
					#	@nodes.add_child(nodeId, sub_node_id)
					#	mesh_id = @meshes.add_mesh(nil)
					#	@nodes.add_mesh(sub_node_id, mesh_id)
					#end
				
					faces = face_by_material[material_id]
							
							
					has_texture = false
					if (faces[0].material != nil && faces[0].material.texture != nil)
						has_texture = true
					end
					if (has_texture == false)
						if (group_with_mat != nil && group_with_mat.material != nil && group_with_mat.material.texture != nil)
							has_texture = true
						end
					end
						
					kPoints = 0
					kUVQFront = 1
					kUVQBack = 2
					kNormals = 4
					flags = kPoints | kUVQFront | kNormals
					faces.each { |face|
						mesh = face.mesh(flags) 
						
					 	det = 1.0
					 	if (@use_matrix == false)
					 		mesh.transform! transformation
					 		a = transformation.to_a
					 		det = determinant(a)
					 	end
						
					 	#has_texture = material_has_texture(group,face)

						number_of_polygons = mesh.count_polygons
						#puts "Mesh has " + number_of_polygons.to_s + " polygons"
					 	for i in (1..number_of_polygons)
					 		polygon = mesh.polygon_at(i)
					 		idx0 = polygon[0].abs
					 		idx1 = polygon[1].abs
					 		idx2 = polygon[2].abs

					 		p0 = mesh.point_at(idx0)
					 		p1 = mesh.point_at(idx1)
					 		p2 = mesh.point_at(idx2)
						
					 		n0 = mesh.normal_at(idx0)
					 		n1 = mesh.normal_at(idx1)
					 		n2 = mesh.normal_at(idx2)
						
							#if(det < 0.0)
							#	n0 = Geom::Vector3d.new(-n0.x,-n0.y,-n0.z)
							#	n1 = Geom::Vector3d.new(-n1.x,-n1.y,-n1.z)
							#	n2 = Geom::Vector3d.new(-n2.x,-n2.y,-n2.z)
							#end
							
					 		uvw0 = mesh.uv_at(idx0,true)
					 		uvw1 = mesh.uv_at(idx1,true)
					 		uvw2 = mesh.uv_at(idx2,true)
							
							if @isWarning == false && (uvw0[2] != 1.0 || uvw1[2] != 1.0 || uvw2[2] != 1.0)
								@errors.push(TRANSLATE("badUVW"))
								@isWarning = true
							end
							
							if (det < 0.0)
								# reverse the winding order
								idx1 = @mesh_geometry.add_geometry(mesh_id, material_id, p1.x,p1.y,p1.z, n1.x,n1.y,n1.z, uvw1[0], 1.0-uvw1[1], has_texture)
								idx0 = @mesh_geometry.add_geometry(mesh_id, material_id, p0.x,p0.y,p0.z, n0.x,n0.y,n0.z, uvw0[0], 1.0-uvw0[1], has_texture)
								idx2 = @mesh_geometry.add_geometry(mesh_id, material_id, p2.x,p2.y,p2.z, n2.x,n2.y,n2.z, uvw2[0], 1.0-uvw2[1], has_texture)
							else
								idx0 = @mesh_geometry.add_geometry(mesh_id, material_id, p0.x,p0.y,p0.z, n0.x,n0.y,n0.z, uvw0[0], 1.0-uvw0[1], has_texture)
								idx1 = @mesh_geometry.add_geometry(mesh_id, material_id, p1.x,p1.y,p1.z, n1.x,n1.y,n1.z, uvw1[0], 1.0-uvw1[1], has_texture)
								idx2 = @mesh_geometry.add_geometry(mesh_id, material_id, p2.x,p2.y,p2.z, n2.x,n2.y,n2.z, uvw2[0], 1.0-uvw2[1], has_texture)
							end
							
					 	end
					}
					
					#Test code
					#puts "Indices is " + @mesh_geometry.meshes_data[mesh_id][material_id].indices.to_s
					
					# all_geometry = @mesh_geometry.meshes_data
					# puts "Mesh with ID " + mesh_id.to_s + " and material ID " + material_id.to_s + " has p: " + all_geometry[mesh_id][material_id].positions.length.to_s \
					# 	+ "; n: " + all_geometry[mesh_id][material_id].normals.length.to_s \
					# 	#+ "; uvs: " + all_geometry[mesh_id][material_id].uvs.length.to_s \
					# 	+ "; h: " + all_geometry[mesh_id][material_id].hash.length.to_s \
					# 	+ "; c: " + all_geometry[mesh_id][material_id].count.to_s \
					# 	+ "; indices length: " + all_geometry[mesh_id][material_id].indices.length.to_s
				}
			end
		end
	end
end
