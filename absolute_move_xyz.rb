# frozen_string_literal: true

require 'sketchup.rb'
require 'extensions.rb'

module AbsoluteMoveXYZ
  EXTENSION_NAME    = "Absolute Move XYZ"
  EXTENSION_VERSION = "2.1.0"

  unless file_loaded?(__FILE__)
    # Папка называется AbsoluteMoveXYZ — точное совпадение с именем на диске
    loader = File.join(File.dirname(__FILE__), 'AbsoluteMoveXYZ', 'core.rb')

    extension             = SketchupExtension.new(EXTENSION_NAME, loader)
    extension.description = "Move objects using absolute XYZ coordinates."
    extension.version     = EXTENSION_VERSION
    extension.creator     = "whydance666"

    Sketchup.register_extension(extension, true)
    file_loaded(__FILE__)
  end
end