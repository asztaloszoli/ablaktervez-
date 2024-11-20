require 'sketchup.rb'
require 'extensions.rb'

module WindowGenerator
  # Bővítmény részletei
  PLUGIN_NAME = 'WindowGenerator'
  PLUGIN_VERSION = '1.0.0'

  # Bővítmény létrehozása
  extension = SketchupExtension.new(PLUGIN_NAME, 'WindowGenerator/main')

  # Bővítmény tulajdonságainak beállítása
  extension.description = 'A tool to generate window components based on user input.'
  extension.version     = PLUGIN_VERSION
  extension.creator     = 'AuthorName'

  # Bővítmény regisztrálása
  Sketchup.register_extension(extension, true)
end
