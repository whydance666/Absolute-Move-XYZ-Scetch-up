module AbsoluteMoveXYZ
  PLUGIN_NAME = "Absolute Move XYZ"
  GITHUB_URL  = "https://github.com/whydance666"

  @current_theme = :dark

  def self.current_theme
    @current_theme
  end

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

  def self.unit_ratio_inv
    r = unit_ratio
    r == 0 ? 1.0 : 1.0 / r
  end

  def self.parse_float(str)
    s = str.to_s.strip.gsub(",", ".")
    return nil if s.empty?
    s.to_f
  end

  def self.format_coord(inches)
    (inches * unit_ratio_inv).round(4)
  end

  def self.read_current_state
    sel = Sketchup.active_model.selection
    entity = sel.find { |e|
      !e.is_a?(Sketchup::Face) &&
      !e.is_a?(Sketchup::Edge) &&
      e.respond_to?(:transformation)
    }
    return nil unless entity

    bb = entity.bounds
    t  = entity.transformation
    rx, ry, rz = extract_euler(t)
    rad2deg = 180.0 / Math::PI

    {
      x:  format_coord((bb.min.x + bb.max.x) / 2.0),
      y:  format_coord((bb.min.y + bb.max.y) / 2.0),
      z:  format_coord((bb.min.z + bb.max.z) / 2.0),
      rx: (rx * rad2deg).round(2),
      ry: (ry * rad2deg).round(2),
      rz: (rz * rad2deg).round(2)
    }
  end

  def self.axis_block(axis, anchors)
    options_html = anchors.map do |val, label|
      selected = val == anchors[anchors.size / 2][0] ? " selected" : ""
      "<option value=\"#{val}\"#{selected}>#{label}</option>"
    end.join("\n")

    <<-HTML
      <div class="row">
        <label class="axis-label">#{axis}:</label>
        <input type="text" id="#{axis.downcase}_value" class="num-input" autocomplete="off">
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

  def self.rot_block(axis)
    <<-HTML
      <div class="row">
        <label class="axis-label">#{axis}:</label>
        <input type="text" id="r#{axis.downcase}_value" class="num-input" autocomplete="off">
        <label class="unit-label">°</label>
        <select id="r#{axis.downcase}_mode" class="mode-select">
          <option value="absolute" selected>Absolute</option>
          <option value="relative">Relative</option>
        </select>
      </div>
    HTML
  end

  def self.footer_html
    <<-HTML
      <div class="footer">
        <span>made by <a href="#" onclick="window.sketchup.openUrl('#{GITHUB_URL}'); return false;">@whydance666</a></span>
        <span class="footer-sep">·</span>
        <span class="footer-testers">tested by Mike_iLeech &amp; GKL0SS</span>
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
      width: 390,
      height: 510,
      style: UI::HtmlDialog::STYLE_DIALOG
    )

    html = <<-HTML
      <!DOCTYPE html>
      <html>
      <head>
      <meta charset="utf-8">
      <style>
        *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

        body.dark {
          --bg:            #1e1e1e;
          --bg-input:      #2d2d2d;
          --bg-section:    #252525;
          --border:        #3e3e3e;
          --divider:       #3a3a3a;
          --text:          #d4d4d4;
          --text-head:     #cccccc;
          --text-axis:     #9cdcfe;
          --text-rot:      #ce9178;
          --text-muted:    #555555;
          --placeholder:   #444444;
          --btn-apply-bg:  #2d2d2d;
          --btn-apply-hv:  #3a3a3a;
          --btn-ok-bg:     #007acc;
          --btn-ok-hv:     #1a8ad4;
          --status-ok:     #6a9955;
          --status-err:    #f44747;
          --link:          #4e7fa8;
          --link-hv:       #7ab8f0;
          --current-bg:    #1a2a1a;
          --current-border:#2e5a2e;
          --current-text:  #4e8a4e;
        }

        body.light {
          --bg:            #f5f5f5;
          --bg-input:      #ffffff;
          --bg-section:    #eeeeee;
          --border:        #cccccc;
          --divider:       #dddddd;
          --text:          #1e1e1e;
          --text-head:     #333333;
          --text-axis:     #0066aa;
          --text-rot:      #a0522d;
          --text-muted:    #999999;
          --placeholder:   #bbbbbb;
          --btn-apply-bg:  #ececec;
          --btn-apply-hv:  #e0e0e0;
          --btn-ok-bg:     #007acc;
          --btn-ok-hv:     #1a8ad4;
          --status-ok:     #3a7a3a;
          --status-err:    #cc0000;
          --link:          #0066aa;
          --link-hv:       #004488;
          --current-bg:    #e8f5e8;
          --current-border:#5aaa5a;
          --current-text:  #2e7a2e;
        }

        body {
          font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
          font-size: 13px;
          padding: 16px;
          background: var(--bg);
          color: var(--text);
          transition: background 0.2s, color 0.2s;
        }

        .header {
          display: flex; align-items: center;
          justify-content: space-between;
          margin-bottom: 10px; padding-bottom: 8px;
          border-bottom: 1px solid var(--divider);
        }

        h3 {
          font-size: 13px; font-weight: 600;
          color: var(--text-head);
          text-transform: uppercase; letter-spacing: 0.08em;
        }

        .theme-btn {
          width: 28px; height: 22px; padding: 0; font-size: 14px;
          background: var(--bg-input); border: 1px solid var(--border);
          border-radius: 4px; cursor: pointer; flex-shrink: 0;
          transition: background 0.15s;
          display: flex; align-items: center; justify-content: center;
        }
        .theme-btn:hover  { background: var(--btn-apply-hv); }
        .theme-btn:active { transform: scale(0.95); }

        .current-state {
          background: var(--current-bg);
          border: 1px solid var(--current-border);
          border-radius: 4px; padding: 6px 10px;
          margin-bottom: 10px; font-size: 11px;
          color: var(--current-text);
          display: flex; justify-content: space-between;
          align-items: center; gap: 8px;
          transition: background 0.2s, border-color 0.2s;
        }

        .current-state .cs-label {
          font-weight: 600; flex-shrink: 0;
          font-size: 10px; text-transform: uppercase; letter-spacing: 0.05em;
        }

        .current-state .cs-values {
          display: flex; gap: 10px;
          flex-wrap: wrap; justify-content: flex-end;
        }

        .current-state .cs-val { white-space: nowrap; }

        .current-state.empty {
          color: var(--text-muted); border-color: var(--border);
          background: var(--bg-section);
          font-style: italic; justify-content: center;
        }

        .section {
          background: var(--bg-section); border: 1px solid var(--border);
          border-radius: 5px; padding: 10px 10px 4px; margin-bottom: 10px;
        }

        .section-title {
          font-size: 10px; font-weight: 600;
          text-transform: uppercase; letter-spacing: 0.1em; margin-bottom: 8px;
        }
        .section-title.move { color: var(--text-axis); }
        .section-title.rot  { color: var(--text-rot);  }

        .hint {
          font-size: 10px; color: var(--text-muted);
          margin-top: -4px; margin-bottom: 8px; font-style: italic;
        }

        .row {
          display: flex; align-items: center; gap: 6px; margin-bottom: 7px;
        }

        .axis-label {
          width: 14px; font-weight: 700; font-size: 12px; flex-shrink: 0;
        }

        .section:nth-child(3) .axis-label { color: var(--text-axis); }
        .section:nth-child(4) .axis-label { color: var(--text-rot);  }

        .num-input {
          width: 72px; padding: 4px 6px; flex-shrink: 0;
          background: var(--bg-input); border: 1px solid var(--border);
          border-radius: 3px; color: var(--text); font-size: 13px;
          outline: none; transition: border-color 0.15s, background 0.2s;
        }
        .num-input:focus   { border-color: #007acc; }
        .num-input.invalid { border-color: var(--status-err); }
        .num-input::placeholder { color: var(--placeholder); font-style: italic; }

        .unit-label {
          font-size: 12px; color: var(--text-muted); flex-shrink: 0; width: 10px;
        }

        .mode-select-sm {
          width: 50px; flex-shrink: 0; padding: 4px 3px;
          background: var(--bg-input); border: 1px solid var(--border);
          border-radius: 3px; color: var(--text); font-size: 12px;
          outline: none; cursor: pointer;
        }

        .mode-select {
          flex: 1; padding: 4px 6px;
          background: var(--bg-input); border: 1px solid var(--border);
          border-radius: 3px; color: var(--text); font-size: 13px;
          outline: none; cursor: pointer;
        }

        select:focus { border-color: #007acc; }

        .buttons { display: flex; gap: 8px; margin-top: 4px; }

        button {
          flex: 1; height: 34px; font-size: 13px; font-weight: 500;
          cursor: pointer; border: none; border-radius: 3px;
          transition: background 0.15s, transform 0.1s;
        }
        button:active { transform: scale(0.98); }

        .btn-apply {
          background: var(--btn-apply-bg); color: var(--text);
          border: 1px solid var(--border);
        }
        .btn-apply:hover { background: var(--btn-apply-hv); }

        .btn-ok {
          background: var(--btn-ok-bg); color: #ffffff;
          border: 1px solid var(--btn-ok-bg);
        }
        .btn-ok:hover { background: var(--btn-ok-hv); }

        #status {
          margin-top: 8px; font-size: 11px; color: var(--status-ok);
          min-height: 14px; text-align: center; transition: color 0.15s;
        }
        #status.error { color: var(--status-err); }

        .footer {
          margin-top: 8px; padding-top: 8px;
          border-top: 1px solid var(--divider);
          text-align: center; font-size: 10px;
          color: var(--text-muted);
          display: flex; justify-content: center;
          align-items: center; gap: 5px; flex-wrap: wrap;
        }
        .footer a {
          color: var(--link); text-decoration: none; transition: color 0.15s;
        }
        .footer a:hover { color: var(--link-hv); }
        .footer-sep { color: var(--border); }
        .footer-testers { color: var(--text-muted); }
      </style>
      </head>
      <body class="#{@current_theme}">

        <div class="header">
          <h3>Absolute Move XYZ</h3>
          <button class="theme-btn" id="theme-btn" onclick="toggleTheme()" title="Toggle theme">
            #{@current_theme == :dark ? "☀️" : "🌙"}
          </button>
        </div>

        <div class="current-state empty" id="current-state">
          No selection
        </div>

        <div class="section">
          <div class="section-title move">⟷ Position</div>
          <div class="hint">Leave blank to keep current value</div>
          #{axis_block("X", [["left", "Left"], ["center", "Center"], ["right", "Right"]])}
          #{axis_block("Y", [["front", "Front"], ["center", "Center"], ["rear", "Rear"]])}
          #{axis_block("Z", [["bottom", "Bottom"], ["center", "Center"], ["top", "Top"]])}
        </div>

        <div class="section">
          <div class="section-title rot">↻ Rotation</div>
          <div class="hint">Leave blank to keep current value</div>
          #{rot_block("X")}
          #{rot_block("Y")}
          #{rot_block("Z")}
        </div>

        <div class="buttons">
          <button class="btn-apply" onclick="applyData(false)">Apply</button>
          <button class="btn-ok"    onclick="applyData(true)">OK</button>
        </div>

        <div id="status"></div>
        #{footer_html}

        <script>
          function getValue(id) {
            const el  = document.getElementById(id);
            const raw = el.value.trim();
            if (raw === "") { el.classList.remove("invalid"); return ""; }
            const val = raw.replace(",", ".");
            const num = parseFloat(val);
            if (isNaN(num)) { el.classList.add("invalid"); return null; }
            el.classList.remove("invalid");
            return String(num);
          }

          function setCurrentState(state) {
            const el = document.getElementById("current-state");
            if (!state) {
              el.className = "current-state empty";
              el.innerHTML = "No selection";
              return;
            }
            el.className = "current-state";
            el.innerHTML =
              '<span class="cs-label">Current</span>' +
              '<span class="cs-values">' +
              '<span class="cs-val">X\u00a0'  + state.x  + '</span>' +
              '<span class="cs-val">Y\u00a0'  + state.y  + '</span>' +
              '<span class="cs-val">Z\u00a0'  + state.z  + '</span>' +
              '<span class="cs-val">Rx\u00a0' + state.rx + '\u00b0</span>' +
              '<span class="cs-val">Ry\u00a0' + state.ry + '\u00b0</span>' +
              '<span class="cs-val">Rz\u00a0' + state.rz + '\u00b0</span>' +
              '</span>';

            ["x","y","z"].forEach(function(ax) {
              const inp = document.getElementById(ax + "_value");
              if (inp && inp.value.trim() === "") inp.value = state[ax];
            });
            [["rx","rx"],["ry","ry"],["rz","rz"]].forEach(function(pair) {
              const inp = document.getElementById("r" + pair[0].slice(1) + "_value");
              if (inp && inp.value.trim() === "") inp.value = state[pair[1]];
            });
          }

          function toggleTheme() {
            const body = document.body;
            const btn  = document.getElementById("theme-btn");
            if (body.classList.contains("dark")) {
              body.classList.replace("dark", "light");
              btn.textContent = "\uD83C\uDF19";
              window.sketchup.saveTheme("light");
            } else {
              body.classList.replace("light", "dark");
              btn.textContent = "\u2600\uFE0F";
              window.sketchup.saveTheme("dark");
            }
          }

          function applyData(closeDialog) {
            const status = document.getElementById("status");
            const fields = ["x_value","y_value","z_value","rx_value","ry_value","rz_value"];
            let valid = true;
            fields.forEach(function(id) { if (getValue(id) === null) valid = false; });
            if (!valid) {
              status.className = "error";
              status.textContent = "Invalid number format.";
              return;
            }
            const data = {
              x: getValue("x_value"), x_mode: document.getElementById("x_mode").value,
              x_anchor: document.getElementById("x_anchor").value,
              y: getValue("y_value"), y_mode: document.getElementById("y_mode").value,
              y_anchor: document.getElementById("y_anchor").value,
              z: getValue("z_value"), z_mode: document.getElementById("z_mode").value,
              z_anchor: document.getElementById("z_anchor").value,
              rx: getValue("rx_value"), rx_mode: document.getElementById("rx_mode").value,
              ry: getValue("ry_value"), ry_mode: document.getElementById("ry_mode").value,
              rz: getValue("rz_value"), rz_mode: document.getElementById("rz_mode").value,
              close: closeDialog
            };
            status.className = "";
            status.textContent = "Applying...";
            window.sketchup.apply(JSON.stringify(data));
          }

          function onSuccess(msg) {
            const s = document.getElementById("status");
            s.className = ""; s.textContent = msg;
            window.sketchup.requestCurrentState();
          }

          function onError(msg) {
            const s = document.getElementById("status");
            s.className = "error"; s.textContent = "Error: " + msg;
          }
        </script>
      </body>
      </html>
    HTML

    @dialog.set_html(html)

    push_state = lambda do
      return unless @dialog
      state = read_current_state
      if state
        @dialog.execute_script("setCurrentState(#{state.to_json})")
      else
        @dialog.execute_script("setCurrentState(null)")
      end
    end

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

    @dialog.add_action_callback("requestCurrentState") do |_|
      push_state.call
    end

    @dialog.add_action_callback("saveTheme") do |_, theme|
      @current_theme = theme.to_sym
    end

    @dialog.add_action_callback("openUrl") do |_, url|
      UI.openURL(url)
    end

    @dialog.add_action_callback("closeDialog") { |_| @dialog.close }

    @dialog.set_on_closed do
      @dialog = nil
      if @sel_observer
        begin
          Sketchup.active_model.selection.remove_observer(@sel_observer)
        rescue
        end
        @sel_observer = nil
      end
    end

    @sel_observer = Class.new(Sketchup::SelectionObserver) do
      def initialize(callback)
        @callback = callback
      end
      def onSelectionBulkChange(_)
        @callback.call
      end
      def onSelectionCleared(_)
        @callback.call
      end
    end.new(push_state)

    Sketchup.active_model.selection.add_observer(@sel_observer)

    @dialog
  end

  def self.run
    dlg = create_dialog
    if dlg.visible?
      dlg.bring_to_front
    else
      dlg.show
      UI.start_timer(0.3, false) do
        state = read_current_state
        if @dialog
          if state
            @dialog.execute_script("setCurrentState(#{state.to_json})")
          else
            @dialog.execute_script("setCurrentState(null)")
          end
        end
      end
    end
  end

  def self.filter_top_level(entities)
    require 'set'
    entity_set = entities.to_set
    entities.select do |e|
      parent = e.respond_to?(:parent) ? e.parent : nil
      !entity_set.include?(parent)
    end
  end

  def self.extract_euler(t)
    m   = t.to_a
    r00 = m[0];  r10 = m[4];  r20 = m[8]
    r01 = m[1];  r11 = m[5];  r21 = m[9]
    r02 = m[2];  r12 = m[6];  r22 = m[10]

    pitch = Math.atan2(-r20, Math.sqrt(r00**2 + r10**2))
    cos_p = Math.cos(pitch)

    if cos_p.abs < 1e-6
      roll = Math.atan2(-r12, r11)
      yaw  = 0.0
    else
      roll = Math.atan2(r10 / cos_p, r00 / cos_p)
      yaw  = Math.atan2(r21 / cos_p, r22 / cos_p)
    end

    [yaw, pitch, roll]
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

    x = parse_float(data["x"])
    y = parse_float(data["y"])
    z = parse_float(data["z"])

    rx_deg = parse_float(data["rx"])
    ry_deg = parse_float(data["ry"])
    rz_deg = parse_float(data["rz"])

    x_relative  = data["x_mode"]  == "relative"
    y_relative  = data["y_mode"]  == "relative"
    z_relative  = data["z_mode"]  == "relative"
    rx_relative = data["rx_mode"] == "relative"
    ry_relative = data["ry_mode"] == "relative"
    rz_relative = data["rz_mode"] == "relative"

    x_anchor = data["x_anchor"] || "center"
    y_anchor = data["y_anchor"] || "center"
    z_anchor = data["z_anchor"] || "center"

    entities = filter_top_level(selection.to_a)

    model.start_operation("Absolute Move & Rotate XYZ", true)

    begin
      entities.each do |entity|
        next if entity.respond_to?(:locked?) && entity.locked?
        next if entity.is_a?(Sketchup::Face) || entity.is_a?(Sketchup::Edge)
        next unless entity.respond_to?(:transform!)

        bb = entity.bounds
        t  = entity.transformation

        # ── ПОВОРОТ ──
        if rx_deg || ry_deg || rz_deg
          center = bb.center
          cur_rx, cur_ry, cur_rz = extract_euler(t)
          deg2rad = Math::PI / 180.0

          target_rx = rx_deg.nil? ? cur_rx : (rx_relative ? cur_rx + rx_deg * deg2rad : rx_deg * deg2rad)
          target_ry = ry_deg.nil? ? cur_ry : (ry_relative ? cur_ry + ry_deg * deg2rad : ry_deg * deg2rad)
          target_rz = rz_deg.nil? ? cur_rz : (rz_relative ? cur_rz + rz_deg * deg2rad : rz_deg * deg2rad)

          delta_rx = target_rx - cur_rx
          delta_ry = target_ry - cur_ry
          delta_rz = target_rz - cur_rz

          # ФИКС: применяем поворот только если есть реальное изменение
          # и используем единую матрицу вместо трёх последовательных transform!
          tolerance = 1e-10
          if delta_rx.abs > tolerance || delta_ry.abs > tolerance || delta_rz.abs > tolerance
            rot_x = Geom::Transformation.rotation(center, [1, 0, 0], delta_rx)
            rot_y = Geom::Transformation.rotation(center, [0, 1, 0], delta_ry)
            rot_z = Geom::Transformation.rotation(center, [0, 0, 1], delta_rz)

            # Единая матрица — исключает накопление ошибки
            entity.transform!(rot_z * rot_y * rot_x)

            # Пересчитываем после поворота
            bb = entity.bounds
            t  = entity.transformation
          end
        end

        # ── ПЕРЕМЕЩЕНИЕ ──
        origin = t.origin

        ax = x.nil? ? origin.x : anchor_point(bb, :x, x_anchor)
        ay = y.nil? ? origin.y : anchor_point(bb, :y, y_anchor)
        az = z.nil? ? origin.z : anchor_point(bb, :z, z_anchor)

        target_x = x.nil? ? origin.x : (x_relative ? ax + x * ratio : x * ratio)
        target_y = y.nil? ? origin.y : (y_relative ? ay + y * ratio : y * ratio)
        target_z = z.nil? ? origin.z : (z_relative ? az + z * ratio : z * ratio)

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

    cmd.tooltip         = "Move & rotate object to absolute XYZ"
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