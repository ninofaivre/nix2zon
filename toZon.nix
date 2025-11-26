# TODO configurable padding level (number of spaces)
{ lib }: let
  nixliteralToZon = literal:
    let
      lType = builtins.typeOf literal;
    in
    if lType == "int" || lType == "float" then
      toString literal
    else if lType == "bool" then
      lib.boolToString literal
    else if lType == "null" then
      "null"
    else if lType == "string" then
      if ((builtins.substring 0 1 literal) == "." || (builtins.substring 0 2 literal) == "0x" ||
          (builtins.substring 0 2 literal) == "0o" || (builtins.substring 0 2 literal) == "0b"
      ) then
        literal
      else if ((builtins.substring 0 2 literal) == ''\.'' ||
        (builtins.substring 0 3 literal) == ''\0x'' || (builtins.substring 0 3 literal) == ''\0o'' ||
        (builtins.substring 0 3 literal) == ''\0b''
      ) then
        ''"${builtins.substring 1 (builtins.stringLength literal) literal}"''
      else if ((builtins.substring 0 2 literal) == ''\\'') then
        ''"${builtins.substring 1 (builtins.stringLength literal) literal}"''
      else
        "\"${literal}\""
    else if (lType == "path") then
      "\"${literal}\"" 
    else
      throw "unsupported type : ${lType}";
  toZon = { suppressNullAttrValues ? false }@conf: { lvl ? 0 }@ctx: value:
    let
      type = builtins.typeOf value;
      padding = lib.strings.replicate (2 * lvl) " "; 
    in
    if type == "list" then
      let
        content = lib.strings.concatMapStringsSep ",\n  ${padding}" (value:
          toZon conf (ctx // { lvl = lvl + 1; }) value
        ) value;
        nValues = builtins.length value;
      in
      if nValues == 0 then
        ".{}"
      else
        ".{${lib.optionalString (nValues > 1) "\n "} ${padding}${content}${
            if nValues > 1 then ",\n"
            else " "
          }${padding}}"
    else if type == "set" then
      let
        values = lib.attrsets.attrsToList (
          if suppressNullAttrValues == true then
            (lib.filterAttrs (_: x: x != null) value)
          else value
        );
        content = lib.strings.concatMapStringsSep ",\n  ${padding}" ({name, value}:
          ".${name} = ${toZon conf (ctx // { lvl = lvl + 1; }) value}"
        ) values;
      in
      if builtins.length values == 0 then ".{}"
      else ".{\n  ${padding}${content},\n${padding}}"
    else
      nixliteralToZon value;
in conf: value:
  toZon conf {} value
