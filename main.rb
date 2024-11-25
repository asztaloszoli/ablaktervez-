require 'sketchup.rb'
require 'json'
require 'securerandom'  # Importáljuk a SecureRandom modult

module WindowGenerator
  module Main
    # Public methods
    def self.show_dialog
      dlg = UI::HtmlDialog.new({
        :dialog_title => "Részletes Fa Ablak és Ajtó Tervező",
        :preferences_key => "com.windowgenerator.plugin",
        :scrollable => true,
        :resizable => true,
        :width => 800,
        :height => 600,
        :style => UI::HtmlDialog::STYLE_DIALOG
      })
    
      html_path = File.join(__dir__, 'dialog.html')
      dlg.set_file(html_path)
    
      # Inicializáljuk a komponensek listáját osztály változóként
      @@components_list = []  # Megváltoztattuk @ -ról @@ -ra
    
      # 1. Ajtó típus változás callback
      dlg.add_action_callback("doorTypeChanged") do |action_context, params|
        begin
          data = JSON.parse(params)
          door_type = data["doorType"]
          puts "Door type changed to: #{door_type}"
          
          if door_type == "Kétszárnyú"
            puts "Double door selected"
          else
            puts "Single door selected"
          end
        rescue => e
          puts "Error in doorTypeChanged callback: #{e.message}"
          puts e.backtrace.join("\n")
        end
      end
    
      # 2. Aszimmetrikus beállítások callback
      dlg.add_action_callback("updateAsymmetricSettings") do |action_context, params|
        begin
          data = JSON.parse(params)
          is_asymmetric = data["isAsymmetric"]
          
          puts "Asymmetric settings updated: #{is_asymmetric}"
          
          if is_asymmetric
            puts "Asymmetric configuration enabled"
          else
            puts "Symmetric configuration enabled"
          end
        rescue => e
          puts "Error in updateAsymmetricSettings callback: #{e.message}"
          puts e.backtrace.join("\n")
        end
      end
    
      # 3. Komponens generálás callback
      dlg.add_action_callback("generateComponents") do |action_context, params|
        begin
          puts "Kapott paraméterek: #{params}"
          params = JSON.parse(params)
          puts "Feldolgozott paraméterek: #{params}"

          element_type = params["element_type"]


          if element_type == "Ajtó"
            # Lokális változók létrehozása
            door_frame_wood_width = params["door_frame_wood_width"].to_f  # Ez volt undefined
            frame_wood_width = door_frame_wood_width  # Ez a változó kell a collect_door_components-nek
            frame_wood_thickness = params["door_frame_wood_thickness"].to_f
            frame_width = params["door_frame_width"].to_f
            frame_height = params["door_frame_height"].to_f
            door_sash_width_deduction = params["door_sash_width_deduction"].to_f  
            door_sash_height_deduction = params["door_sash_height_deduction"].to_f
            door_type = params["door_type"]
            quantity = params["door_count"].to_i
      
            tenon_length = params["tenon_length"].to_f
            door_frieze_width = params["door_frieze_width"].to_f
            door_frieze_thickness = params["door_frieze_thickness"].to_f
      
            lower_tenoned_width = params["lower_tenoned_width"].to_f
            lower_tenoned_thickness = params["lower_tenoned_thickness"].to_f
      
            middle_division_width = params["middle_division_width"].to_f
            middle_division_thickness = params["middle_division_thickness"].to_f
            horizontal_divisions = params["horizontal_divisions"].to_i
      
            upper_tenoned_width = params["upper_tenoned_width"].to_f
            upper_tenoned_thickness = params["upper_tenoned_thickness"].to_f
      
            vertical_division_width = params["vertical_division_width"].to_f
            vertical_division_thickness = params["vertical_division_thickness"].to_f
            vertical_divisions = params["vertical_divisions"].to_i
            use_aluminum_threshold = params["useAluminumThreshold"] == true || params["useAluminumThreshold"] == "true"
            manual_distances = params["manual_distances"]
            use_manual_distances = params["use_manual_distances"] == true
            manual_horizontal_positions = params["manual_horizontal_positions"]

          puts "Ajtó paraméterek:"
          puts "Tok anyag szélesség: #{frame_wood_width}, Tok anyag vastagság: #{frame_wood_thickness}"
          puts "Tok szélesség: #{frame_width}, Tok magasság: #{frame_height}"
          puts "Nyíló szélesség levonás: #{door_sash_width_deduction}, Magasság levonás: #{door_sash_height_deduction}"
          puts "Ajtó típus: #{door_type}"
          puts "Darabszám: #{quantity}"
          puts "Csap hossza: #{tenon_length}"
          puts "Ajtó fríz szélessége: #{door_frieze_width}, Vastagsága: #{door_frieze_thickness}"
          puts "Alsó csapos szélessége: #{lower_tenoned_width}, Vastagsága: #{lower_tenoned_thickness}"
          puts "Középső osztók száma: #{horizontal_divisions}, Szélessége: #{middle_division_width}, Vastagsága: #{middle_division_thickness}"
          puts "Felső csapos szélessége: #{upper_tenoned_width}, Vastagsága: #{upper_tenoned_thickness}"
          puts "Függőleges osztók száma: #{vertical_divisions}, Szélessége: #{vertical_division_width}, Vastagsága: #{vertical_division_thickness}"
          puts "Alumínium küszöb használata (konvertált érték): #{use_aluminum_threshold}"
          puts "Manual distances: #{manual_distances}"
          puts "Using manual distances: #{use_manual_distances}"
          puts "Manual horizontal positions: #{manual_horizontal_positions}"

          quantity.times do
            manual_horizontal_positions = params["manualHorizontalPositions"]
            manual_vertical_positions = params["manualVerticalPositions"]
            
            puts "Manual horizontal positions from params: #{manual_horizontal_positions.inspect}"
            puts "Manual vertical positions from params: #{manual_vertical_positions.inspect}"
            
            new_components = self.collect_door_components(
              frame_wood_width, frame_wood_thickness,
              frame_width, frame_height,
              door_sash_width_deduction, door_sash_height_deduction,
              tenon_length,
              door_frieze_width, door_frieze_thickness,
              lower_tenoned_width, lower_tenoned_thickness,
              middle_division_width, middle_division_thickness,
              upper_tenoned_width, upper_tenoned_thickness,
              vertical_division_width, vertical_division_thickness,
              vertical_divisions, horizontal_divisions,
              door_type,
              params["is_asymmetric"],
              params["main_wing_ratio"].to_f,
              use_aluminum_threshold,
              params["disable_narrow_wing_vertical_divisions"],
              nil, # manual_distances (már nem használjuk)
              true, # use_manual_distances
              manual_horizontal_positions,
              manual_vertical_positions
            )
            @@components_list << {
              element_type: element_type,
              frame_size: "#{frame_width} x #{frame_height}",
              components: new_components
            }
          end
        

        elsif element_type == "Ablak"
          # Ablak paraméterek beolvasása
          frame_wood_width = params["frame_wood_width"].to_f
          frame_wood_thickness = params["frame_wood_thickness"].to_f
          sash_wood_width = params["sash_wood_width"].to_f
          sash_wood_thickness = params["sash_wood_thickness"].to_f
          window_type = params["window_type"]
          frame_width = params["frame_width"].to_f
          frame_height = params["frame_height"].to_f
          sash_width_deduction = params["sash_width_deduction"].to_f
          sash_height_deduction = params["sash_height_deduction"].to_f
          sash_double_deduction = params["sash_double_deduction"].to_f
          quantity = params["window_count"].to_i

          puts "Ablak paraméterek:"
          puts "Tok anyag szélesség: #{frame_wood_width}, Tok anyag vastagság: #{frame_wood_thickness}"
          puts "Nyíló anyag szélesség: #{sash_wood_width}, Nyíló anyag vastagság: #{sash_wood_thickness}"
          puts "Ablak típus: #{window_type}"
          puts "Tok szélesség: #{frame_width}, Tok magasság: #{frame_height}"
          puts "Nyíló szélesség levonás: #{sash_width_deduction}, Magasság levonás: #{sash_height_deduction}"
          puts "Kétszárnyú/tokosztós levonás: #{sash_double_deduction}"
          puts "Darabszám: #{quantity}"

          # Ellenőrzések
          if [frame_wood_width, frame_wood_thickness, sash_wood_width, sash_wood_thickness,
              frame_width, frame_height, quantity].any?(&:zero?) || quantity < 1
            UI.messagebox("Kérjük, töltse ki az összes mezőt, és adjon meg érvényes darabszámot.")
            next
          end

          quantity.times do
            new_components = self.collect_window_components(
              frame_wood_width, frame_wood_thickness,
              sash_wood_width, sash_wood_thickness,
              window_type, frame_width, frame_height,
              sash_width_deduction, sash_height_deduction,
              sash_double_deduction
            )
            @@components_list << {
              element_type: "Ablak",
              window_type: window_type,
              frame_size: "#{frame_width} x #{frame_height}",
              components: new_components
            }
          end
        elsif element_type == "Beltéri ajtó"

          # Beltéri ajtó paraméterek beolvasása - módosított verzió az új ID-kkal
          frame_wood_width = params["door_frame_wood_width"].to_f
          frame_wood_thickness = params["door_frame_wood_thickness"].to_f
           frame_width = params["door_frame_width"].to_f
          frame_height = params["door_frame_height"].to_f
          door_sash_width_deduction = params["door_sash_width_deduction"].to_f
          door_sash_height_deduction = params["door_sash_height_deduction"].to_f
          quantity = params["door_count"].to_i

          tenon_length = params["tenon_length"].to_f
          door_frieze_width = params["door_frieze_width"].to_f
          door_frieze_thickness = params["door_frieze_thickness"].to_f

          lower_tenoned_width = params["lower_tenoned_width"].to_f
           lower_tenoned_thickness = params["lower_tenoned_thickness"].to_f

           middle_division_width = params["middle_division_width"].to_f
           middle_division_thickness = params["middle_division_thickness"].to_f
            horizontal_divisions = params["horizontal_divisions"].to_i

            upper_tenoned_width = params["upper_tenoned_width"].to_f
             upper_tenoned_thickness = params["upper_tenoned_thickness"].to_f

               vertical_division_width = params["vertical_division_width"].to_f
  vertical_division_thickness = params["vertical_division_thickness"].to_f
  vertical_divisions = params["vertical_divisions"].to_i

  puts "Beltéri ajtó paraméterek:"
  puts "Tok anyag szélesség: #{frame_wood_width}, Tok anyag vastagság: #{frame_wood_thickness}"
  puts "Tok szélesség: #{frame_width}, Tok magasság: #{frame_height}"
  puts "Nyíló szélesség levonás: #{door_sash_width_deduction}, Magasság levonás: #{door_sash_height_deduction}"
  puts "Darabszám: #{quantity}"

  # Ellenőrzések
  if [frame_wood_width, frame_wood_thickness, frame_width, frame_height, quantity,
      tenon_length, door_frieze_width, door_frieze_thickness,
      lower_tenoned_width, lower_tenoned_thickness,
      upper_tenoned_width, upper_tenoned_thickness,
      vertical_division_width, vertical_division_thickness].any?(&:zero?) || quantity < 1
    UI.messagebox("Kérjük, töltse ki az összes mezőt, és adjon meg érvényes darabszámot.")
    next
  end

  quantity.times do
    new_components = self.collect_interior_door_components(
      frame_wood_width, frame_wood_thickness,
      frame_width, frame_height,
      door_sash_width_deduction, door_sash_height_deduction,
      tenon_length,
      door_frieze_width, door_frieze_thickness,
      lower_tenoned_width, lower_tenoned_thickness,
      middle_division_width, middle_division_thickness,
      upper_tenoned_width, upper_tenoned_thickness,
      vertical_division_width, vertical_division_thickness,
      vertical_divisions, horizontal_divisions
            )
            @@components_list << {
              element_type: "Beltéri ajtó",
              frame_size: "#{frame_width} x #{frame_height}",
              components: new_components
            }
          end
      
        elsif element_type == "Villanyóra szekrény ajtó"
          # Villanyóra szekrény ajtó paraméterek beolvasása - használjuk a door_ előtagot
          frame_wood_width = params["door_frame_wood_width"].to_f
          frame_wood_thickness = params["door_frame_wood_thickness"].to_f
          frame_width = params["door_frame_width"].to_f
          frame_height = params["door_frame_height"].to_f
          door_sash_width_deduction = params["door_sash_width_deduction"].to_f
          door_sash_height_deduction = params["door_sash_height_deduction"].to_f
          quantity = params["door_count"].to_i
        
          tenon_length = params["tenon_length"].to_f
          door_frieze_width = params["door_frieze_width"].to_f
          door_frieze_thickness = params["door_frieze_thickness"].to_f
        
          lower_tenoned_width = params["lower_tenoned_width"].to_f
          lower_tenoned_thickness = params["lower_tenoned_thickness"].to_f
        
          middle_division_width = params["middle_division_width"].to_f
          middle_division_thickness = params["middle_division_thickness"].to_f
          horizontal_divisions = params["horizontal_divisions"].to_i
        
          upper_tenoned_width = params["upper_tenoned_width"].to_f
          upper_tenoned_thickness = params["upper_tenoned_thickness"].to_f
        
          vertical_division_width = params["vertical_division_width"].to_f
          vertical_division_thickness = params["vertical_division_thickness"].to_f
          vertical_divisions = params["vertical_divisions"].to_i
        
          puts "Villanyóra szekrény ajtó paraméterek:"
          puts "Tok anyag szélesség: #{frame_wood_width}, Tok anyag vastagság: #{frame_wood_thickness}"
          puts "Tok szélesség: #{frame_width}, Tok magasság: #{frame_height}"
          puts "Nyíló szélesség levonás: #{door_sash_width_deduction}, Magasság levonás: #{door_sash_height_deduction}"
          puts "Darabszám: #{quantity}"

          # Ellenőrzések
          if [frame_wood_width, frame_wood_thickness, frame_width, frame_height, quantity,
              tenon_length, door_frieze_width, door_frieze_thickness,
              lower_tenoned_width, lower_tenoned_thickness,
              upper_tenoned_width, upper_tenoned_thickness,
              vertical_division_width, vertical_division_thickness].any?(&:zero?) || quantity < 1
            UI.messagebox("Kérjük, töltse ki az összes mezőt, és adjon meg érvényes darabszámot.")
            next
          end
        
          quantity.times do
            new_components = self.collect_electric_box_door_components(
              frame_wood_width, frame_wood_thickness,
              frame_width, frame_height,
              door_sash_width_deduction, door_sash_height_deduction,
              tenon_length,
              door_frieze_width, door_frieze_thickness,
              lower_tenoned_width, lower_tenoned_thickness,
              middle_division_width, middle_division_thickness,
              upper_tenoned_width, upper_tenoned_thickness,
              vertical_division_width, vertical_division_thickness,
              vertical_divisions, horizontal_divisions
            )
            @@components_list << {
              element_type: "Villanyóra szekrény ajtó",
              frame_size: "#{frame_width} x #{frame_height}",
              components: new_components
            }
          end
  
        else
          UI.messagebox("Ismeretlen elem típus: #{element_type}")
        end

        formatted_list = format_components_list(@@components_list)

        puts "Generált komponensek: #{formatted_list.inspect}"

        dlg.execute_script("updateComponentList(#{formatted_list.to_json})")
        UI.messagebox("A komponensek sikeresen generálva!")
      rescue => e
        puts "Hiba történt a komponensek generálása során: #{e.message}"
        puts e.backtrace.join("\n")
        UI.messagebox("Hiba történt a komponensek generálása során. Kérjük, ellenőrizze a Ruby Console-t a részletekért.")
      end
    end

   # Lista mentése callback
   dlg.add_action_callback("saveComponentList") do |action_context, name, html_content|
     begin
       # Fájl mentési párbeszédablak megnyitása
       save_path = UI.savepanel("Mentés másként", "", "#{name}.html")
       if save_path
         File.write(save_path, html_content)
         puts "Lista sikeresen mentve: #{save_path}"
         dlg.execute_script("updateSaveStatus('Lista mentve!');")
       end
     rescue => e
       puts "Hiba történt a mentés során: #{e.message}"
       UI.messagebox("Hiba történt a mentés során!")
     end
   end
   
   # Nyomtatás callback
   dlg.add_action_callback("printComponentList") do |action_context, html_content|
     begin
       # Ideiglenes fájl létrehozása a nyomtatáshoz
       temp_path = File.join(Dir.tmpdir, "print_preview_#{Time.now.to_i}.html")
       File.write(temp_path, html_content)
       
       # Fájl megnyitása az alapértelmezett böngészőben
       UI.openURL("file:///#{temp_path}")
       
       puts "Nyomtatási előnézet megnyitva"
     rescue => e
       puts "Hiba történt a nyomtatás során: #{e.message}"
       UI.messagebox("Hiba történt a nyomtatási előnézet létrehozása során!")
     end
   end
    
    # Elemek törlése callback
    dlg.add_action_callback("deleteWindow") do |action_context, index|
      index = index.to_i
      if index >= 0 && index < @@components_list.length
        @@components_list.delete_at(index)
        formatted_list = format_components_list(@@components_list)
        dlg.execute_script("updateComponentList(#{formatted_list.to_json})")
        puts "Elem törölve az indexnél: #{index}"
      else
        puts "Érvénytelen index a törléshez: #{index}"
      end
    end

    # Alkatrészek generálása callback
    dlg.add_action_callback("generateWindowParts") do |action_context|
      begin
        self.create_components_from_list(@@components_list)
        UI.messagebox("Az alkatrészek sikeresen létrehozva!")
      rescue => e
        puts "Hiba történt az alkatrészek létrehozása során: #{e.message}"
        puts e.backtrace.join("\n")
        UI.messagebox("Hiba történt az alkatrészek létrehozása során. Kérjük, ellenőrizze a Ruby Console-t a részletekért.")
      end
    end

    # Bezárás előtti ellenőrzés callback
    dlg.add_action_callback("checkUnsavedChanges") do |action_context|
      begin
        result = UI.messagebox('Van nem mentett elemlista. Szeretné menteni?', MB_YESNO)
        if result == IDYES
          # Kérjük be a mentés nevét
          save_name = UI.inputbox(['Adja meg a mentés nevét:'], [''], 'Mentés névadás')[0]
          if save_name && !save_name.empty?
            # Ha a felhasználó megadott egy nevet, küldjük el a JavaScript-nek
            dlg.execute_script("saveListWithName('#{save_name}');")
          end
        end
      rescue => e
        puts "Error in checkUnsavedChanges callback: #{e.message}"
        puts e.backtrace.join("\n")
      end
    end

    private
    
    def self.generate_printable_html(components, title = nil)
        # HTML generálása
        html = <<-HTML
            <!DOCTYPE html>
            <html>
            <head>
                <meta charset="UTF-8">
                <title>#{title || 'Elemlista'}</title>
                <style>
                    body { 
                        font-family: Arial, sans-serif; 
                        margin: 5px;
                        line-height: 1.3;
                        font-size: 12px;
                    }
                    h1 {
                        font-size: 16px;
                        margin: 10px 0;
                    }
                    .component-list {
                        margin: 10px;
                        column-count: 2;
                        column-gap: 20px;
                    }
                    .component-item {
                        padding: 3px 5px;
                        border-bottom: 1px solid #eee;
                        break-inside: avoid;
                    }
                    .print-button {
                        display: block;
                        margin: 10px auto;
                        padding: 8px 16px;
                        background-color: #4CAF50;
                        color: white;
                        border: none;
                        border-radius: 4px;
                        cursor: pointer;
                        font-size: 14px;
                    }
                    .print-button:hover {
                        background-color: #45a049;
                    }
                    @media print {
                        .print-button {
                            display: none;
                        }
                        body {
                            margin: 0;
                            padding: 5mm;
                        }
                        @page {
                            size: A4;
                            margin: 5mm;
                        }
                        .component-list {
                            margin: 5px;
                        }
                        .component-item {
                            padding: 2px 4px;
                        }
                    }
                </style>
            </head>
            <body>
                #{title ? "<h1>#{title}</h1>" : ""}
                <button onclick="window.print()" class="print-button">Nyomtatás</button>
                <div class="component-list">
        HTML

        # Ellenőrizzük, hogy a components egy tömb-e
        if components.is_a?(Array)
            components.each do |component|
                if component.is_a?(Array) && component.length >= 4
                    name, length, width, thickness = component
                    html += "<div class=\"component-item\">#{name}: #{length}x#{width}x#{thickness}mm</div>\n"
                else
                    html += "<div class=\"component-item\">#{component}</div>\n"
                end
            end
        else
            html += "<div class=\"component-item\">Nincs generált elem.</div>\n"
        end

        html += <<-HTML
                </div>
            </body>
            </html>
        HTML

        return html
    end
   
    dlg.show
  end

  # Formázó metódus
  def self.format_components_list(components_list)
    formatted_list = []

    components_list.each_with_index do |element, index|
      element_type = element[:element_type]
      formatted_list << "#{element_type} #{index + 1}"
      formatted_list << "Méret: #{element[:frame_size]}"
      formatted_list << "Típus: #{element[:window_type]}" if element[:window_type]
      formatted_list << "<button onclick='deleteWindow(#{index})'>Törlés</button>"
      formatted_list << ""

      components = element[:components]
      if components.empty?
        formatted_list << "Nincsenek komponensek."
        next
      end

      components.each do |component|
        formatted_list << "#{component[0]}: #{component[1]} x #{component[2]} x #{component[3]}"
      end

      formatted_list << ""
    end

    formatted_list
  end

  def self.collect_door_components(
    frame_wood_width, frame_wood_thickness,
    frame_width, frame_height,
    door_sash_width_deduction, door_sash_height_deduction,
    tenon_length,
    door_frieze_width, door_frieze_thickness,
    lower_tenoned_width, lower_tenoned_thickness,
    middle_division_width, middle_division_thickness,
    upper_tenoned_width, upper_tenoned_thickness,
    vertical_division_width, vertical_division_thickness,
    vertical_divisions, horizontal_divisions,
    door_type,
    is_asymmetric = false,
    main_wing_ratio = 50,
    use_aluminum_threshold = false,  # Új paraméter alapértelmezett értékkel
    disable_narrow_wing_vertical_divisions = false, # Új paraméter
    manual_distances = nil,  # új paraméter
    use_manual_distances = false,  # új paraméter
    manual_horizontal_positions = nil,  # új paraméter
    manual_vertical_positions = nil  # új paraméter
  )
    # Konvertáljuk a paramétereket számokká
    frame_wood_width = frame_wood_width.to_f
    frame_wood_thickness = frame_wood_thickness.to_f
    frame_width = frame_width.to_f
    frame_height = frame_height.to_f
    door_sash_width_deduction = door_sash_width_deduction.to_f
    door_sash_height_deduction = door_sash_height_deduction.to_f
    tenon_length = tenon_length.to_f
    door_frieze_width = door_frieze_width.to_f
    door_frieze_thickness = door_frieze_thickness.to_f
    lower_tenoned_width = lower_tenoned_width.to_f
    lower_tenoned_thickness = lower_tenoned_thickness.to_f
    middle_division_width = middle_division_width.to_f
    middle_division_thickness = middle_division_thickness.to_f
    upper_tenoned_width = upper_tenoned_width.to_f
    upper_tenoned_thickness = upper_tenoned_thickness.to_f
    vertical_division_width = vertical_division_width.to_f
    vertical_division_thickness = vertical_division_thickness.to_f
    vertical_divisions = vertical_divisions.to_i
    horizontal_divisions = horizontal_divisions.to_i
    main_wing_ratio = main_wing_ratio.to_f
    
    # Ellenőrizzük, hogy van-e manuális távolság és megfelelő-e a hossza
    if manual_horizontal_positions && manual_horizontal_positions.length == horizontal_divisions
      puts "Using manual horizontal positions: #{manual_horizontal_positions.inspect}"
      use_manual_distances = true
      manual_distances = manual_horizontal_positions
    else
      puts "Using automatic calculation (no valid manual positions provided)"
      use_manual_distances = false
      manual_distances = nil
    end
    
    puts "Manual horizontal positions: #{manual_horizontal_positions.inspect}"
    puts "Manual distances after conversion: #{manual_distances.inspect}"
    puts "Using manual distances: #{use_manual_distances}"
    
    components = []
  
    # Tok komponensek - most már figyelembe vesszük az alumínium küszöb használatát
  if use_aluminum_threshold
    puts "Skipping bottom frame component due to aluminum threshold"
  else
    components << ["Tok alsó vízszintes", frame_width, frame_wood_width, frame_wood_thickness]
    puts "Added bottom frame component"
  end
  components << ["Tok felső vízszintes", frame_width, frame_wood_width, frame_wood_thickness]
  components << ["Tok bal oldali függőleges", frame_height, frame_wood_width, frame_wood_thickness]
  components << ["Tok jobb oldali függőleges", frame_height, frame_wood_width, frame_wood_thickness]
  
    # Nyíló külső méretei
    total_sash_width = frame_width - door_sash_width_deduction
    sash_external_height = frame_height - door_sash_height_deduction
  
    puts "\n=== Alap méretek ==="
    puts "Total sash width (teljes nyílószélesség): #{total_sash_width}"
    puts "Sash external height: #{sash_external_height}"
  
    # Az ajtó típusának ellenőrzése és az overlap_adjustment beállítása
    if door_type == "Kétszárnyú"
      overlap_adjustment = 13.0  # Kétszárnyú ajtó esetén 13 mm-rel növeljük a csapos elemek hosszát
    else
      overlap_adjustment = 0.0
    end

    if door_type == "Kétszárnyú"
      if is_asymmetric
        puts "\n=== Aszimmetrikus számítások ==="
        wider_ratio = main_wing_ratio / 100.0
        narrower_ratio = 1.0 - wider_ratio
        
        puts "Wider ratio: #{wider_ratio} (#{main_wing_ratio}%)"
        puts "Narrower ratio: #{narrower_ratio} (#{(narrower_ratio * 100).round(1)}%)"
        
        # Szárnyak külső szélességének számítása
        wider_sash_width = total_sash_width * wider_ratio
        narrower_sash_width = total_sash_width * narrower_ratio
  
        puts "\n=== Szárnyak külső szélessége ==="
        puts "Wider sash width: #{wider_sash_width.round(1)}"
        puts "Narrower sash width: #{narrower_sash_width.round(1)}"
  
        # Szárnyak belső szélességének számítása
        wider_sash_internal_width = wider_sash_width - (2 * door_frieze_width)
        narrower_sash_internal_width = narrower_sash_width - (2 * door_frieze_width)
  
        puts "\n=== Szárnyak belső szélessége ==="
        puts "Wider internal width: #{wider_sash_internal_width.round(1)}"
        puts "Narrower internal width: #{narrower_sash_internal_width.round(1)}"
  
        # Szélesebb szárny komponensei
        components << ["Szélesebb szárny fríz bal", sash_external_height, door_frieze_width, door_frieze_thickness]
        components << ["Szélesebb szárny fríz jobb", sash_external_height, door_frieze_width, door_frieze_thickness]
        
        wider_tenoned_length = wider_sash_internal_width + (2 * tenon_length) + overlap_adjustment
        components << ["Szélesebb szárny alsó csapos", wider_tenoned_length, lower_tenoned_width, lower_tenoned_thickness]
        components << ["Szélesebb szárny felső csapos", wider_tenoned_length, upper_tenoned_width, upper_tenoned_thickness]
  
        puts "\n=== Szélesebb szárny csapos hossza ==="
        puts "Wider tenoned length: #{wider_tenoned_length.round(1)}"
  
        # Keskenyebb szárny komponensei
        components << ["Keskenyebb szárny fríz bal", sash_external_height, door_frieze_width, door_frieze_thickness]
        components << ["Keskenyebb szárny fríz jobb", sash_external_height, door_frieze_width, door_frieze_thickness]
        
        narrower_tenoned_length = narrower_sash_internal_width + (2 * tenon_length) + overlap_adjustment
        components << ["Keskenyebb szárny alsó csapos", narrower_tenoned_length, lower_tenoned_width, lower_tenoned_thickness]
        components << ["Keskenyebb szárny felső csapos", narrower_tenoned_length, upper_tenoned_width, upper_tenoned_thickness]
  
        puts "Narrower tenoned length: #{narrower_tenoned_length.round(1)}"
  
        # Vízszintes osztók mindkét szárnyhoz
        if horizontal_divisions > 0
          puts "\n=== Vízszintes osztók ==="
          door_inner_height = sash_external_height - lower_tenoned_width - upper_tenoned_width
            
          if use_manual_distances && manual_horizontal_positions && manual_horizontal_positions.length == horizontal_divisions
            puts "\nManuális számítás részletei:"
            puts "Tok magasság: #{frame_height}mm"
            puts "Nyíló külső magasság: #{sash_external_height}mm"
            puts "Belső magasság (door_inner_height): #{door_inner_height}mm"
            
            manual_horizontal_positions.each_with_index do |distance, i|
              # Szélesebb szárny osztói
              wider_division_length = wider_sash_internal_width + (2 * tenon_length) + overlap_adjustment
              components << ["Szélesebb szárny vízszintes osztó #{i + 1}", 
                            wider_division_length, 
                            middle_division_width, 
                            middle_division_thickness]
              puts "Manual wider horizontal division #{i + 1} at distance: #{distance}"

              # Keskenyebb szárny osztói
              narrower_division_length = narrower_sash_internal_width + (2 * tenon_length) + overlap_adjustment
              components << ["Keskenyebb szárny vízszintes osztó #{i + 1}", 
                            narrower_division_length, 
                            middle_division_width, 
                            middle_division_thickness]
              puts "Manual narrower horizontal division #{i + 1} at distance: #{distance}"
            end
          else
            puts "Using automatic calculation for horizontal divisions"
            total_horizontal_division_height = horizontal_divisions * middle_division_width
            available_height = door_inner_height - total_horizontal_division_height
            segment_height = available_height / (horizontal_divisions + 1)
              
            horizontal_divisions.times do |i|
              # Szélesebb szárny osztói
              wider_division_length = wider_sash_internal_width + (2 * tenon_length) + overlap_adjustment
              components << ["Szélesebb szárny vízszintes osztó #{i + 1}", 
                            wider_division_length, 
                            middle_division_width, 
                            middle_division_thickness]
              puts "Automatic wider horizontal division #{i + 1} at height: #{segment_height * (i + 1)}"

              # Keskenyebb szárny osztói
              narrower_division_length = narrower_sash_internal_width + (2 * tenon_length) + overlap_adjustment
              components << ["Keskenyebb szárny vízszintes osztó #{i + 1}", 
                            narrower_division_length, 
                            middle_division_width, 
                            middle_division_thickness]
              puts "Automatic narrower horizontal division #{i + 1} at height: #{segment_height * (i + 1)}"
            end
          end
        end
          
        # Függőleges osztók
        if vertical_divisions > 0
          puts "\n=== Függőleges osztók ==="
          door_inner_height = sash_external_height - lower_tenoned_width - upper_tenoned_width
            
          if use_manual_distances && manual_horizontal_positions && manual_horizontal_positions.length == horizontal_divisions
            puts "\nManuális számítás részletei:"
            puts "Tok magasság: #{frame_height}mm"
            puts "Nyíló külső magasság: #{sash_external_height}mm"
            puts "Belső magasság (door_inner_height): #{door_inner_height}mm"
            
            manual_horizontal_positions.each_with_index do |distance, i|
              # Első szegmens (alsó csapostól az első osztóig)
              first_segment_height = manual_horizontal_positions[0] + (2 * tenon_length)
              puts "\nElső szegmens számítása:"
              puts "Manuális távolság: #{manual_horizontal_positions[0]}mm"
              puts "Csap hossza (2x): #{2 * tenon_length}mm"
              puts "Első szegmens teljes hossza: #{first_segment_height}mm"
              
              components << ["Függőleges osztó #{i + 1} - szegmens 1", 
                            first_segment_height, 
                            vertical_division_width, 
                            vertical_division_thickness]
              
              # Utolsó szegmens számítása
              remaining_height = door_inner_height - manual_horizontal_positions[0] - (horizontal_divisions * middle_division_width)
              last_segment_height = remaining_height + (2 * tenon_length)
              
              puts "\nUtolsó szegmens számítása:"
              puts "Belső magasság: #{door_inner_height}mm"
              puts "Levonás (manuális távolság): #{manual_horizontal_positions[0]}mm"
              puts "Levonás (vízszintes osztók): #{horizontal_divisions * middle_division_width}mm"
              puts "Maradék magasság: #{remaining_height}mm"
              puts "Utolsó szegmens teljes hossza: #{last_segment_height}mm"
              
              components << ["Függőleges osztó #{i + 1} - utolsó szegmens", 
                            last_segment_height, 
                            vertical_division_width, 
                            vertical_division_thickness]
            end
          else
            puts "Using automatic calculation for vertical divisions"
            total_horizontal_division_height = horizontal_divisions * middle_division_width
            available_height = door_inner_height - total_horizontal_division_height
            segment_height = available_height / (horizontal_divisions + 1)
            
            vertical_divisions.times do |v_index|
              (horizontal_divisions + 1).times do |segment_index|
                segment_height_with_tenon = segment_height + 2 * tenon_length
                components << ["Függőleges osztó #{v_index + 1} - szegmens #{segment_index + 1}", 
                              segment_height_with_tenon, 
                              vertical_division_width, 
                              vertical_division_thickness]
              end
            end
          end
        end
      else
        # Szimmetrikus kétszárnyú ajtó esetén
        sash_external_width = total_sash_width / 2
        sash_internal_width = sash_external_width - (2 * door_frieze_width)
        sash_internal_height = sash_external_height - (lower_tenoned_width + upper_tenoned_width)
        
        ["Első", "Második"].each do |prefix|
          # Fríz elemek
          components << ["#{prefix} szárny fríz bal", sash_external_height, door_frieze_width, door_frieze_thickness]
          components << ["#{prefix} szárny fríz jobb", sash_external_height, door_frieze_width, door_frieze_thickness]
          
          # Csapos elemek
          tenoned_length = sash_internal_width + (2 * tenon_length) + overlap_adjustment
          components << ["#{prefix} szárny alsó csapos", tenoned_length, lower_tenoned_width, lower_tenoned_thickness]
          components << ["#{prefix} szárny felső csapos", tenoned_length, upper_tenoned_width, upper_tenoned_thickness]
          
          # Vízszintes osztók
          if horizontal_divisions > 0
            if use_manual_distances && manual_horizontal_positions && manual_horizontal_positions.length == horizontal_divisions
              puts "\nVízszintes osztók manuális távolságokkal (#{prefix} szárny):"
              manual_horizontal_positions.each_with_index do |distance, i|
                division_length = sash_internal_width + (2 * tenon_length) + overlap_adjustment
                components << ["#{prefix} szárny vízszintes osztó #{i + 1}", 
                              division_length, 
                              middle_division_width, 
                              middle_division_thickness]
                puts "#{prefix} szárny #{i + 1}. osztó távolsága: #{distance}mm"
              end
            end
          end
          
          # Függőleges osztók
          if vertical_divisions > 0
            door_inner_height = sash_external_height - lower_tenoned_width - upper_tenoned_width
            if use_manual_distances && manual_horizontal_positions && manual_horizontal_positions.length == horizontal_divisions
              puts "\nFüggőleges osztók számítása (#{prefix} szárny):"
              puts "Belső magasság: #{door_inner_height}mm"
              
              vertical_divisions.times do |v_index|
                # Első szegmens (felső csapostól az első vízszintes osztóig)
                first_segment_height = manual_horizontal_positions[0] + (2 * tenon_length)
                puts "\nElső szegmens számítása:"
                puts "Manuális távolság: #{manual_horizontal_positions[0]}mm"
                puts "Csap hossza (2x): #{2 * tenon_length}mm"
                puts "Első szegmens teljes hossza: #{first_segment_height}mm"
                
                components << ["#{prefix} szárny függőleges osztó #{v_index + 1} - szegmens 1", 
                              first_segment_height, 
                              vertical_division_width, 
                              vertical_division_thickness]
                
                # Utolsó szegmens számítása
                remaining_height = door_inner_height - manual_horizontal_positions[0] - (horizontal_divisions * middle_division_width)
                last_segment_height = remaining_height + (2 * tenon_length)
                
                puts "\nUtolsó szegmens számítása:"
                puts "Belső magasság: #{door_inner_height}mm"
                puts "Levonás (manuális távolság): #{manual_horizontal_positions[0]}mm"
                puts "Levonás (vízszintes osztók): #{horizontal_divisions * middle_division_width}mm"
                puts "Maradék magasság: #{remaining_height}mm"
                puts "Utolsó szegmens teljes hossza: #{last_segment_height}mm"
                
                components << ["#{prefix} szárny függőleges osztó #{v_index + 1} - utolsó szegmens", 
                              last_segment_height, 
                              vertical_division_width, 
                              vertical_division_thickness]
              end
            end
          end
        end
      end
    else
      # Egyszárnyú ajtó esetén
      sash_external_width = frame_width - (2 * sash_width_deduction)
      sash_external_height = frame_height - sash_height_deduction

      # Ajtó belméret számítása
      total_sash_width = frame_width - door_sash_width_deduction
      sash_external_height = frame_height - door_sash_height_deduction
  
      puts "\n=== Alap méretek ==="
      puts "Total sash width (teljes nyílószélesség): #{total_sash_width}"
      puts "Sash external height: #{sash_external_height}"
  
      # Ajtó belméret számítása
      sash_internal_width = sash_external_width - (2 * door_frieze_width)
      sash_internal_height = sash_external_height - (lower_tenoned_width + upper_tenoned_width)

      # Ajtó belméret számítása
      door_inner_height = sash_internal_height

      # Csapos elemek hossza
      lower_tenoned_length = sash_internal_width + (2 * tenon_length)
      upper_tenoned_length = sash_internal_width + (2 * tenon_length)

      # Ajtó fríz
      components << ["Ajtó fríz bal", sash_external_height, door_frieze_width, door_frieze_thickness]
      components << ["Ajtó fríz jobb", sash_external_height, door_frieze_width, door_frieze_thickness]

      # Alsó és felső csapos
      components << ["Alsó csapos", lower_tenoned_length, lower_tenoned_width, lower_tenoned_thickness]
      components << ["Felső csapos", upper_tenoned_length, upper_tenoned_width, upper_tenoned_thickness]

      # Vízszintes osztók
      if horizontal_divisions > 0
        if use_manual_distances && manual_horizontal_positions && manual_horizontal_positions.length == horizontal_divisions
          puts "Using manual distances for horizontal divisions"
          manual_horizontal_positions.each_with_index do |distance, i|
            division_length = sash_internal_width + (2 * tenon_length)
            components << ["Vízszintes osztó #{i + 1}", division_length, middle_division_width, middle_division_thickness]
            puts "Manual horizontal division #{i + 1} at distance: #{distance}"
          end
        else
          puts "Using automatic calculation for horizontal divisions"
          door_inner_height = sash_internal_height
          total_horizontal_division_height = horizontal_divisions * middle_division_width
          available_height = door_inner_height - total_horizontal_division_height
          segment_height = available_height / (horizontal_divisions + 1)
          
          horizontal_divisions.times do |i|
            division_length = sash_internal_width + (2 * tenon_length)
            components << ["Vízszintes osztó #{i + 1}", division_length, middle_division_width, middle_division_thickness]
            puts "Automatic horizontal division #{i + 1} at height: #{segment_height * (i + 1)}"
          end
        end
      end
      
      # Függőleges osztók
      if vertical_divisions > 0
        door_inner_height = sash_external_height - lower_tenoned_width - upper_tenoned_width
        if use_manual_distances && manual_horizontal_positions && manual_horizontal_positions.length == horizontal_divisions
          puts "\nManuális számítás részletei:"
          puts "Tok magasság: #{frame_height}mm"
          puts "Nyíló külső magasság: #{sash_external_height}mm"
          puts "Belső magasság (door_inner_height): #{door_inner_height}mm"
          
          vertical_divisions.times do |v_index|
            # Első szegmens (alsó csapostól az első osztóig)
            first_segment_height = manual_horizontal_positions[0] + (2 * tenon_length)
            puts "\nElső szegmens számítása:"
            puts "Manuális távolság: #{manual_horizontal_positions[0]}mm"
            puts "Csap hossza (2x): #{2 * tenon_length}mm"
            puts "Első szegmens teljes hossza: #{first_segment_height}mm"
            
            components << ["Függőleges osztó #{v_index + 1} - szegmens 1", 
                          first_segment_height, 
                          vertical_division_width, 
                          vertical_division_thickness]
            
            # Utolsó szegmens számítása
            remaining_height = door_inner_height - manual_horizontal_positions[0] - (horizontal_divisions * middle_division_width)
            last_segment_height = remaining_height + (2 * tenon_length)
            
            puts "\nUtolsó szegmens számítása:"
            puts "Belső magasság: #{door_inner_height}mm"
            puts "Levonás (manuális távolság): #{manual_horizontal_positions[0]}mm"
            puts "Levonás (vízszintes osztók): #{horizontal_divisions * middle_division_width}mm"
            puts "Maradék magasság: #{remaining_height}mm"
            puts "Utolsó szegmens teljes hossza: #{last_segment_height}mm"
            
            components << ["Függőleges osztó #{v_index + 1} - utolsó szegmens", 
                          last_segment_height, 
                          vertical_division_width, 
                          vertical_division_thickness]
          end
        else
          puts "Using automatic calculation for vertical divisions"
          total_horizontal_division_height = horizontal_divisions * middle_division_width
          available_height = door_inner_height - total_horizontal_division_height
          segment_height = available_height / (horizontal_divisions + 1)
          
          vertical_divisions.times do |v_index|
            (horizontal_divisions + 1).times do |segment_index|
              segment_height_with_tenon = segment_height + 2 * tenon_length
              components << ["Függőleges osztó #{v_index + 1} - szegmens #{segment_index + 1}", 
                            segment_height_with_tenon, 
                            vertical_division_width, 
                            vertical_division_thickness]
            end
          end
        end
      end
    end
  
    puts "\n=== Komponensek generálása befejezve ==="
    puts "Összes komponens száma: #{components.length}"
    components
  end

    def self.collect_window_components(
      frame_wood_width, frame_wood_thickness,
      sash_wood_width, sash_wood_thickness,
      window_type, frame_width, frame_height,
      sash_width_deduction, sash_height_deduction,
      sash_double_deduction
    )
      components = []

      # Tok komponensek generálása minden típushoz
      components << ["Tok alsó vízszintes", frame_width, frame_wood_width, frame_wood_thickness]
      components << ["Tok felső vízszintes", frame_width, frame_wood_width, frame_wood_thickness]
      components << ["Tok bal oldali függőleges", frame_height, frame_wood_width, frame_wood_thickness]
      components << ["Tok jobb oldali függőleges", frame_height, frame_wood_width, frame_wood_thickness]

      puts "Tok komponensek generálása..."

      if window_type != "Üvegfal"
        sash_width = frame_width - sash_width_deduction
        sash_height = frame_height - sash_height_deduction

        if window_type == "Kétszárnyú" || window_type == "Tokosztós"
          sash_width = frame_width - 88  # Levonunk 88mm-t
          sash_width = (sash_width + 38) / 2  # Hozzáadunk 38mm-t és felezzük

          
        end

        components << ["Nyíló alsó vízszintes", sash_width, sash_wood_width, sash_wood_thickness]
        components << ["Nyíló felső vízszintes", sash_width, sash_wood_width, sash_wood_thickness]
        components << ["Nyíló bal oldali függőleges", sash_height, sash_wood_width, sash_wood_thickness]
        components << ["Nyíló jobb oldali függőleges", sash_height, sash_wood_width, sash_wood_thickness]

        puts "Nyíló komponensek generálása..."

        if window_type == "Kétszárnyú"
          components << ["Második szárny alsó vízszintes", sash_width, sash_wood_width, sash_wood_thickness]
          components << ["Második szárny felső vízszintes", sash_width, sash_wood_width, sash_wood_thickness]
          components << ["Második szárny bal oldali függőleges", sash_height, sash_wood_width, sash_wood_thickness]
          components << ["Második szárny jobb oldali függőleges", sash_height, sash_wood_width, sash_wood_thickness]
        elsif window_type == "Tokosztós"
          tokosztó_length = frame_height - 2 * frame_wood_width
          components << ["Függőleges tokosztó", tokosztó_length, frame_wood_width, frame_wood_thickness]
        end
      end

      puts "Ablak komponensek összegyűjtése befejezve."

      components
    end
    # Beltéri ajtó komponensek számítása
