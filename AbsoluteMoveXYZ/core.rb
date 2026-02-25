# frozen_string_literal: true

module AbsoluteMoveXYZ
  PLUGIN_NAME = "Absolute Move XYZ"

  def self.unit_ratio
    options   = Sketchup.active_model.options["UnitsOptions"]
    unit_type = options["LengthUnit"]

    case unit_type
    when 0 then 1.0
    when 1 then 12.0
    when 2 then 1.0 / 25.4
    when 3 then 1.0 / 2.54
    when 4 then 39.3701
    else        1.0
    end
  end

  def self.axis_block(axis, anchors)
    options_html = anchors.map do |val, label|
      selected = val == anchors[anchors.size / 2][0] ? " selected" : ""
      "<option value=\"#{val}\"#{selected}>#{label}</option>"
    end.join("\n")

    <<-HTML
      <div class="row">
        <label class="axis-label">#{axis}:</label>
        <input type="number" id="#{axis.downcase}_value" value="0" step="any" class="num-input">
        <select id="#{axis.downcase}_mode" class="mode-select-sm">
          <option value="absolute" selected>Abs</option>
          <option value="relative">Rel</option>
        </select>
        <select id="#{axis.downcase}_anchor" class="mode-select">
          #{options_html}
        </select>
      </div>
    HTML
  end

  def self.create_dialog
    return @dialog if @dialog

    @dialog = UI::HtmlDialog.new(
      dialog_title: PLUGIN_NAME,
      preferences_key: "AbsoluteMoveXYZ",
      scrollable: false,
      resizable: false,
      width: 380,
      height: 290,
      style: UI::HtmlDialog::STYLE_DIALOG
    )

    html = <<-HTML
      <!DOCTYPE html>
      <html>
      <head>
      <meta charset="utf-8">
      <style>
        body {
          font-family: sans-serif;
          font-size: 13px;
          padding: 14px;
          margin: 0;
          background: #f5f5f5;
        }
        h3 { margin: 0 0 12px; font-size: 14px; }
        .row {
          display: flex;
          align-items: center;
          gap: 6px;
          margin-bottom: 8px;
        }
        .axis-label     { width: 16px; font-weight: bold; flex-shrink: 0; }
        .num-input      { width: 75px; padding: 3px 4px; box-sizing: border-box; flex-shrink: 0; }
        .mode-select-sm { width: 48px; padding: 3px 2px; flex-shrink: 0; }
        .mode-select    { flex: 1; padding: 3px 4px; }
        .buttons        { display: flex; gap: 10px; margin-top: 14px; }
        button          { flex: 1; height: 36px; font-size: 13px; cursor: pointer; }
        #status         { margin-top: 8px; font-size: 11px; color: #666; min-height: 14px; }
      </style>
      </head>
      <body>
        <h3>Absolute Coordinates</h3>

        #{axis_block("X", [["left", "Left"], ["center", "Center"], ["right", "Right"]])}
        #{axis_block("Y", [["front", "Front"], ["center", "Center"], ["rear", "Rear"]])}
        #{axis_block("Z", [["bottom", "Bottom"], ["center", "Center"], ["top", "Top"]])}

        <div class="buttons">
          <button onclick="applyData(false)">Apply</button>
          <button onclick="applyData(true)">OK</button>
        </div>
        <div id="status"></div>

        <script>
          function applyData(closeDialog) {
            const data = {
              x:        document.getElementById("x_value").value,
              x_mode:   document.getElementById("x_mode").value,
              x_anchor: document.getElementById("x_anchor").value,
              y:        document.getElementById("y_value").value,
              y_mode:   document.getElementById("y_mode").value,
              y_anchor: document.getElementById("y_anchor").value,
              z:        document.getElementById("z_value").value,
              z_mode:   document.getElementById("z_mode").value,
              z_anchor: document.getElementById("z_anchor").value,
              close:    closeDialog
            };
            document.getElementById("status").textContent = "Applying...";
            window.sketchup.apply(JSON.stringify(data));
          }

          function onSuccess(msg) {
            document.getElementById("status").style.color = "#666";
            document.getElementById("status").textContent = msg;
          }

          function onError(msg) {
            document.getElementById("status").style.color = "#c00";
            document.getElementById("status").textContent = "Error: " + msg;
          }
        </script>
      </body>
      </html>
    HTML

    @dialog.set_html(html)

    @dialog.add_action_callback("apply") do |_, json|
      begin
        params = JSON.parse(json)
        apply_move(params)
        @dialog.execute_script("onSuccess('Done.')")
        @dialog.close if params["close"]
      rescue => e
        @dialog.execute_script("onError(#{e.message.to_json})")
      end
    end

    @dialog.add_action_callback("closeDialog") { |_| @dialog.close }
    @dialog.set_on_closed { @dialog = nil }

    @dialog
  end

  def self.run
    dlg = create_dialog
    dlg.visible? ? dlg.bring_to_front : dlg.show
  end

  def self.filter_top_level(entities)
    require 'set'
    entity_set = entities.to_set
    entities.select do |e|
      parent = e.respond_to?(:parent) ? e.parent : nil
      !entity_set.include?(parent)
    end
  end

  def self.anchor_point(bb, axis, anchor)
    case axis
    when :x
      case anchor
      when "left"   then bb.max.x
      when "right"  then bb.min.x
      else               (bb.min.x + bb.max.x) / 2.0
      end
    when :y
      case anchor
      when "front"  then bb.max.y
      when "rear"   then bb.min.y
      else               (bb.min.y + bb.max.y) / 2.0
      end
    when :z
      case anchor
      when "bottom" then bb.min.z
      when "top"    then bb.max.z
      else               (bb.min.z + bb.max.z) / 2.0
      end
    end
  end

  def self.apply_move(data)
    model     = Sketchup.active_model
    selection = model.selection
    return if selection.empty?

    ratio = unit_ratio
    x     = data["x"].to_f * ratio
    y     = data["y"].to_f * ratio
    z     = data["z"].to_f * ratio

    x_relative = data["x_mode"] == "relative"
    y_relative = data["y_mode"] == "relative"
    z_relative = data["z_mode"] == "relative"

    x_anchor = data["x_anchor"] || "center"
    y_anchor = data["y_anchor"] || "center"
    z_anchor = data["z_anchor"] || "center"

    entities = filter_top_level(selection.to_a)

    model.start_operation("Move to Absolute XYZ", true)

    begin
      entities.each do |entity|
        next if entity.respond_to?(:locked?) && entity.locked?
        next if entity.is_a?(Sketchup::Face) || entity.is_a?(Sketchup::Edge)
        next unless entity.respond_to?(:transform!)

        bb = entity.bounds

        ax = anchor_point(bb, :x, x_anchor)
        ay = anchor_point(bb, :y, y_anchor)
        az = anchor_point(bb, :z, z_anchor)

        target_x = x_relative ? ax + x : x
        target_y = y_relative ? ay + y : y
        target_z = z_relative ? az + z : z

        dx = target_x - ax
        dy = target_y - ay
        dz = target_z - az

        entity.transform!(Geom::Transformation.translation([dx, dy, dz]))
      end

      model.commit_operation

    rescue => e
      model.abort_operation
      raise e
    end
  end

  unless file_loaded?(__FILE__)
    UI.menu("Extensions").add_item(PLUGIN_NAME) { AbsoluteMoveXYZ.run }

    toolbar = UI::Toolbar.new(PLUGIN_NAME)
    cmd     = UI::Command.new(PLUGIN_NAME) { AbsoluteMoveXYZ.run }

    cmd.tooltip         = "Move object to absolute XYZ"
    cmd.status_bar_text = "Absolute coordinate positioning"
    cmd.menu_text       = PLUGIN_NAME

    icon_path      = File.join(File.dirname(__FILE__), "icons")
    cmd.small_icon = File.join(icon_path, "icon_16.png")
    cmd.large_icon = File.join(icon_path, "icon_24.png")

    toolbar.add_item(cmd)
    toolbar.restore

    file_loaded(__FILE__)
  end

end

#with love by whydance&Mike_iLeech