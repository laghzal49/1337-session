; extends
; nvimz Python semantic accents: distinct class, function, and __init__ names.
(class_definition
  name: (identifier) @type.definition)

(function_definition
  name: (identifier) @function)

(function_definition
  name: (identifier) @function.method.special
  (#eq? @function.method.special "__init__"))
