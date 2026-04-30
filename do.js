const fs = require('fs'); 
const p = 'C:/Users/Administrator/git/allergy-detector/app/lib/screens/search_scan_screen.dart'; 
var content = fs.readFileSync(p, 'utf8'); 
content = content.replace('import .package:flutter/material.dart.;'/'/'import .package:flutter.material.dart.;\r\nimport .package:flutter.foundation.dart.;/'/); 
