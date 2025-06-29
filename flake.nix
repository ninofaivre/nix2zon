{
  inputs = {
    nixpkgs-lib.url = "github:nix-community/nixpkgs.lib";
  };
  description = "Output a function nix2zon which you can use in your flake";
  outputs = { self, nixpkgs-lib }:
  let
    inherit (nixpkgs-lib) lib;
    nixLitteralToZon = litteral:
      let
        lType = builtins.typeOf litteral;
      in
      if (lType == "int" || lType == "float") then
        toString litteral
      else if (lType == "bool") then
        lib.boolToString litteral
      else if (lType == "null") then
        "null"
      else if (lType == "string") then
        if ((builtins.substring 0 1 litteral) == "." || (builtins.substring 0 2 litteral) == "0x" ||
            (builtins.substring 0 2 litteral) == "0o" || (builtins.substring 0 2 litteral) == "0b"
        ) then
          litteral
        else if ((builtins.substring 0 2 litteral) == ''\.'' ||
          (builtins.substring 0 3 litteral) == ''\0x'' || (builtins.substring 0 3 litteral) == ''\0o'' ||
          (builtins.substring 0 3 litteral) == ''\0b''
        ) then
          ''"${builtins.substring 1 (builtins.stringLength litteral) litteral}"''
        else if ((builtins.substring 0 2 litteral) == ''\\'') then
          ''"${builtins.substring 1 (builtins.stringLength litteral) litteral}"''
        else
          "\"${litteral}\""
      else if (lType == "path") then
        "\"${litteral}\"" 
      else
        throw "unsupported type : ${lType}";
  in {
    lib = {
      toZon = { value, lvl ? 0 }:
        let
          type = builtins.typeOf value;
          padding = lib.strings.replicate (2 * lvl) " "; 
        in
        if (type == "list") then
          let
            content = lib.strings.concatMapStringsSep ",\n  ${padding}" (value:
              self.lib.toZon { inherit value; lvl = lvl + 1; }
            ) value;
          in
          ".{\n  ${padding}${content}${if (builtins.length value) > 1 then "," else ""}\n${padding}}"
        else if (type == "set") then
          let
            values = lib.attrsets.attrsToList value;
            content = lib.strings.concatMapStringsSep ",\n  ${padding}" ({name, value}:
              ".${name} = ${self.lib.toZon { inherit value; lvl = lvl + 1; }}"
            ) values;
          in
          ".{\n  ${padding}${content}${if (builtins.length values) > 1 then "," else ""}\n${padding}}"
        else if (type == "lambda") then
          throw "lambda not supported"
        else
          nixLitteralToZon value; 
    };
  };
}
