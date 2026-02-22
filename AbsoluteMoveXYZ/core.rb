# frozen_string_literal: true

module AbsoluteMoveXYZ
  PLUGIN_NAME = "AbsoluteMoveXYZ"

  # Возвращает текущий множитель перевода единиц модели → дюймы (внутренний формат SketchUp)
  def self.unit_ratio
    options   = Sketchup.active_model.options["UnitsOptions"]
    unit_type = options["LengthUnit"]

    # LengthUnit: 0=inches, 1=feet, 2=mm, 3=cm, 4=m
    case unit_type
    when 0 then 1.0
    when 1 then 12.0
    when 2 then 1.0 / 25.4
    when 3 then 1.0 / 2.54
    when 4 then 39.3701
    else        1.0
    end
  end

  # HTML-блок для одной оси
  def self.axis_block(axis)
    <<-HTML
      <div class="row">
        <label class="axis-label">#{axis}:</label>
        <input type="number" id="#{axis.downcase}_value" value="0" step="any" class="num-input">
        <select id="#{axis.downcase}_mode" class="mode-select">
          <option value="absolute" selected>Absolute</option>
          <option value="relative">Relative</option>
        </select>
      </div>
    HTML
  end

  # HTML-блок выбора anchor
  def self.anchor_block
    <<-HTML
      <div class="row">
        <label class="axis-label">Anchor:</label>
        <select id="anchor" class="mode-select" style="flex:1;">
          <option value="bottom">Bottom</option>
          <option value="center" selected>Center</option>
          <option value="top">Top</option>
        </select>
      </div>
    HTML
  end

  # Создание диалога (один экземпляр)
  def self.create_dialog
    return @dialog if @dialog

    @dialog = UI::HtmlDialog.new(
      dialog_title: PLUGIN_NAME,
      preferences_key: "AbsoluteMoveXYZ",
      scrollable: false,
      resizable: false,
      width: 340,
      height: 310,
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
        .axis-label { width: 16px; font-weight: bold; flex-shrink: 0; }
        .num-input  { width: 80px; padding: 3px 4px; box-sizing: border-box; }
        .mode-select { flex: 1; padding: 3px 4px; }
        .buttons {
          display: flex;
          gap: 10px;
          margin-top: 14px;
        }
        button {
          flex: 1;
          height: 36px;
          font-size: 13px;
          cursor: pointer;
        }
        #status {
          margin-top: 8px;
          font-size: 11px;
          color: #666;
          min-height: 14px;
        }
      </style>
      </head>
      <body>
        <h3>Absolute Coordinates</h3>
        #{axis_block("X")}
        #{axis_block("Y")}
        #{axis_block("Z")}
        #{anchor_block}

        <div class="buttons">
          <button onclick="applyData(false)">Apply</button>
          <button onclick="applyData(true)">OK</button>
        </div>
        <div id="status"></div>

        <script>
          function applyData(closeDialog) {
            const data = {
              x:      document.getElementById("x_value").value,
              x_mode: document.getElementById("x_mode").value,
              y:      document.getElementById("y_value").value,
              y_mode: document.getElementById("y_mode").value,
              z:      document.getElementById("z_value").value,
              z_mode: document.getElementById("z_mode").value,
              anchor: document.getElementById("anchor").value,
              close:  closeDialog
            };
            document.getElementById("status").textContent = "Applying...";
            window.sketchup.apply(JSON.stringify(data));
          }

          function onSuccess(msg) {
            document.getElementById("status").textContent = msg;
          }

          function onError(msg) {
            document.getElementById("status").style.color = "#c00";
            document.getElementById("status").textContent = "Error: " + msg;
          }

          function doClose() {
            window.sketchup.closeDialog();
          }
        </script>
      </body>
      </html>
    HTML

    @dialog.set_html(html)

    # Основной callback — применить перемещение
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

    # Callback закрытия (window.close() не работает в HtmlDialog)
    @dialog.add_action_callback("closeDialog") { |_| @dialog.close }

    # Сбрасываем ссылку когда диалог закрыт, чтобы он пересоздался при следующем вызове
    @dialog.set_on_closed { @dialog = nil }

    @dialog
  end

  # Показываем диалог (или выносим на передний план)
  def self.run
    dlg = create_dialog

    if dlg.visible?
      dlg.bring_to_front
    else
      dlg.show
    end
  end

  # Перемещение выбранных объектов
  def self.apply_move(data)
    model     = Sketchup.active_model
    selection = model.selection
    return if selection.empty?

    ratio  = unit_ratio
    x      = data["x"].to_f * ratio
    y      = data["y"].to_f * ratio
    z      = data["z"].to_f * ratio
    anchor = data["anchor"] || "center"

    x_relative = data["x_mode"] == "relative"
    y_relative = data["y_mode"] == "relative"
    z_relative = data["z_mode"] == "relative"

    model.start_operation("Move to Absolute XYZ", true)

    begin
      selection.each do |entity|
        bb = entity.bounds

        # Определяем текущий origin сущности
        origin = if entity.is_a?(Sketchup::Group) || entity.is_a?(Sketchup::ComponentInstance)
                   entity.transformation.origin
                 else
                   bb.center
                 end

        # Z-смещение от origin до нужной точки привязки
        z_offset = case anchor
                   when "bottom" then bb.min.z - origin.z
                   when "top"    then bb.max.z - origin.z
                   else 0.0
                   end

        target_point = Geom::Point3d.new(
          x_relative ? origin.x + x : x,
          y_relative ? origin.y + y : y,
          z_relative ? origin.z + z : z - z_offset
        )

        vector = target_point - origin
        entity.transform!(Geom::Transformation.translation(vector))
      end

      model.commit_operation

    rescue => e
      model.abort_operation
      raise e  # пробрасываем наверх — поймает callback и отправит в JS
    end
  end

end