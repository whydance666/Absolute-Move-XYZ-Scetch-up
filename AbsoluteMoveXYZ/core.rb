module AbsoluteMoveXYZ
  PLUGIN_NAME = "AbsoluteMoveXYZ"

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

  def self.create_dialog
    @dialog = UI::HtmlDialog.new(
      dialog_title: PLUGIN_NAME,
      preferences_key: "AbsoluteMoveXYZ",
      scrollable: false,
      resizable: false,
      width: 420,
      height: 380,
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
              z_mode: document.getElementById("z_mode").value
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

  def self.run
    create_dialog
    @dialog.show
  end

  def self.apply_move(data)
    # Тут твоя логика перемещения объектов
    puts "Applying move: #{data}"
  end
end