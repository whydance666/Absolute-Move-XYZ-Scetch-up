module AbsoluteMoveXYZ
  PLUGIN_NAME = "Absolute Move XYZ"
  GITHUB_URL  = "https://github.com/whydance666"

  # Тема сохраняется между открытиями диалога в рамках сессии SketchUp
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

  def self.footer_html
    <<-HTML
      <div class="footer">
        made by <a href="#" onclick="window.sketchup.openUrl('#{GITHUB_URL}'); return false;">@whydance666</a>
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
      height: 338,
      style: UI::HtmlDialog::STYLE_DIALOG
    )

    html = <<-HTML
      <!DOCTYPE html>
      <html>
      <head>
      <meta charset="utf-8">
      <style>
        *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

        /* ── Тёмная тема ── */
        body.dark {
          --bg:            #1e1e1e;
          --bg-input:      #2d2d2d;
          --border:        #3e3e3e;
          --divider:       #3a3a3a;
          --text:          #d4d4d4;
          --text-head:     #cccccc;
          --text-axis:     #9cdcfe;
          --text-muted:    #555555;
          --btn-apply-bg:  #2d2d2d;
          --btn-apply-hv:  #3a3a3a;
          --btn-ok-bg:     #007acc;
          --btn-ok-hv:     #1a8ad4;
          --status-ok:     #6a9955;
          --status-err:    #f44747;
          --link:          #4e7fa8;
          --link-hv:       #7ab8f0;
        }

        /* ── Светлая тема ── */
        body.light {
          --bg:            #f5f5f5;
          --bg-input:      #ffffff;
          --border:        #cccccc;
          --divider:       #dddddd;
          --text:          #1e1e1e;
          --text-head:     #333333;
          --text-axis:     #0066aa;
          --text-muted:    #999999;
          --btn-apply-bg:  #ececec;
          --btn-apply-hv:  #e0e0e0;
          --btn-ok-bg:     #007acc;
          --btn-ok-hv:     #1a8ad4;
          --status-ok:     #3a7a3a;
          --status-err:    #cc0000;
          --link:          #0066aa;
          --link-hv:       #004488;
        }

        body {
          font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
          font-size: 13px;
          padding: 16px;
          background: var(--bg);
          color: var(--text);
          transition: background 0.2s, color 0.2s;
        }

        /* ── Шапка ── */
        .header {
          display: flex;
          align-items: center;
          justify-content: space-between;
          margin-bottom: 14px;
          padding-bottom: 8px;
          border-bottom: 1px solid var(--divider);
        }

        h3 {
          font-size: 13px;
          font-weight: 600;
          color: var(--text-head);
          text-transform: uppercase;
          letter-spacing: 0.08em;
        }

        /* ── Кнопка переключения темы ── */
        .theme-btn {
          width: 28px;
          height: 22px;
          padding: 0;
          font-size: 14px;
          line-height: 1;
          background: var(--bg-input);
          border: 1px solid var(--border);
          border-radius: 4px;
          cursor: pointer;
          flex-shrink: 0;
          transition: background 0.15s, border-color 0.15s;
          display: flex;
          align-items: center;
          justify-content: center;
        }

        .theme-btn:hover  { background: var(--btn-apply-hv); }
        .theme-btn:active { transform: scale(0.95); }

        /* ── Строки полей ── */
        .row {
          display: flex;
          align-items: center;
          gap: 6px;
          margin-bottom: 8px;
        }

        .axis-label {
          width: 14px;
          font-weight: 700;
          font-size: 12px;
          flex-shrink: 0;
          color: var(--text-axis);
        }

        .num-input {
          width: 75px;
          padding: 4px 6px;
          flex-shrink: 0;
          background: var(--bg-input);
          border: 1px solid var(--border);
          border-radius: 3px;
          color: var(--text);
          font-size: 13px;
          outline: none;
          transition: border-color 0.15s, background 0.2s;
        }

        .num-input:focus { border-color: #007acc; }

        .mode-select-sm {
          width: 50px;
          flex-shrink: 0;
          padding: 4px 3px;
          background: var(--bg-input);
          border: 1px solid var(--border);
          border-radius: 3px;
          color: var(--text);
          font-size: 12px;
          outline: none;
          cursor: pointer;
          transition: background 0.2s;
        }

        .mode-select {
          flex: 1;
          padding: 4px 6px;
          background: var(--bg-input);
          border: 1px solid var(--border);
          border-radius: 3px;
          color: var(--text);
          font-size: 13px;
          outline: none;
          cursor: pointer;
          transition: background 0.2s;
        }

        select:focus { border-color: #007acc; }

        .divider {
          height: 1px;
          background: var(--divider);
          margin: 10px 0;
        }

        /* ── Кнопки Apply / OK ── */
        .buttons { display: flex; gap: 8px; margin-top: 12px; }

        button {
          flex: 1;
          height: 34px;
          font-size: 13px;
          font-weight: 500;
          cursor: pointer;
          border: none;
          border-radius: 3px;
          transition: background 0.15s, transform 0.1s;
        }

        button:active { transform: scale(0.98); }

        .btn-apply {
          background: var(--btn-apply-bg);
          color: var(--text);
          border: 1px solid var(--border);
        }

        .btn-apply:hover { background: var(--btn-apply-hv); }

        .btn-ok {
          background: var(--btn-ok-bg);
          color: #ffffff;
          border: 1px solid var(--btn-ok-bg);
        }

        .btn-ok:hover { background: var(--btn-ok-hv); }

        /* ── Статус ── */
        #status {
          margin-top: 10px;
          font-size: 11px;
          color: var(--status-ok);
          min-height: 14px;
          text-align: center;
          transition: color 0.15s;
        }

        #status.error { color: var(--status-err); }

        /* ── Футер ── */
        .footer {
          margin-top: 10px;
          padding-top: 8px;
          border-top: 1px solid var(--divider);
          text-align: center;
          font-size: 10px;
          color: var(--text-muted);
        }

        .footer a {
          color: var(--link);
          text-decoration: none;
          transition: color 0.15s;
        }

        .footer a:hover { color: var(--link-hv); }
      </style>
      </head>
      <body class="#{@current_theme}">

        <div class="header">
          <h3>Absolute Coordinates</h3>
          <button class="theme-btn" id="theme-btn" onclick="toggleTheme()" title="Toggle theme">
            #{@current_theme == :dark ? "☀️" : "🌙"}
          </button>
        </div>

        #{axis_block("X", [["left", "Left"], ["center", "Center"], ["right", "Right"]])}
        #{axis_block("Y", [["front", "Front"], ["center", "Center"], ["rear", "Rear"]])}
        #{axis_block("Z", [["bottom", "Bottom"], ["center", "Center"], ["top", "Top"]])}

        <div class="divider"></div>

        <div class="buttons">
          <button class="btn-apply" onclick="applyData(false)">Apply</button>
          <button class="btn-ok"    onclick="applyData(true)">OK</button>
        </div>

        <div id="status"></div>

        #{footer_html}

        <script>
          function toggleTheme() {
            const body = document.body;
            const btn  = document.getElementById("theme-btn");
            if (body.classList.contains("dark")) {
              body.classList.replace("dark", "light");
              btn.textContent = "🌙";
              window.sketchup.saveTheme("light");
            } else {
              body.classList.replace("light", "dark");
              btn.textContent = "☀️";
              window.sketchup.saveTheme("dark");
            }
          }

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
            const status = document.getElementById("status");
            status.className = "";
            status.textContent = "Applying...";
            window.sketchup.apply(JSON.stringify(data));
          }

          function onSuccess(msg) {
            const status = document.getElementById("status");
            status.className = "";
            status.textContent = msg;
          }

          function onError(msg) {
            const status = document.getElementById("status");
            status.className = "error";
            status.textContent = "Error: " + msg;
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

    # Сохраняем выбранную тему — запомнится до закрытия SketchUp
    @dialog.add_action_callback("saveTheme") do |_, theme|
      @current_theme = theme.to_sym
    end

    # Открываем ссылку в нативном браузере системы
    @dialog.add_action_callback("openUrl") do |_, url|
      UI.openURL(url)
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