def self.collect_interior_door_components(
  frame_wood_width, frame_wood_thickness,
  frame_width, frame_height,
  sash_width_deduction, sash_height_deduction,
  tenon_length,
  door_frieze_width, door_frieze_thickness,
  lower_tenoned_width, lower_tenoned_thickness,
  middle_division_width, middle_division_thickness,
  upper_tenoned_width, upper_tenoned_thickness,
  vertical_division_width, vertical_division_thickness,
  vertical_divisions, horizontal_divisions,
  door_type = "Egyszárnyú"  # Kétszárnyú ajtó támogatásához szükséges paraméter
)
  components = []

  # Tok komponensek
  components << ["Beltéri tok alsó", frame_width, frame_wood_width, frame_wood_thickness]
  components << ["Beltéri tok felső", frame_width, frame_wood_width, frame_wood_thickness]
  components << ["Beltéri tok bal", frame_height, frame_wood_width, frame_wood_thickness]
  components << ["Beltéri tok jobb", frame_height, frame_wood_width, frame_wood_thickness]

  # Nyíló külső méretei
  sash_external_width = frame_width - (2 * sash_width_deduction)
  sash_external_height = frame_height - sash_height_deduction

  # Kétszárnyú ajtó esetén a szélességet felezzük
  # Ez az ablakoknál használt logika alapján készült
  if door_type == "Kétszárnyú"
    sash_external_width = sash_external_width / 2
  end

  # Nyíló belső méretei
  sash_internal_width = sash_external_width - (2 * door_frieze_width)
  sash_internal_height = sash_external_height - (lower_tenoned_width + upper_tenoned_width)

  # Ajtó belméret számítása
  door_inner_height = sash_internal_height

  # Csapos elemek hossza
  lower_tenoned_length = sash_internal_width + (2 * tenon_length)
  upper_tenoned_length = sash_internal_width + (2 * tenon_length)

  # Ajtó fríz
  components << ["Beltéri fríz bal", sash_external_height, door_frieze_width, door_frieze_thickness]
  components << ["Beltéri fríz jobb", sash_external_height, door_frieze_width, door_frieze_thickness]

  # Alsó és felső csapos
  components << ["Beltéri alsó csapos", lower_tenoned_length, lower_tenoned_width, lower_tenoned_thickness]
  components << ["Beltéri felső csapos", upper_tenoned_length, upper_tenoned_width, upper_tenoned_thickness]

  # Középső osztók
  if horizontal_divisions > 0
    segment_height = (door_inner_height - (horizontal_divisions * middle_division_width)) / (horizontal_divisions + 1)
    
    horizontal_divisions.times do |i|
      division_length = sash_internal_width + (2 * tenon_length)
      components << ["Beltéri vízszintes osztó #{i + 1}", division_length, middle_division_width, middle_division_thickness]
    end
  end

  # Függőleges osztók
  if vertical_divisions > 0
    (horizontal_divisions + 1).times do |segment_index|
      segment_height = if segment_index == 0 || segment_index == horizontal_divisions
        (door_inner_height - (horizontal_divisions * middle_division_width)) / (horizontal_divisions + 1)
      else
        (door_inner_height - (horizontal_divisions * middle_division_width)) / (horizontal_divisions + 1)
      end
      
      vertical_divisions.times do |v_index|
        components << ["Beltéri függőleges osztó #{v_index + 1} - szegmens #{segment_index + 1}", 
                      segment_height + (2 * tenon_length),
                      vertical_division_width, 
                      vertical_division_thickness]
      end
    end
  end

  # Kétszárnyú ajtó esetén a második szárny komponenseinek hozzáadása
  # Ez az ablakoknál használt logika alapján készült
  if door_type == "Kétszárnyú"
    # Második szárny fríz elemei
    components << ["Második szárny beltéri fríz bal", sash_external_height, door_frieze_width, door_frieze_thickness]
    components << ["Második szárny beltéri fríz jobb", sash_external_height, door_frieze_width, door_frieze_thickness]

    # Második szárny csapos elemei
    components << ["Második szárny beltéri alsó csapos", lower_tenoned_length, lower_tenoned_width, lower_tenoned_thickness]
    components << ["Második szárny beltéri felső csapos", upper_tenoned_length, upper_tenoned_width, upper_tenoned_thickness]

    # Második szárny osztói
    if horizontal_divisions > 0
      horizontal_divisions.times do |i|
        division_length = sash_internal_width + (2 * tenon_length)
        components << ["Második szárny beltéri vízszintes osztó #{i + 1}", division_length, middle_division_width, middle_division_thickness]
      end
    end

    if vertical_divisions > 0
      vertical_divisions.times do |v_index|
        (horizontal_divisions + 1).times do |segment_index|
          segment_height_with_tenon = segment_height + 2 * tenon_length
          components << ["Második szárny beltéri függőleges osztó #{v_index + 1} - szegmens #{segment_index + 1}", 
                        segment_height_with_tenon, 
                        vertical_division_width, 
                        vertical_division_thickness]
        end
      end
    end
  end

  components
