---
title: Yulio SketchUp glTF Exporter (in Ruby)
tags: SketchUp, glTF, exporter, plug-in, 3D geometry
author: Yulio Technolgies Inc.
status: ongoing development
---

## Yulio SketchUp glTF Exporter

Yulio SketchUp glTF Exporter is a Ruby based SketchUp plug-in that adds the ability to export arbitrary 3D scenes from SketchUp to the glTF 2.0 format. Both the embedded glTF (.gltf file extension) and binary glTF (.glb file extension) are supported.  

### Original Authors
This project builds of top of the work done by David R White and Y C White, who were the initiators and original creators of the free-to-use [Khronos glTF exporter plug-in](https://extensions.sketchup.com/nl/content/gltf-exporter). The initial release is a carbon copy of that plug-in with no additions or modification, other than the renaming of the source files and modules. 

### Installation and Usage 

To install the plug-in, copy the 'yulio_gltf_export.rb' files and the 'yulio_gltf_export' folder to the '%userprofile%\AppData\Roaming\SketchUp\SketchUp 2018\SketchUp\Plugins'. Your path may differ according to the installed SketchUp version. The plug-in was tested on the SketchUp 2017 Pro and SketchUp 2018 Pro (earlier versions might work, but are not guaranteed to do so).

To run the export, from the 'Extensions' menu item, select 'Yulio glTF', and then select either 'Export Embedded glTF 2.0 (.gltf)' or 'Export Binary glTF 2.0 (.glb)'.

To view the exported files, refer to the [Khronos glTF page](https://www.khronos.org/gltf/) that contains numerous resources, including the links to several glTF viewer and validation apps.


### Authors

* [Yulio R&D Team](https://github.com/YulioTech)
Ruby based SketchUp glTF Exporter
