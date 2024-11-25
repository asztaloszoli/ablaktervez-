// SketchUp bridge objektum
var sketchup = {
    generateComponents: function(params) {
        try {
            // Konvertáljuk a params stringet objektummá, ha string formátumban van
            if (typeof params === 'string') {
                params = JSON.parse(params);
            }
            
            // Logoljuk a paramétereket
            console.log('Paraméterek küldése a Ruby-nak:', params);
            
            // Itt hívjuk meg a Ruby oldali generateComponents függvényt
            window.location = 'skp:generateComponents@' + JSON.stringify(params);
        } catch (e) {
            console.error('Hiba történt a komponensek generálása során:', e);
            alert('Hiba történt a komponensek generálása során: ' + e.message);
        }
    }
};
