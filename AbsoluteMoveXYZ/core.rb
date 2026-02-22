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
      <button onclick="applyData(false)" style="flex:1;height:40px;">
        Apply
      </button>
      <button onclick="applyData(true)" style="flex:1;height:40px;">
        OK
      </button>
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