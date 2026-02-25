require 'sketchup.rb'
require 'extensions.rb'

module AbsoluteMoveXYZ
  EXTENSION_NAME    = "Absolute Move XYZ"
  EXTENSION_VERSION = "2.0.0"

  unless file_loaded?(__FILE__)
    loader = File.join(File.dirname(__FILE__), 'AbsoluteMoveXYZ', 'core.rb')

    extension             = SketchupExtension.new(EXTENSION_NAME, loader)
    extension.description = "Move objects using absolute XYZ coordinates."
    extension.version     = EXTENSION_VERSION
    extension.creator     = "Your Name"

    Sketchup.register_extension(extension, true)
    file_loaded(__FILE__)
  end
end