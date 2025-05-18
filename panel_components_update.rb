# Kétszárnyú ablakok panel méretezésének javítása
# Ez a kódrészlet a panel_components.rb fájlból származik, a kétszárnyú ablakok panel méretezését javítja

# A módosított kódrészlet:
# Kétszárnyú ablak esetén figyelembe kell venni a szárnyak szélességét
if is_double_window
    # Kétszárnyú ablak esetén ellenőrizzük, hogy melyik szárnyhoz tartozik a panel
    wing_position = panel["wing"] || "left"
    is_asymmetric = panel["is_asymmetric"] == true || panel["window_is_asymmetric"] == true
    main_wing_ratio = panel["main_wing_ratio"] || panel["window_main_wing_ratio"] || 50.0
    sash_double_deduction = panel["sash_double_deduction"] || 26.0 # Kétszárnyú ablakok egymásra takarása
    
    puts "[PANEL MÉRET SZÁMÍTÁS] Kétszárnyú ablak adatok: Szárny=#{wing_position}, Aszimmetrikus=#{is_asymmetric}, Fő szárny arány=#{main_wing_ratio}%, Egymásra takarás=#{sash_double_deduction}mm"
    
    # ÚJ SZÁMÍTÁSI MÓD: A nyíló elemek méreteiből indulunk ki
    # A nyíló alsó/felső vízszintes elemek szélessége a komponens listából
    nyilo_width = 725.0  # Alapértelmezett érték, ha nincs megadva
    
    # Ha a params objektumban van nyíló elem szélesség, azt használjuk
    if panel["nyilo_width"]
        nyilo_width = panel["nyilo_width"].to_f
        puts "[PANEL MÉRET SZÁMÍTÁS] Nyíló elem szélessége a paraméterekből: #{nyilo_width}mm"
    end
    
    # Nyíló belméret számítása: nyíló szélesség - (2 * fríz szélesség)
    sash_inner_width_from_nyilo = nyilo_width - (2 * sash_wood_width)
    puts "[PANEL MÉRET SZÁMÍTÁS] Nyíló belméret a nyíló elemből számítva: #{sash_inner_width_from_nyilo}mm"
    
    # Ezt használjuk a további számításokhoz
    sash_inner_width = sash_inner_width_from_nyilo
    
    puts "[PANEL MÉRET SZÁMÍTÁS] Kétszárnyú ablak számítás után: Szárny szélesség=#{sash_inner_width}mm"
end

# Módosítás magyarázata:
# A korábbi kód a sash_inner_width-et a teljes nyíló belméretből számította, figyelembe véve az aszimmetrikus/szimmetrikus beállításokat.
# Az új kód a nyíló elemek (Nyíló alsó/felső vízszintes) méreteiből indul ki:
# 1. Alapértelmezetten 725mm-es nyíló szélességet használ
# 2. Ha a paraméterekben van megadva nyíló szélesség, akkor azt használja
# 3. A nyíló belméretét úgy számítja, hogy a nyíló szélességből levonja a két fríz szélességét
# 4. Ezt a belméret értéket használja a további számításokhoz