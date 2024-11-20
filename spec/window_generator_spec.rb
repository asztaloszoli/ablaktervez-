require 'rspec'
require_relative '../main'  # Betölti a tesztelendő kódot

# Hozzáadjuk a hiányzó file_loaded? metódust
module WindowGenerator
  module Main
    def self.file_loaded?(file)
      true  # Egyszerű implementáció a teszteléshez
    end
  end
end

RSpec.describe WindowGenerator::Main do
  describe '.collect_door_components' do
    context 'when using manual vertical division lengths' do
      it 'generates correct components for manual vertical divisions' do
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

        # Hívjuk meg a metódust manuális osztókkal
        components = described_class.collect_door_components(
          frame_wood_width, frame_wood_thickness, frame_width, frame_height,
          door_sash_width_deduction, door_sash_height_deduction, tenon_length,
          door_frieze_width, door_frieze_thickness, lower_tenoned_width, lower_tenoned_thickness,
          middle_division_width, middle_division_thickness, upper_tenoned_width, upper_tenoned_thickness,
          vertical_division_width, vertical_division_thickness, vertical_divisions, horizontal_divisions,
          door_type, false, 50, false, false, use_manual_positions, manual_positions
        )

        # Ellenőrizzük, hogy a generált komponensek listája nem üres
        expect(components).not_to be_empty

        # Nyomtassuk ki a generált komponenseket a konzolra
        puts "\n=== Generált Komponensek ==="
        components.each do |component|
          name, length, width, thickness = component
          puts "Név: #{name}, Hossz: #{length}, Szélesség: #{width}, Vastagság: #{thickness}"
        end

        # Ellenőrizzük a manuális függőleges osztók hozzáadását
        manual_positions.each_with_index do |pos, index|
          expected_length = pos['totalLength'] + (2 * tenon_length)
          expect(components).to include(
            an_object_having_attributes(
              first: include("Függőleges osztó #{index + 1}"),
              second: be_within(0.1).of(expected_length),
              third: be_within(0.1).of(vertical_division_width),
              fourth: be_within(0.1).of(vertical_division_thickness)
            )
          )
        end
      end
    end
  end
end
