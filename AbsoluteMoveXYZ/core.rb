# frozen_string_literal: true

module AbsoluteMoveXYZ
  PLUGIN_NAME = "AbsoluteMoveXYZ"

  # Создаём HTML блок для каждой оси
  def self.axis_block(axis)
    <<-HTML
      <label>#{axis}:</label>
      <input type="number" id="#{axis.downcase}_value" value="0" style="width:60px;">
      <select id="#{axis.downcase}_mode">
        <option value="absolute">Absolute</option>
        <option value="relative">Relative</option>
      </select>
      <br>
    HTML
  end

  # Блок выбора точки привязки объекта
  def self.anchor_block
    <<-HTML
      <label>Anchor:</label>
      <select id="anchor">
        <option value="bottom">Bottom</option>
        <option value="center" selected>Center</option>
        <option value="top">Top</option>
      </select>
      <br>
    HTML
  end

  # Создание диалога
  def self.create_dialog
    @dialog = UI::HtmlDialog.new(
      dialog_title: PLUGIN_NAME,
      preferences_key: "AbsoluteMoveXYZ",
      scrollable: false,
      resizable: false,
      width: 420,
      height: 420,
      style: UI::HtmlDialog::STYLE_DIALOG
    )

    html = <<-HTML
      <!DOCTYPE html>
      <html>
      <body style="font-family:sans-serif;padding:15px;">
        <h3>Absolute Coordinates</h3>
        #{axis_block("X")}
        #{axis_block("Y")}
        #{axis_block("Z")}
        <br>
        #{anchor_block}
        <div style="display:flex; gap:10px;">
          <button onclick="applyData(false)" style="flex:1;height:40px;"> Apply </button>
          <button onclick="applyData(true)" style="flex:1;height:40px;"> OK </button>
        </div>
        <script>
          function applyData(closeDialog){
            const data = {
              x: document.getElementById("x_value").value,
              x_mode: document.getElementById("x_mode").value,
              y: document.getElementById("y_value").value,
              y_mode: document.getElementById("y_mode").value,
              z: document.getElementById("z_value").value,
              z_mode: document.getElementById("z_mode").value,
              anchor: document.getElementById("anchor").value
            };
            window.apply(JSON.stringify(data));
            if(closeDialog){
              window.close();
            }
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

  # Запуск диалога
  def self.run
    create_dialog
    @dialog.show
  end

  # Метод перемещения выбранных объектов
  def self.apply_move(data)
    model = Sketchup.active_model
    selection = model.selection
    return if selection.empty?

    x = data["x"].to_f
    y = data["y"].to_f
    z = data["z"].to_f
    anchor = data["anchor"] || "center"

    model.start_operation("Move to Absolute XYZ", true)

    selection.each do |entity|
      # Определяем точку перемещения по anchor
      bb = entity.bounds
      origin = case anchor
               when "bottom"
                 Geom::Point3d.new(bb.center.x, bb.center.y, bb.min.z)
               when "top"
                 Geom::Point3d.new(bb.center.x, bb.center.y, bb.max.z)
               else # center
                 bb.center
               end

      # Для групп и компонентов используем их реальную origin
      if entity.is_a?(Sketchup::Group) || entity.is_a?(Sketchup::ComponentInstance)
        origin = entity.transformation.origin
        # Сдвиг по оси Z в зависимости от выбранного anchor
        z_offset = case anchor
                   when "bottom" then bb.min.z - bb.center.z
                   when "top"    then bb.max.z - bb.center.z
                   else 0
                   end
        target_point = Geom::Point3d.new(x, y, z - z_offset)
        vector = target_point - origin
      else
        target_point = Geom::Point3d.new(x, y, z)
        vector = target_point - origin
      end

      entity.transform!(Geom::Transformation.translation(vector))
    end

    model.commit_operation
  end
end