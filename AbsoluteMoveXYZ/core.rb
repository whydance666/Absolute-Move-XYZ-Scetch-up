# frozen_string_literal: true
# encoding: utf-8

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
        <label class="unit-label">&#176;</label>
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
        <span class="footer-sep">&middot;</span>
        <span class="footer-testers">tested by Mike_iLeech &amp; GKL0SS</span>
      </div>
    HTML
  end

  ICON_SUN  = "&#9728;&#65039;"
  ICON_MOON = "&#127769;"

  def self.create_dialog
    return @dialog if @dialog

    @dialog = UI::HtmlDialog.new(
      dialog_title: PLUGIN_NAME,
      preferences_key: "AbsoluteMoveXYZ",
      scrollable: false,
      resizable: true,
      width: 390,
      height: 480,
      style: UI::HtmlDialog::STYLE_DIALOG
    )

    initial_icon = @current_theme == :dark ? ICON_SUN : ICON_MOON

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
          --btn-reset-bg:  #3a2020;
          --btn-reset-hv:  #4a2828;
          --btn-reset-cl:  #f44747;
          --status-ok:     #6a9955;
          --status-err:    #f44747;
          --link:          #4e7fa8;
          --link-hv:       #7ab8f0;
          --current-bg:    #1a2a1a;
          --current-border:#2e5a2e;
          --current-text:  #4e8a4e;
          --scrollbar-bg:  #2d2d2d;
          --scrollbar-th:  #555555;
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
          --btn-reset-bg:  #fdecea;
          --btn-reset-hv:  #fad4d0;
          --btn-reset-cl:  #cc0000;
          --status-ok:     #3a7a3a;
          --status-err:    #cc0000;
          --link:          #0066aa;
          --link-hv:       #004488;
          --current-bg:    #e8f5e8;
          --current-border:#5aaa5a;
          --current-text:  #2e7a2e;
          --scrollbar-bg:  #eeeeee;
          --scrollbar-th:  #bbbbbb;
        }

        html, body { height: 100%; overflow: hidden; }

        body {
          font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
          font-size: 13px; background: var(--bg); color: var(--text);
          transition: background 0.2s, color 0.2s;
          display: flex; flex-direction: column;
        }

        .topbar {
          flex-shrink: 0; display: flex; align-items: center;
          justify-content: space-between;
          padding: 10px 16px 8px;
          border-bottom: 1px solid var(--divider);
          background: var(--bg);
        }

        .current-state {
          flex: 1; background: var(--current-bg);
          border: 1px solid var(--current-border);
          border-radius: 4px; padding: 4px 8px;
          font-size: 11px; color: var(--current-text);
          display: flex; justify-content: space-between;
          align-items: center; gap: 6px;
          transition: background 0.2s, border-color 0.2s;
          margin-right: 8px;
        }
        .current-state .cs-label {
          font-weight: 600; flex-shrink: 0;
          font-size: 10px; text-transform: uppercase; letter-spacing: 0.05em;
        }
        .current-state .cs-values {
          display: flex; gap: 8px; flex-wrap: wrap; justify-content: flex-end;
        }
        .current-state .cs-val { white-space: nowrap; }
        .current-state.empty {
          color: var(--text-muted); border-color: var(--border);
          background: var(--bg-section);
          font-style: italic; justify-content: center;
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

        .scroll-area {
          flex: 1; overflow-y: auto; overflow-x: hidden; padding: 12px 16px 8px;
        }
        .scroll-area::-webkit-scrollbar { width: 6px; }
        .scroll-area::-webkit-scrollbar-track { background: var(--scrollbar-bg); }
        .scroll-area::-webkit-scrollbar-thumb { background: var(--scrollbar-th); border-radius: 3px; }
        .scroll-area::-webkit-scrollbar-thumb:hover { background: var(--text-muted); }

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

        .row { display: flex; align-items: center; gap: 6px; margin-bottom: 7px; }

        .axis-label { width: 14px; font-weight: 700; font-size: 12px; flex-shrink: 0; }
        .section:nth-child(1) .axis-label { color: var(--text-axis); }
        .section:nth-child(2) .axis-label { color: var(--text-rot);  }

        .num-input {
          width: 72px; padding: 4px 6px; flex-shrink: 0;
          background: var(--bg-input); border: 1px solid var(--border);
          border-radius: 3px; color: var(--text); font-size: 13px;
          outline: none; transition: border-color 0.15s, background 0.2s;
        }
        .num-input:focus   { border-color: #007acc; }
        .num-input.invalid { border-color: var(--status-err); }
        .num-input::placeholder { color: var(--placeholder); font-style: italic; }

        .unit-label { font-size: 12px; color: var(--text-muted); flex-shrink: 0; width: 10px; }

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

        .bottom-bar {
          flex-shrink: 0; padding: 8px 16px 10px;
          border-top: 1px solid var(--divider); background: var(--bg);
        }

        .buttons { display: flex; gap: 8px; margin-bottom: 6px; }

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

        .btn-reset {
          background: var(--btn-reset-bg); color: var(--btn-reset-cl);
          border: 1px solid var(--btn-reset-cl);
          font-size: 12px; height: 28px;
        }
        .btn-reset:hover { background: var(--btn-reset-hv); }

        #status {
          font-size: 11px; color: var(--status-ok);
          min-height: 14px; text-align: center;
          transition: color 0.15s; margin-bottom: 6px;
        }
        #status.error { color: var(--status-err); }

        .footer {
          text-align: center; font-size: 10px; color: var(--text-muted);
          display: flex; justify-content: center;
          align-items: center; gap: 5px; flex-wrap: wrap;
        }
        .footer a { color: var(--link); text-decoration: none; transition: color 0.15s; }
        .footer a:hover { color: var(--link-hv); }
        .footer-sep { color: var(--border); }
        .footer-testers { color: var(--text-muted); }
      </style>
      </head>
      <body class="#{@current_theme}">

        <div class="topbar">
          <div class="current-state empty" id="current-state">No selection</div>
          <button class="theme-btn" id="theme-btn" onclick="toggleTheme()" title="Toggle theme">#{initial_icon}</button>
        </div>

        <div class="scroll-area">
          <div class="section">
            <div class="section-title move">&#8596; Position</div>
            <div class="hint">Leave blank to keep current value</div>
            #{axis_block("X", [["left", "Left"], ["center", "Center"], ["right", "Right"]])}
            #{axis_block("Y", [["front", "Front"], ["center", "Center"], ["rear", "Rear"]])}
            #{axis_block("Z", [["bottom", "Bottom"], ["center", "Center"], ["top", "Top"]])}
          </div>

          <div class="section">
            <div class="section-title rot">&#8635; Rotation</div>
            <div class="hint">Leave blank to keep current value</div>
            #{rot_block("X")}
            #{rot_block("Y")}
            #{rot_block("Z")}
          </div>
        </div>

        <div class="bottom-bar">
          <div class="buttons">
            <button class="btn-apply" onclick="applyData(false)">Apply</button>
            <button class="btn-ok"    onclick="applyData(true)">OK</button>
          </div>
          <button class="btn-reset" onclick="resetAll()" style="width:100%;">&#8635; Reset all parameters</button>
          <div id="status"></div>
          #{footer_html}
        </div>

        <script>
          var ICON_SUN  = "&#9728;&#65039;";
          var ICON_MOON = "&#127769;";

          function getValue(id) {
            var el  = document.getElementById(id);
            var raw = el.value.trim();
            if (raw === "") { el.classList.remove("invalid"); return ""; }
            var val = raw.replace(",", ".");
            var num = parseFloat(val);
            if (isNaN(num)) { el.classList.add("invalid"); return null; }
            el.classList.remove("invalid");
            return String(num);
          }

          // ФИКС: reset только очищает поля и сбрасывает селекты
          // НЕ вызывает requestCurrentState — поля остаются пустыми
          function resetAll() {
            var inputs = ["x_value","y_value","z_value","rx_value","ry_value","rz_value"];
            inputs.forEach(function(id) {
              var el = document.getElementById(id);
              if (el) { el.value = ""; el.classList.remove("invalid"); }
            });
            var selects = {
              "x_mode": "absolute", "y_mode": "absolute", "z_mode": "absolute",
              "x_anchor": "center", "y_anchor": "center",  "z_anchor": "center",
              "rx_mode": "absolute", "ry_mode": "absolute", "rz_mode": "absolute"
            };
            Object.keys(selects).forEach(function(id) {
              var el = document.getElementById(id);
              if (el) el.value = selects[id];
            });
            var s = document.getElementById("status");
            s.className = ""; s.textContent = "";
          }

          function setCurrentState(state) {
            var el = document.getElementById("current-state");
            if (!state) {
              el.className = "current-state empty";
              el.innerHTML = "No selection";
              return;
            }
            el.className = "current-state";
            el.innerHTML =
              '<span class="cs-label">Current</span>' +
              '<span class="cs-values">' +
              '<span class="cs-val">X&#160;'  + state.x  + '</span>' +
              '<span class="cs-val">Y&#160;'  + state.y  + '</span>' +
              '<span class="cs-val">Z&#160;'  + state.z  + '</span>' +
              '<span class="cs-val">Rx&#160;' + state.rx + '&#176;</span>' +
              '<span class="cs-val">Ry&#160;' + state.ry + '&#176;</span>' +
              '<span class="cs-val">Rz&#160;' + state.rz + '&#176;</span>' +
              '</span>';
            // Подставляем значения только в пустые поля
            ["x","y","z"].forEach(function(ax) {
              var inp = document.getElementById(ax + "_value");
              if (inp && inp.value.trim() === "") inp.value = state[ax];
            });
            ["x","y","z"].forEach(function(ax) {
              var inp = document.getElementById("r" + ax + "_value");
              if (inp && inp.value.trim() === "") inp.value = state["r" + ax];
            });
          }

          function toggleTheme() {
            var body = document.body;
            var btn  = document.getElementById("theme-btn");
            if (body.classList.contains("dark")) {
              body.classList.replace("dark", "light");
              btn.innerHTML = ICON_MOON;
              window.sketchup.saveTheme("light");
            } else {
              body.classList.replace("light", "dark");
              btn.innerHTML = ICON_SUN;
              window.sketchup.saveTheme("dark");
            }
          }

          function applyData(closeDialog) {
            var status = document.getElementById("status");
            var fields = ["x_value","y_value","z_value","rx_value","ry_value","rz_value"];
            var valid  = true;
            fields.forEach(function(id) { if (getValue(id) === null) valid = false; });
            if (!valid) {
              status.className = "error";
              status.textContent = "Invalid number format.";
              return;
            }
            var data = {
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
            var s = document.getElementById("status");
            s.className = ""; s.textContent = msg;
            window.sketchup.requestCurrentState();
          }

          function onError(msg) {
            var s = document.getElementById("status");
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

    @dialog.add_action_callback("requestCurrentState") { |_| push_state.call }
    @dialog.add_action_callback("saveTheme") { |_, theme| @current_theme = theme.to_sym }
    @dialog.add_action_callback("openUrl")   { |_, url|   UI.openURL(url) }
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
      def initialize(cb) ; @cb = cb ; end
      def onSelectionBulkChange(_) ; @cb.call ; end
      def onSelectionCleared(_)    ; @cb.call ; end
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
          json = state ? "setCurrentState(#{state.to_json})" : "setCurrentState(null)"
          @dialog.execute_script(json)
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
    r11 = m[5];  r21 = m[9]
    r12 = m[6];  r22 = m[10]

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
          center  = bb.center
          deg2rad = Math::PI / 180.0

          if rx_relative || ry_relative || rz_relative
            # Relative: считаем delta и применяем
            cur_rx, cur_ry, cur_rz = extract_euler(t)

            delta_rx = rx_deg && rx_relative  ? rx_deg * deg2rad : 0.0
            delta_ry = ry_deg && ry_relative  ? ry_deg * deg2rad : 0.0
            delta_rz = rz_deg && rz_relative  ? rz_deg * deg2rad : 0.0

            tolerance = 1e-10
            if delta_rx.abs > tolerance || delta_ry.abs > tolerance || delta_rz.abs > tolerance
              rot_x = Geom::Transformation.rotation(center, [1, 0, 0], delta_rx)
              rot_y = Geom::Transformation.rotation(center, [0, 1, 0], delta_ry)
              rot_z = Geom::Transformation.rotation(center, [0, 0, 1], delta_rz)
              entity.transform!(rot_z * rot_y * rot_x)
              bb = entity.bounds
              t  = entity.transformation
            end
          else
            # ФИКС Absolute: полностью пересобираем трансформацию с нуля
            # Берём текущий масштаб и позицию, заменяем только rotation
            cur_rx, cur_ry, cur_rz = extract_euler(t)

            target_rx = rx_deg ? rx_deg * deg2rad : cur_rx
            target_ry = ry_deg ? ry_deg * deg2rad : cur_ry
            target_rz = rz_deg ? rz_deg * deg2rad : cur_rz

            # Строим чистую rotation матрицу через три оси
            # Сначала сбрасываем rotation объекта до нуля, потом применяем нужный угол
            # Получаем текущий scale из трансформации
            sx = Math.sqrt(t.to_a[0]**2 + t.to_a[4]**2 + t.to_a[8]**2)
            sy = Math.sqrt(t.to_a[1]**2 + t.to_a[5]**2 + t.to_a[9]**2)
            sz = Math.sqrt(t.to_a[2]**2 + t.to_a[6]**2 + t.to_a[10]**2)

            # Трансформация: сброс к identity rotation вокруг center, затем новый поворот
            reset_rot = Geom::Transformation.rotation(center, [1,0,0], -cur_rx) *
                        Geom::Transformation.rotation(center, [0,1,0], -cur_ry) *
                        Geom::Transformation.rotation(center, [0,0,1], -cur_rz)

            new_rot   = Geom::Transformation.rotation(center, [0,0,1], target_rz) *
                        Geom::Transformation.rotation(center, [0,1,0], target_ry) *
                        Geom::Transformation.rotation(center, [1,0,0], target_rx)

            entity.transform!(new_rot * reset_rot)

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

        entity.transform!(Geom::Transformation.translation([target_x - ax, target_y - ay, target_z - az]))
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