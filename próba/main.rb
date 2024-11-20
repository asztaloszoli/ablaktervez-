module WindowGenerator
  module Main
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

      dlg.add_action_callback("updateDividerSettings") do |action_context, settings_json|
        begin
          settings = JSON.parse(settings_json)
          puts "Manuális osztó beállítások fogadva:"
          puts "Ajtó magasság: #{settings['doorHeight']}"
          puts "Vízszintes osztások száma: #{settings['horizontalDivisions']}"
          puts "Manuális pozíciók:"
          settings['manualPositions'].each_with_index do |pos, index|
            puts "  #{index + 1}. osztó - pozíció: #{pos['position']}mm, hossz: #{pos['totalLength']}mm"
          end
      
          # A beállításokat tároljuk a későbbi felhasználáshoz
          @manual_divider_settings = settings
      
          # Frissítjük az előnézetet, ha szükséges
          if settings['type'] == 'door'
            update_door_preview(settings)
          elsif settings['type'] == 'interiorDoor'
            update_interior_door_preview(settings)
          elsif settings['type'] == 'electricBoxDoor'
            update_electric_box_door_preview(settings)
          end
      
        rescue => e
          puts "Hiba a manuális osztó beállítások feldolgozásakor: #{e.message}"
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

          quantity.times do
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
              params["is_asymmetric"],              # új paraméter
              params["main_wing_ratio"].to_f,      # új paraméter
              use_aluminum_threshold,  # Új paraméter átadása
              params["disable_narrow_wing_vertical_divisions"], # Új paraméter
              params["use_manual_positions"],   # Manuális beállítások használata
              use_manual_vertical_division_lengths = params["use_manual_positions"]
              vertical_division_lengths = params["manual_positions"]
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
    use_aluminum_threshold = false,
    disable_narrow_wing_vertical_divisions = false,
    use_manual_positions = false,           
    manual_positions = [],                  
    manual_horizontal_positions = []                   
    )
    # Konvertáljuk a paramétereket float típusra
    frame_width = frame_width.to_f
    frame_height = frame_height.to_f
    door_sash_width_deduction = door_sash_width_deduction.to_f
    door_sash_height_deduction = door_sash_height_deduction.to_f
    tenon_length = tenon_length.to_f
    door_frieze_width = door_frieze_width.to_f
    door_frieze_thickness = door_frieze_thickness.to_f
    main_wing_ratio = main_wing_ratio.to_f

    # Boolean konverziók
    disable_narrow_wing_vertical_divisions = !!disable_narrow_wing_vertical_divisions
    use_aluminum_threshold = !!use_aluminum_threshold
    is_asymmetric = !!is_asymmetric
    use_manual_positions = !!use_manual_positions
    
    puts "\n=== Kezdeti paraméterek ==="
    puts "Door type: #{door_type}"
    puts "Frame width: #{frame_width}, Frame height: #{frame_height}"
    puts "Is asymmetric: #{is_asymmetric}, Wider wing ratio: #{main_wing_ratio}%"
    puts "Collecting door components with aluminum threshold: #{use_aluminum_threshold}"
    puts "Using manual positions: #{use_manual_positions}"
    
    components = []
  
    # Tok komponensek
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
  
    # Az ajtó típusának ellenőrzése és az egymásra takarás beállítása
    if door_type == "Kétszárnyú"
        overlap_adjustment = 13.0
    else
        overlap_adjustment = 0.0
    end

    if door_type == "Kétszárnyú"
        if is_asymmetric
            puts "\n=== Aszimmetrikus számítások ==="
            wider_ratio = main_wing_ratio / 100.0
            narrower_ratio = 1.0 - wider_ratio
            
            wider_sash_width = total_sash_width * wider_ratio
            narrower_sash_width = total_sash_width * narrower_ratio
      
            wider_sash_internal_width = wider_sash_width - (2 * door_frieze_width)
            narrower_sash_internal_width = narrower_sash_width - (2 * door_frieze_width)
      
            # Szélesebb szárny komponensei
            components << ["Szélesebb szárny fríz bal", sash_external_height, door_frieze_width, door_frieze_thickness]
            components << ["Szélesebb szárny fríz jobb", sash_external_height, door_frieze_width, door_frieze_thickness]
            
            wider_tenoned_length = wider_sash_internal_width + (2 * tenon_length) + overlap_adjustment
            components << ["Szélesebb szárny alsó csapos", wider_tenoned_length, lower_tenoned_width, lower_tenoned_thickness]
            components << ["Szélesebb szárny felső csapos", wider_tenoned_length, upper_tenoned_width, upper_tenoned_thickness]
      
            # Keskenyebb szárny komponensei
            components << ["Keskenyebb szárny fríz bal", sash_external_height, door_frieze_width, door_frieze_thickness]
            components << ["Keskenyebb szárny fríz jobb", sash_external_height, door_frieze_width, door_frieze_thickness]
            
            narrower_tenoned_length = narrower_sash_internal_width + (2 * tenon_length) + overlap_adjustment
            components << ["Keskenyebb szárny alsó csapos", narrower_tenoned_length, lower_tenoned_width, lower_tenoned_thickness]
            components << ["Keskenyebb szárny felső csapos", narrower_tenoned_length, upper_tenoned_width, upper_tenoned_thickness]
      
            # Vízszintes osztók mindkét szárnyhoz
            if horizontal_divisions > 0
              division_length = tenoned_length
              horizontal_divisions.times do |i|
                components << ["Vízszintes osztó #{i + 1}",
                               division_length,
                               middle_division_width,
                               middle_division_thickness]
              end
            end
            # Függőleges osztók
            if vertical_divisions > 0
                door_inner_height = sash_external_height - lower_tenoned_width - upper_tenoned_width
                total_horizontal_division_height = horizontal_divisions * middle_division_width
                available_height = door_inner_height - total_horizontal_division_height
                segment_height = available_height / (horizontal_divisions + 1)
      
                # Szélesebb szárny függőleges osztói
                vertical_divisions.times do |v_index|
                    (horizontal_divisions + 1).times do |segment_index|
                        segment_height_with_tenon = segment_height + (2 * tenon_length)
                        components << ["Szélesebb szárny függőleges osztó #{v_index + 1} - szegmens #{segment_index + 1}", 
                                     segment_height_with_tenon,
                                     vertical_division_width, 
                                     vertical_division_thickness]
                  end
              end
              # Függőleges osztók manuális hosszal
              if vertical_divisions > 0 && use_manual_vertical_division_lengths && !vertical_division_lengths.empty?
                # Minden megadott hosszhoz hozzáadjuk a csapokat
                vertical_division_lengths.each_with_index do |length_data, index|
                  pos = length_data['position'].to_f
                  length = pos + (2 * tenon_length)
                  components << ["Függőleges osztó #{index + 1}",
                                length,
                                vertical_division_width,
                                vertical_division_thickness]
                end
                # Utolsó szegmens (maradék)
                remaining_height = sash_external_height - 
                                  lower_tenoned_width - 
                                  upper_tenoned_width - 
                                  (vertical_division_lengths.length * middle_division_width) - 
                                  vertical_division_lengths.sum { |p| p['position'].to_f }
                 final_length = remaining_height + (2 * tenon_length)
                 components << ["Függőleges osztó #{vertical_division_lengths.length + 1}",
                              final_length,
                               vertical_division_width,
                              vertical_division_thickness]
               end

                # Keskenyebb szárny függőleges osztói (csak ha nincs letiltva)
                unless disable_narrow_wing_vertical_divisions
                    vertical_divisions.times do |v_index|
                        (horizontal_divisions + 1).times do |segment_index|
                            segment_height_with_tenon = segment_height + (2 * tenon_length)
                            components << ["Keskenyebb szárny függőleges osztó #{v_index + 1} - szegmens #{segment_index + 1}", 
                                         segment_height_with_tenon,
                                         vertical_division_width, 
                                         vertical_division_thickness]
                        end
                    end
                end
            end
        else
            # Szimmetrikus kétszárnyú ajtó
            sash_external_width = total_sash_width / 2
            sash_internal_width = sash_external_width - (2 * door_frieze_width)
            sash_internal_height = sash_external_height - (lower_tenoned_width + upper_tenoned_width)
            
            ["Első", "Második"].each do |prefix|
                components << ["#{prefix} szárny fríz bal", sash_external_height, door_frieze_width, door_frieze_thickness]
                components << ["#{prefix} szárny fríz jobb", sash_external_height, door_frieze_width, door_frieze_thickness]
                
                tenoned_length = sash_internal_width + (2 * tenon_length) + overlap_adjustment
                components << ["#{prefix} szárny alsó csapos", tenoned_length, lower_tenoned_width, lower_tenoned_thickness]
                components << ["#{prefix} szárny felső csapos", tenoned_length, upper_tenoned_width, upper_tenoned_thickness]
                
                if horizontal_divisions > 0
                    if use_manual_positions && !manual_positions.empty?
                        manual_positions.each_with_index do |position, index|
                            division_length = sash_internal_width + (2 * tenon_length) + overlap_adjustment
                            components << ["#{prefix} szárny manuális vízszintes osztó #{index + 1}", 
                                         division_length, 
                                         middle_division_width, 
                                         middle_division_thickness]
                            puts "Manuális osztó hozzáadva #{prefix.downcase} szárnyhoz: pozíció=#{position['position']}mm"
                        end
                    else
                        horizontal_divisions.times do |i|
                            division_length = sash_internal_width + (2 * tenon_length) + overlap_adjustment
                            components << ["#{prefix} szárny vízszintes osztó #{i + 1}", 
                                         division_length, 
                                         middle_division_width, 
                                         middle_division_thickness]
                        end
                    end
                end
                
                if vertical_divisions > 0
                    door_inner_height = sash_external_height - lower_tenoned_width - upper_tenoned_width
                    total_horizontal_division_height = horizontal_divisions * middle_division_width
                    available_height = door_inner_height - total_horizontal_division_height
                    segment_height = available_height / (horizontal_divisions + 1)
                    
                    vertical_divisions.times do |v_index|
                        (horizontal_divisions + 1).times do |segment_index|
                            segment_height_with_tenon = segment_height + (2 * tenon_length)
                            components << ["#{prefix} szárny függőleges osztó #{v_index + 1} - szegmens #{segment_index + 1}", 
                                         segment_height_with_tenon,
                                         vertical_division_width, 
                                         vertical_division_thickness]
                        end
                    end
                end
            end
        end
    else
        # Egyszárnyú ajtó
        sash_external_width = total_sash_width
        sash_internal_width = sash_external_width - (2 * door_frieze_width)
        sash_internal_height = sash_external_height - (lower_tenoned_width + upper_tenoned_width)

       # Fríz elemek
        components << ["Ajtó fríz bal", sash_external_height, door_frieze_width, door_frieze_thickness]
        components << ["Ajtó fríz jobb", sash_external_height, door_frieze_width, door_frieze_thickness]

       # Csapos elemek
        tenoned_length = sash_internal_width + (2 * tenon_length)
        components << ["Alsó csapos", tenoned_length, lower_tenoned_width, lower_tenoned_thickness]
        components << ["Felső csapos", tenoned_length, upper_tenoned_width, upper_tenoned_thickness]

       # Vízszintes osztók
        if horizontal_divisions > 0
         if use_manual_positions && !manual_horizontal_positions.empty?
          manual_horizontal_positions.each_with_index do |position, index|
           division_length = tenoned_length
           components << ["Manuális vízszintes osztó #{index + 1}",
                       division_length,
                       middle_division_width,
                       middle_division_thickness]
        puts "Manuális vízszintes osztó hozzáadva: pozíció=#{position['position']}mm, hossz=#{division_length}mm"
      end
    else
      horizontal_divisions.times do |i|
        division_length = tenoned_length
        components << ["Vízszintes osztó #{i + 1}",
                       division_length,
                       middle_division_width,
                       middle_division_thickness]
      end
    end
  end

  # Függőleges osztók
  if vertical_divisions > 0 && use_manual_positions && !manual_horizontal_positions.empty?
    # Minden függőleges osztónál: pozíció + (2 × csaphossz)
    manual_horizontal_positions.each_with_index do |position, index|
      pos = position['position'].to_f
      length = pos + (2 * tenon_length)  # csak ennyi a számítás! 600 + (2 × 82) = 764mm
      components << ["Függőleges osztó #{index + 1}",
                    length,
                    vertical_division_width,
                    vertical_division_thickness]
      puts "Függőleges osztó #{index + 1} hossza: #{pos}mm + #{2 * tenon_length}mm csapok = #{length}mm"
    end
  
    # Utolsó szegmens (maradék)
    remaining_height = sash_external_height - 
                      lower_tenoned_width - 
                      upper_tenoned_width - 
                      (manual_horizontal_positions.length * middle_division_width) - 
                      manual_horizontal_positions.sum { |p| p['position'].to_f }
    final_length = remaining_height + (2 * tenon_length)
    components << ["Függőleges osztó #{manual_horizontal_positions.length + 1}",
                  final_length,
                  vertical_division_width,
                  vertical_division_thickness]
  end
    else
      door_inner_height = sash_external_height - lower_tenoned_width - upper_tenoned_width
      total_horizontal_division_height = horizontal_divisions * middle_division_width
      available_height = door_inner_height - total_horizontal_division_height
      segment_height = available_height / (horizontal_divisions + 1)

      vertical_divisions.times do |v_index|
        (horizontal_divisions + 1).times do |segment_index|
          segment_height_with_tenon = segment_height + (2 * tenon_length)
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