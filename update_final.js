var fs = require('fs'); 
var p = 'C:/Users/Administrator/git/allergy-detector/app/lib/screens/search_scan_screen.dart'; 
var c = fs.readFileSync(p, 'utf8'); 
c = c.replace(String.raw\import 'package:flutter/material.dart';\, String.raw\import 'package:flutter/material.dart';\nimport 'package:flutter/foundation.dart';\); 
fs.writeFileSync(p, c, 'utf8'); 
