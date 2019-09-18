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

Sketchup.require 'sketchup'
Sketchup.require 'extensions'

# 1.1.0 Support 8-bit ubyte indices
#       Fixed exception handler
#				Fixed an issue for when the json text contained utf8 multibyte characters
#	1.1.1 Fixed inversed textures
#       Fixed metallicFactor default value - textured materials had default metallicity of 1 (metal) rather than 0 (diaellectric)
# 1.1.2 Add Sketchup.require
# 1.2.0 Add file-save dialog box when exporting the model, default to the same directory and name as the existing model.
# 1.2.1 Do not export hidden entities
#       Export metallicFactor and roughnessFactor from dictionary attributes
#       Allow scripted exports to specify filename
#       Orientate model to face viewer
#       Export textures from group/components
# 1.2.2 Fixed issue with nil material exported in un-grouped geometry
# 1.2.3 Do not export if the entity is on a hidden layer
#       Fixed issue with min/max values of accessors
# 1.2.4 sRGB to linear color space conversion
# 1.2.5 Export sampler to correct issues with textures
# 1.3.0 Remove support for original Microsoft .glb files, as they have now fixed their issues
#       Allow setting material metallic, roughness, emissive, and doubleSided properties through material naming convention
#       Add BLEND property if the material contains a texture, as it might contain alpha transparency and the Sketchup API doesn't tell us.
#       Fixed an issue where the material from an outer group or component being used to paint nested faces was not used in the final model.
#       Set glTF copyright field from model.description
# 1.3.1 Drop the use of 8-bit indexes as this is not supported by many GPUs/Engines and may be dropped from future glTF specification.
# 2.0.0 Added support for the camera export
# 		Changed the mesh accumulation, export and relevant buffer view generation mechanism to be performed on a per mesh per material basis. This cuts down the export times by a factor of 2x and drastically improves the speed and memory consumption when exported files are imported via Assimp.
# 		Added optional support for multiple buffer generation in exported files (if needed)
# 		Currently mesh vertices are exported without welding for performance reasons (additional ~30% speed improvement) at the expense of bigger exported file sizes (this could be changed to hash based welding; see the code in MeshData class)
# 		Overall re-factoring to clean up and remove redundant code
# 		Various small performance optimizations and hardening
# 		Added some missing internationalization resource strings
# 2.1.0 Added ImageMagick app to convert images to .png
# 		Passed FOV to gltf from SU
# 2.2.0 Fixed RGBA blending not being supported when a texture was specified for a material
# 		A fix to suppress duplicate geometry in CET exported scenes
# 2.2.1 Disabled the fix to suppress duplicate geometry in CET exported scenes, since it resulted in removal of valid geometry
# 2.3.0 Added proper handling of double sided materials (with a distinct material on each side) by generating 2 separate sets of front and back faces with the correct associated materials.

module Yulio
	module GltfExporter
		unless file_loaded?(__FILE__)
			# because LanguageHandler.new works at this directory level, create a constant for it here
			TRANSLATE = LanguageHandler.new('yulio_gltf_export.strings')
			
			ex = SketchupExtension.new(TRANSLATE["title"], 'yulio_gltf_export/gltf_export')
			ex.description = TRANSLATE["description"]
			ex.version     = '2.3.0'
			ex.copyright   = '©2019'
			ex.creator     = 'Yulio Technolgies Inc.'
			Sketchup.register_extension(ex, true)
			file_loaded(__FILE__)
		end
	end
end
