require_relative 'main'

def test_manual_vertical_divisions
  puts "DEBUG: Teszt metódus elindult"

  # Alapvető bemeneti paraméterek
  frame_wood_width = 100
  frame_wood_thickness = 10
  frame_width = 2000
  frame_height = 2100
  door_sash_width_deduction = 50
  door_sash_height_deduction = 50
  tenon_length = 15
  door_frieze_width = 30
  door_frieze_thickness = 5
  lower_tenoned_width = 40
  lower_tenoned_thickness = 5
  middle_division_width = 20
  middle_division_thickness = 5
  upper_tenoned_width = 40
  upper_tenoned_thickness = 5
  vertical_division_width = 15
  vertical_division_thickness = 5
  vertical_divisions = 2
  horizontal_divisions = 0
  door_type = "Egyszárnyú"

  # Manuális osztó beállítások
  use_manual_positions = true
  manual_positions = [
    { 'position' => 500, 'totalLength' => 1000 },
    { 'position' => 1200, 'totalLength' => 800 }
  ]

  puts "\n=== Bemeneti paraméterek ==="
  puts "Manuális pozíciók:"
  manual_positions.each_with_index do |pos, index|
    puts "  #{index + 1}. pozíció: #{pos['position']}mm, hossz: #{pos['totalLength']}mm"
  end

  begin
    puts "DEBUG: Komponensek generálásának megkezdése"
    # Komponensek generálása
    components = WindowGenerator::Main.collect_door_components(
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
      false,  # is_asymmetric
      50,     # main_wing_ratio
      false,  # use_aluminum_threshold
      false,  # disable_narrow_wing_vertical_divisions
      use_manual_positions,
      manual_positions
    )

    puts "DEBUG: Komponensek generálva, darabszám: #{components.length}"

    # Eredmények kiértékelése
    puts "\n=== Generált Komponensek ==="
    components.each do |component|
      name, length, width, thickness = component
      puts "Név: #{name}, Hossz: #{length}, Szélesség: #{width}, Vastagság: #{thickness}"
    end

    # Manuális függőleges osztók ellenőrzése
    manual_vertical_divisions = components.select { |c| c[0].include?("Függőleges osztó") }
    
    puts "\n=== Manuális Függőleges Osztók Ellenőrzése ==="
    puts "DEBUG: Talált manuális függőleges osztók: #{manual_vertical_divisions.length}"
    
    if manual_vertical_divisions.empty?
      puts "HIBA: Nem generálódtak manuális függőleges osztók!"
      return {
        success: false,
        message: "Nem generálódtak manuális függőleges osztók"
      }
    end

    # Részletes ellenőrzés
    validation_results = manual_positions.each_with_index.map do |pos, index|
      expected_length = pos['totalLength'] + (2 * tenon_length)
      
      puts "\nElvárt hossz #{index + 1}. osztóhoz: #{expected_length}"
      
      matching_division = manual_vertical_divisions.find do |div| 
        div[0].include?("Függőleges osztó #{index + 1}") &&
        (div[1] - expected_length).abs < 0.1 &&
        div[2] == vertical_division_width &&
        div[3] == vertical_division_thickness
      end

      if matching_division
        puts "✓ #{index + 1}. manuális függőleges osztó rendben"
        puts "   Generált hossz: #{matching_division[1]}"
        puts "   Elvárt hossz:   #{expected_length}"
        {
          success: true,
          index: index + 1,
          generated_length: matching_division[1],
          expected_length: expected_length
        }
      else
        puts "✗ HIBA: #{index + 1}. manuális függőleges osztó nem megfelelő"
        {
          success: false,
          index: index + 1,
          message: "Nem megfelelő manuális függőleges osztó"
        }
      end
    end

    # Végső eredmény
    all_valid = validation_results.all? { |result| result[:success] }
    
    puts "\n=== TESZT EREDMÉNYE ==="
    if all_valid
      puts "✓ TESZT SIKERES"
      {
        success: true,
        message: "Minden manuális függőleges osztó megfelelően generálva",
        details: validation_results
      }
    else
      puts "✗ TESZT SIKERTELEN"
      {
        success: false,
        message: "Nem minden manuális függőleges osztó megfelelő",
        details: validation_results
      }
    end

  rescue => e
    puts "HIBA történt a teszt végrehajtása során:"
    puts e.message
    puts e.backtrace.join("\n")
    {
      success: false,
      message: "Hiba a teszt végrehajtása során",
      error: e.message
    }
  end
end

# Ha közvetlenül futtatjuk a szkriptet
if __FILE__ == $0
  result = test_manual_vertical_divisions
  exit(result[:success] ? 0 : 1)
end

# Exportáljuk a metódust, hogy elérhető legyen a Ruby konzolban
result = test_manual_vertical_divisions
result
