module AbsoluteMoveXYZ

  PLUGIN_NAME = "Absolute Move XYZ"

  # -----------------------------
  # MAIN EXECUTION
  # -----------------------------

  def self.run
    create_dialog unless @dialog
    @dialog.show
  end

  # -----------------------------
  # DIALOG
  # -----------------------------

  def self.create_dialog
    @dialog = UI::HtmlDialog.new({
      dialog_title: PLUGIN_NAME,
      preferences_key: "AbsoluteMoveXYZ",
      scrollable: false,
      resizable: false,
      width: 420,
      height: 380,
      style: UI::HtmlDialog::STYLE_DIALOG
    })

    html = <<-HTML
    <!DOCTYPE html>
    <html>
    <body style="font-family:sans-serif;padding:15px;">
      <h3>Absolute Coordinates</h3>

      #{axis_block("X")}
      #{axis_block("Y")}
      #{axis_block("Z")}

      <br>
      <button onclick="sendData()" style="width:100%;height:40px;">
        Apply
      </button>

      <script>
        function sendData(){
          const data = {
            x: document.getElementById("x_value").value,
            x_mode: document.getElementById("x_mode").value,
            y: document.getElementById("y_value").value,
            y_mode: document.getElementById("y_mode").value,
            z: document.getElementById("z_value").value,
            z_mode: document.getElementById("z_mode").value
          };
          sketchup.apply(JSON.stringify(data));
        }
      </script>
    </body>
    </html>
    HTML

    @dialog.set_html(html)

    @dialog.add_action_callback("apply") do |_, json|
      apply_move(JSON.parse(json))
    end
  end

  # -----------------------------
  # AXIS UI BLOCK
  # -----------------------------

  def self.axis_block(axis)
    axis_down = axis.downcase
    <<-HTML
    <fieldset style="margin-bottom:10px;">
      <legend>Axis #{axis}</legend>
      <input id="#{axis_down}_value" placeholder="Absolute value (blank = ignore)" style="width:100%;margin-bottom:5px;">
      <select id="#{axis_down}_mode" style="width:100%;">
        <option value="min">Min</option>
        <option value="center">Center</option>
        <option value="max">Max</option>
      </select>
    </fieldset>
    HTML
  end

  # -----------------------------
  # APPLY LOGIC
  # -----------------------------

  def self.apply_move(data)
    model = Sketchup.active_model
    sel   = model.selection

    if sel.empty?
      UI.messagebox("Selection is empty.")
      return
    end

    tx = data["x"].strip.empty? ? nil : data["x"].to_l
    ty = data["y"].strip.empty? ? nil : data["y"].to_l
    tz = data["z"].strip.empty? ? nil : data["z"].to_l

    model.start_operation("Absolute Move XYZ", true)

    sel.each do |e|
      next unless e.respond_to?(:bounds)
      next if e.locked?

      bounds = e.bounds

      dx = compute_delta(tx, data["x_mode"], bounds, :x)
      dy = compute_delta(ty, data["y_mode"], bounds, :y)
      dz = compute_delta(tz, data["z_mode"], bounds, :z)

      translation = Geom::Transformation.translation([dx, dy, dz])
      e.transform!(translation)
    end

    model.commit_operation
  end

  def self.compute_delta(target, mode, bounds, axis)
    return 0 if target.nil?

    current =
      case mode
      when "min"
        bounds.min.send(axis)
      when "center"
        bounds.center.send(axis)
      else
        bounds.max.send(axis)
      end

    target - current
  end

  # -----------------------------
  # MENU + TOOLBAR
  # -----------------------------

  unless file_loaded?(__FILE__)

    UI.menu("Extensions").add_item(PLUGIN_NAME) { self.run }

    toolbar = UI::Toolbar.new(PLUGIN_NAME)

    cmd = UI::Command.new(PLUGIN_NAME) { self.run }
    cmd.tooltip = "Move object to absolute XYZ"
    cmd.status_bar_text = "Absolute coordinate positioning"
    cmd.menu_text = PLUGIN_NAME

    icon_path = File.join(File.dirname(__FILE__), "icons")
    cmd.small_icon = File.join(icon_path, "icon_16.png")
    cmd.large_icon = File.join(icon_path, "icon_24.png")

    toolbar.add_item(cmd)
    toolbar.restore

    file_loaded(__FILE__)
  end

end