end

def self.collect_electric_box_door_components(
  frame_wood_width, frame_wood_thickness,
  frame_width, frame_height,
  sash_width_deduction, sash_height_deduction,
  tenon_length,
  door_frieze_width, door_frieze_thickness,
  lower_tenoned_width, lower_tenoned_thickness,
  middle_division_width, middle_division_thickness,
  upper_tenoned_width, upper_tenoned_thickness,
  vertical_division_width, vertical_division_thickness,
  vertical_divisions, horizontal_divisions,
  door_type = "Egyszárnyú"  # Kétszárnyú ajtó támogatásához szükséges paraméter
)
  components = []

  # Tok komponensek
  components << ["Villanyóra tok alsó", frame_width, frame_wood_width, frame_wood_thickness]
  components << ["Villanyóra tok felső", frame_width, frame_wood_width, frame_wood_thickness]
  components << ["Villanyóra tok bal", frame_height, frame_wood_width, frame_wood_thickness]
  components << ["Villanyóra tok jobb", frame_height, frame_wood_width, frame_wood_thickness]

  # Nyíló külső méretei
  sash_external_width = frame_width - (2 * sash_width_deduction)
  sash_external_height = frame_height - sash_height_deduction

  # Kétszárnyú ajtó esetén a szélességet felezzük
  # Ez az ablakoknál használt logika alapján készült
  if door_type == "Kétszárnyú"
    sash_external_width = sash_external_width / 2
  end

  # Nyíló belső méretei
  sash_internal_width = sash_external_width - (2 * door_frieze_width)
  sash_internal_height = sash_external_height - (lower_tenoned_width + upper_tenoned_width)

  # Ajtó belméret számítása
  door_inner_height = sash_internal_height

  # Csapos elemek hossza
  lower_tenoned_length = sash_internal_width + (2 * tenon_length)
  upper_tenoned_length = sash_internal_width + (2 * tenon_length)

  # Ajtó fríz
  components << ["Villanyóra fríz bal", sash_external_height, door_frieze_width, door_frieze_thickness]
  components << ["Villanyóra fríz jobb", sash_external_height, door_frieze_width, door_frieze_thickness]

  # Alsó és felső csapos
  components << ["Villanyóra alsó csapos", lower_tenoned_length, lower_tenoned_width, lower_tenoned_thickness]
  components << ["Villanyóra felső csapos", upper_tenoned_length, upper_tenoned_width, upper_tenoned_thickness]

  # Középső osztók
  if horizontal_divisions > 0
    segment_height = (door_inner_height - (horizontal_divisions * middle_division_width)) / (horizontal_divisions + 1)
    
    horizontal_divisions.times do |i|
      division_length = sash_internal_width + (2 * tenon_length)
      components << ["Villanyóra vízszintes osztó #{i + 1}", division_length, middle_division_width, middle_division_thickness]
    end
  end

  # Függőleges osztók
  if vertical_divisions > 0
    (horizontal_divisions + 1).times do |segment_index|
      segment_height = if segment_index == 0 || segment_index == horizontal_divisions
        (door_inner_height - (horizontal_divisions * middle_division_width)) / (horizontal_divisions + 1)
      else
        (door_inner_height - (horizontal_divisions * middle_division_width)) / (horizontal_divisions + 1)
      end
      
      vertical_divisions.times do |v_index|
        components << ["Villanyóra függőleges osztó #{v_index + 1} - szegmens #{segment_index + 1}", 
                      segment_height + (2 * tenon_length),
                      vertical_division_width, 
                      vertical_division_thickness]
      end
    end
  end

  # Kétszárnyú ajtó esetén a második szárny komponenseinek hozzáadása
  # Ez az ablakoknál használt logika alapján készült
  if door_type == "Kétszárnyú"
    # Második szárny fríz elemei
    components << ["Második szárny villanyóra fríz bal", sash_external_height, door_frieze_width, door_frieze_thickness]
    components << ["Második szárny villanyóra fríz jobb", sash_external_height, door_frieze_width, door_frieze_thickness]

    # Második szárny csapos elemei
    components << ["Második szárny villanyóra alsó csapos", lower_tenoned_length, lower_tenoned_width, lower_tenoned_thickness]
    components << ["Második szárny villanyóra felső csapos", upper_tenoned_length, upper_tenoned_width, upper_tenoned_thickness]

    # Második szárny osztói
    if horizontal_divisions > 0
      horizontal_divisions.times do |i|
        division_length = sash_internal_width + (2 * tenon_length)
        components << ["Második szárny villanyóra vízszintes osztó #{i + 1}", division_length, middle_division_width, middle_division_thickness]
      end
    end

    if vertical_divisions > 0
      vertical_divisions.times do |v_index|
        (horizontal_divisions + 1).times do |segment_index|
          segment_height_with_tenon = segment_height + 2 * tenon_length
          components << ["Második szárny villanyóra függőleges osztó #{v_index + 1} - szegmens #{segment_index + 1}", 
                        segment_height_with_tenon, 
                        vertical_division_width, 
                        vertical_division_thickness]
        end
      end
    end
  end

  components
