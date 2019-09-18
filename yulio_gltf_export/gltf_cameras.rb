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
Sketchup.require "yulio_gltf_export/gltf_id"

module Yulio
    module GltfExporter
        class GltfCameras
            def initialize(nodes)
                @nodes = nodes
                @cameras = []
                @id_gen = GltfId.new
            end

            attr_reader :cameras 

            def add_camera_type(name, fov, aspect_ratio)
                camera={
                        "perspective"=>
                        {
                            "yfov"=>fov,
                            "zfar"=>25.399999618530278,
                            "znear"=>0.02539999969303608,
                                "aspectRatio"=>aspect_ratio
                        },
                        "type"=>"perspective",
                    "name"=>name
                    }
                index=@cameras.length
                @cameras.push(camera)
                return index

            end

            def create_camera_matrix(camera)
                originM=Geom::Point3d.new(camera.eye.x.to_m,camera.eye.y.to_m,camera.eye.z.to_m)
                matrix=Geom::Transformation.axes(originM,camera.xaxis,camera.yaxis,camera.zaxis.reverse)
                #temp=[1.0, 0.0, 0.0, 0.0, 0.0, 0.0, -1.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0]
                #tran=Geom::Transformation.new(temp)
                #matrix=tran*matrix
                return matrix.to_a
            end

            def add_camera_nodes
                pages = Sketchup.active_model.pages
                if (pages.length == 0)
                    return
                end

                group_node_id = create_camera_group
                
                pages.each do |page|
                    name = page.label
                    camera=align_camera_view(page.camera)
                    matrix = create_camera_matrix(camera)
                    camera_id = add_camera_type(name + "_camera", camera.fov.degrees, (camera.aspect_ratio > 0.0 ? camera.aspect_ratio : 16.0/9.0))
                    node_id = @nodes.add_node(name, matrix, true)
                    @nodes.add_camera(node_id, camera_id)
                    @nodes.add_child(group_node_id, node_id)
                end
            end

            def create_camera_group
                matrix = [    
                    1.0,
                    0.0,
                    0.0,
                    0.0,
                    0.0,
                    0.0,
                   -1.0,
                    0.0,
                    0.0,
                    1.0,
                    0.0,
                    0.0,
                    0.0,
                    0.0,
                    0.0,
                    1.0
                ]

                node_id = @nodes.add_node("Camera Group", matrix, true)
                @nodes.add_child(0, node_id)

                return node_id
            end

            def align_camera_view(camera)
                angle=camera.direction.angle_between(Z_AXIS)
                angle=angle*180/Math::PI-90
                rotation=Geom::Transformation.rotation(camera.eye,camera.xaxis,(angle.degrees))
                new_target=camera.target.transform(rotation)
                return camera.set(camera.eye,new_target,Z_AXIS)
            end
        end
    end
    
end
