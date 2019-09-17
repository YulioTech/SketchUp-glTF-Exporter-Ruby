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
	
		class GltfMaterials
			
			def initialize(textures)
				@textures = textures
				@materials = []
				@materials_hash = {}
				#@is_microsoft = false
				@id_gen = GltfId.new
				@defaultMaterial = -1
			end
			
			attr_reader :materials 

			def set_microsoft_mode(is_microsoft)
				#@is_microsoft = is_microsoft
			end
			
			def add_material_node(name,r,g,b,a,metallic_factor,roughness_factor,double_sided,texture_id)
				# Paint3D requires a material name even though it is not required according to glTF spec...
				#name = nil
				#if @is_microsoft
				#	#if name == nil
				#	name = 'mat' + @id_gen.get_next_id()
				#	#end
				#end
				
				# Lev: this is wrong (it's tonemapping, not sRGB -> linear conversion) and unnecessary (the color in SU is in linear space), and results in overly dark colors in the final renderes.
				# ====>
				# # convert from sRGB space to Linear space
				# r = r ** (2.2)
				# g = g ** (2.2)
				# b = b ** (2.2)
				# <====
				
				#puts "Adding material: " + name
				#puts "r:" + r.to_s + " g:" + g.to_s + " b:" + b.to_s + " a:" + a.to_s 
				#puts name
				
				
				material =
				{
					#"name" => name,
					"pbrMetallicRoughness" =>
					{
						"baseColorFactor" => [ r.round(4),g.round(4),b.round(4),a.round(4) ]
					},
				}

				if texture_id != nil
					# Lev: in SU when a texture is used in a material, its pixel values (including the alpha) are multipled by the base color values (thus providing the mechanism for linear RGBA blending between both).
					# This matches nicely with the way the glTF 2.0 spec (https://github.com/KhronosGroup/glTF/tree/master/specification/2.0) defines the similar scenario:
					# "If both factors and textures are present the factor value acts as a linear multiplier for the corresponding texture values."
					# So the behavior below has to be the one of adding "baseColorTexture" property to the "pbrMetallicRoughness", rather than overwriting the "baseColorFactor" added above.
					material["pbrMetallicRoughness"]["baseColorTexture"] = { "index" => texture_id } 
					
					#if @is_microsoft == true
						# metallicRoughnessTexture is currently required by Paint3D.
						# As we dont have a texture to use, repeat the same texture.
						# todo: Fix this once Microsoft releases a version of Paint3D with this bug fixed!
						#metal_texture_id = texture_id
						
						# Have to repeat the same texture because there is no api to create an image on the fly
						# and Microsoft Paint 3D does not accept any metallicRoughnessTexture image with
						# dimensions different from the baseColorTexture
						
						#metal_texture_id = @textures.add_metallic_texture()
						#metallicRoughnessTexture = { "index" => metal_texture_id }
						#material["pbrMetallicRoughness"]["metallicRoughnessTexture"] = metallicRoughnessTexture
					#end
				end
				
				emissiveR = 0.0
				emissiveG = 0.0
				emissiveB = 0.0
				
				if name != nil
					material["name"] = name
					# metallic=0.1
					# doubleSided=1.0
					# 0123456789012345678901234
					begin
						if name.include? 'metallic='
							i = name.index('metallic=') + 9
							met = name[i,3]
							metallic_factor = met.to_f
						end
					rescue
					end
					
					begin
						if name.include? 'roughness='
							i = name.index('roughness=') + 10
							rough = name[i,3]
							roughness_factor = rough.to_f
						end
					rescue
					end
					
					if name.include? 'doubleSided=true'
						double_sided = true
					end
					if name.include? 'doubleSided=false'
						double_sided = false
					end
					
					if name.include? 'emissive='
						i = name.index('emissive=') + 9
						begin
							emissiveR = name[i,3].to_f
							emissiveG = name[i+4,3].to_f
							emissiveB = name[i+8,3].to_f
						rescue
						end
					end
				end
				
				if not (emissiveR == 0.0 && emissiveG == 0.0 && emissiveB == 0.0)
					emissive_factor = [emissiveR,emissiveG,emissiveB]
					material["emissiveFactor"] = emissive_factor
				end
				
				# the default metallicity is 1 (metal)
				if metallic_factor < 1
					material["pbrMetallicRoughness"]["metallicFactor"] = metallic_factor
				end
				# the default roughness is 1
				if roughness_factor < 1
					material["pbrMetallicRoughness"]["roughnessFactor"] = roughness_factor
				end
				
				if double_sided
					material["doubleSided"] = true
				end
				if(a < 1.0)
					material["alphaMode"] = "BLEND"
				end
				if texture_id != nil
					# also set blend mode if it is a texture, as the texture may contain transparency
					material["alphaMode"] = "BLEND"
				end
				
				index = @materials.length
				@materials.push(material)
				return index
			end
			
			
			def add_material_by_material(name, material)
				# todo, this function should eventually create a 'virtual', ie temporary face, apply the material, then extract image
				index = @materials_hash[material]
				if index != nil
					return index
				end
				metallicFactor = get_material_attribute(material, 'pbr','metallicFactor',0.1)
				roughnessFactor = get_material_attribute(material, 'pbr', 'roughnessFactor',0.9)
				
				a = material.alpha
				r = material.color.red / 255.0
				g = material.color.green / 255.0
				b = material.color.blue / 255.0
				return add_material_node(name, r,g,b,a, defaultMetallicFactor,defaultRoughnessFactor,false, nil)
			end
			
			def get_material_attribute(material, dictionaryName, attributeName, defaultValue)
				if material == nil
					return defaultValue
				end
				value = material.get_attribute(dictionaryName, attributeName)
				if value == nil
					return defaultValue
				end
				return value.to_f
			end
			
			# Add a material from a face, return the index for the new or existing material
			def add_material(face)
				
				material = face.material
				
				index = @materials_hash[material]
				
				if (index != nil)
					return index
				end

				if (material == nil)
					if @defaultMaterial == -1
						#@defaultMaterial = add_material_node("default material",0.5,0.5,0.75,1.0, 0.1,0.5,true,nil)
						@defaultMaterial = add_material_node("default material",1,1,1,1.0, 0.1,0.5,true,nil) #Use white (not blue) as a default material
					end
					return @defaultMaterial
				end
				
				double_sided = false
				if face.class == Sketchup::Face 	# 'face' might be an entity such as group or component

					#puts "FRONT face material: " + face.material.name
					#puts "r:" + face.material.color.red.to_s + " g:" + face.material.color.green.to_s + " b:" + face.material.color.blue.to_s + " a:" + face.material.alpha.to_s 

					if face.back_material != nil
						double_sided = true

						#puts "BACK face material: " + face.back_material.name
						#puts "r:" + face.back_material.color.red.to_s + " g:" + face.back_material.color.green.to_s + " b:" + face.back_material.color.blue.to_s + " a:" + face.back_material.alpha.to_s 
					end
				end
				
				metallicFactor = get_material_attribute(material, 'pbr','metallicFactor',0.1)
				roughnessFactor = get_material_attribute(material, 'pbr', 'roughnessFactor',0.9)
				
				@materials_hash[material] = @materials.length
				
				name = face.material.display_name
				#puts 'Material display name: ' + name

				a = material.alpha
				r = material.color.red / 255.0
				g = material.color.green / 255.0
				b = material.color.blue / 255.0
				
				# In future version have lookup into common materials table?
				if name != nil
					lname = name.downcase
					if name.include? 'gold'
						metallicFactor = 0.75
						roughnessFactor = 0.0
					end
					if name.include? 'silver'
						metallicFactor = 0.75
						roughnessFactor = 0.0
					end
					
					if (lname.include? 'metal') || (lname.include? 'steel')
						metallicFactor = 0.75
						roughnessFactor = 0.0
					end
					if lname.include? 'aluminium'
						metallicFactor = 0.75
						roughnessFactor = 0.40
					end
				end
				
				if (material.texture != nil)
					texture_id = @textures.add_texture(face)
					return add_material_node(name, r,g,b,a, metallicFactor, roughnessFactor, double_sided, texture_id)
				end

				return add_material_node(name, r,g,b,a, metallicFactor, roughnessFactor, double_sided, nil)
			end

		end
	end
end
