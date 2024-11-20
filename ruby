require 'sketchup.rb'
require 'extensions.rb'

module WindowGenerator
    unless file_loaded?(__FILE__)
        menu = UI.menu('Plugins')
        menu.add_item('Generált Ablak Komponensek') { generate_components }
        file_loaded(__FILE__)
      end
end
