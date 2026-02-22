# frozen_string_literal: true

require 'sketchup.rb'
require 'extensions.rb'

module AbsoluteMoveXYZ
  EXTENSION_NAME    = "Absolute Move XYZ"
  EXTENSION_VERSION = "2.0.0"

  unless file_loaded?(__FILE__)
    loader = File.join(File.dirname(__FILE__), 'AbsoluteMoveXYZ', 'core.rb')

    extension             = SketchupExtension.new(EXTENSION_NAME, loader)
    extension.description = "Move objects using absolute XYZ coordinates with per-axis reference control."
    extension.version     = EXTENSION_VERSION
    extension.creator     = "Your Name"

    Sketchup.register_extension(extension, true)

    UI.menu("Extensions").add_item(EXTENSION_NAME) { AbsoluteMoveXYZ.run }

    toolbar = UI::Toolbar.new(EXTENSION_NAME)
    cmd     = UI::Command.new(EXTENSION_NAME) { AbsoluteMoveXYZ.run }

    cmd.tooltip          = "Move object to absolute XYZ"
    cmd.status_bar_text  = "Absolute coordinate positioning"
    cmd.menu_text        = EXTENSION_NAME

    icon_path      = File.join(File.dirname(__FILE__), "AbsoluteMoveXYZ", "icons")
    cmd.small_icon = File.join(icon_path, "icon_16.png")
    cmd.large_icon = File.join(icon_path, "icon_24.png")

    toolbar.add_item(cmd)
    toolbar.restore

    file_loaded(__FILE__)
  end
end