end

    def self.create_components_from_list(components_list)
      model = Sketchup.active_model
      model.start_operation('Alkatrészek létrehozása', true)
    
      begin
        entities = model.active_entities
        definitions = model.definitions
    
        x_offset = 0
        y_offset = 0
        max_height = 0
    
        puts "Komponensek feldolgozása..."
        puts "Elemek száma: #{components_list.length}"
    
        components_list.each_with_index do |element, element_index|
          puts "Feldolgozás alatt álló elem indexe: #{element_index}"
          element_type = element[:element_type]
          frame_size = element[:frame_size]
          components = element[:components]
    
          puts "#{element_index + 1}. elem feldolgozása: #{element_type}, méret: #{frame_size}"
          puts "Komponensek száma: #{components.length}"
    
          if components.empty?
            puts "Figyelmeztetés: Nincsenek komponensek ehhez az elemhez. Kihagyjuk."
            next
          end
    

          # Szövegcímke hozzáadása
          text = "#{element_type}\nMéret: #{frame_size}"
          text += "\nTípus: #{element[:window_type]}" if element[:window_type]
          text_point = Geom::Point3d.new(x_offset, y_offset, 0)
          text_entity = entities.add_text(text, text_point)

          components.each do |component|
            name, length, width, thickness = component

            if [name, length, width, thickness].any?(&:nil?) || [length, width, thickness].any? { |v| v <= 0 }
              puts "Figyelmeztetés: Hiányzó vagy érvénytelen adatok a komponenshez. Kihagyjuk ezt a komponenst."
              next
            end

            puts "Komponens létrehozása: #{name}, méret: #{length} x #{width} x #{thickness}"

            begin
              definition_name = "#{name}_#{element_index}_#{SecureRandom.uuid}"
              definition = definitions.add(definition_name)
              face = definition.entities.add_face([0, 0, 0], [length.mm, 0, 0], [length.mm, thickness.mm, 0], [0, thickness.mm, 0])
              face.pushpull(-width.mm)

              instance = entities.add_instance(definition, Geom::Transformation.translation([x_offset, y_offset, 0]))
              puts "Komponens sikeresen hozzáadva: #{name}"

              x_offset += length.mm + 50.mm  # 50 mm távolság a komponensek között
              max_height = [max_height, thickness.mm].max
            rescue => e
              puts "Hiba a komponens létrehozása során: #{name}"
              puts "Hibaüzenet: #{e.message}"
              puts e.backtrace.join("\n")
            end
          end

          # Nagyobb hézag az elemek között
          x_offset += 600.mm
          y_offset += max_height + 100.mm
          max_height = 0

          # Ha elértük a modell szélét, új sort kezdünk
          if x_offset > 2000.mm  # Példaérték, módosítható
            x_offset = 0
            y_offset += 200.mm
          end
        end

        puts "Komponensek és szövegdobozok létrehozása befejezve."
        model.commit_operation 
      rescue => e
        puts "Hiba történt a komponensek létrehozása során: #{e.message}"
        puts e.backtrace.join("\n")
        model.abort_operation
        return
      end 
    end
    unless file_loaded?(__FILE__)
      menu = UI.menu('Plugins').add_submenu('Ablak és Ajtó Generátor')
      menu.add_item('Alkatrészek generálása') { self.show_dialog }
      file_loaded(__FILE__)
    end

    private

    def self.generate_printable_html(components, title = nil)
        # HTML generálása
        html = <<-HTML
            <!DOCTYPE html>
            <html>
            <head>
                <meta charset="UTF-8">
                <title>#{title || 'Elemlista'}</title>
                <style>
                    body { 
                        font-family: Arial, sans-serif; 
                        margin: 5px;
                        line-height: 1.3;
                        font-size: 12px;
                    }
                    h1 {
                        font-size: 16px;
                        margin: 10px 0;
                    }
                    .component-list {
                        margin: 10px;
                        column-count: 2;
                        column-gap: 20px;
                    }
                    .component-item {
                        padding: 3px 5px;
                        border-bottom: 1px solid #eee;
                        break-inside: avoid;
                    }
                    .print-button {
                        display: block;
                        margin: 10px auto;
                        padding: 8px 16px;
                        background-color: #4CAF50;
                        color: white;
                        border: none;
                        border-radius: 4px;
                        cursor: pointer;
                        font-size: 14px;
                    }
                    .print-button:hover {
                        background-color: #45a049;
                    }
                    @media print {
                        .print-button {
                            display: none;
                        }
                        body {
                            margin: 0;
                            padding: 5mm;
                        }
                        @page {
                            size: A4;
                            margin: 5mm;
                        }
                        .component-list {
                            margin: 5px;
                        }
                        .component-item {
                            padding: 2px 4px;
                        }
                    }
                </style>
            </head>
            <body>
                #{title ? "<h1>#{title}</h1>" : ""}
                <button onclick="window.print()" class="print-button">Nyomtatás</button>
                <div class="component-list">
        HTML

        # Ellenőrizzük, hogy a components egy tömb-e
        if components.is_a?(Array)
            components.each do |component|
                if component.is_a?(Array) && component.length >= 4
                    name, length, width, thickness = component
                    html += "<div class=\"component-item\">#{name}: #{length}x#{width}x#{thickness}mm</div>\n"
                else
                    html += "<div class=\"component-item\">#{component}</div>\n"
                end
            end
        else
            html += "<div class=\"component-item\">Nincs generált elem.</div>\n"
        end

        html += <<-HTML
                </div>
            </body>
            </html>
        HTML

        return html
    end
   
  end  # module Main
end  # module WindowGenerator