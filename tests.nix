{ toZon, generators }:
{
  literals = {
    integers = {
      testDecimal = { expr = toZon 42; expected = "42"; };
      testHex = { expr = toZon "0x2a"; expected = "0x2a"; };
      testOctal = { expr = toZon "0o52"; expected = "0o52"; };
      testBinary = { expr = toZon "0b101010"; expected = "0b101010"; };
    };
    testFloat = { expr = toZon 42.42; expected = "42.420000"; };
    testBool = { expr = toZon false; expected = "false"; };
    testNull = { expr = toZon null; expected = "null"; };
    enums = {
      testDefault = { expr = toZon ".fortyTwo"; expected = ".fortyTwo"; };
      testInvalidIdentifier = {
        expr = toZon ".42-@";
        expected = ".@\"42-@\"";
      };
    };
    strings = {
      testDefault = {
        expr = toZon "fortyTwo";
        expected = "\"fortyTwo\"";
      };
      testEmpty = { expr = toZon ""; expected = "\"\""; };
      /* TODO fix this ?
      testPath = let
        path = ./flake.nix;
      in {
        expr = toZon path;
        expected = "\"${toString path}\"";
      };
      */
      testHex = { expr = toZon ''\0x2a''; expected = "\"0x2a\""; };
      testOctal = { expr = toZon ''\0o52''; expected = "\"0o52\""; };
      testBinary = {
        expr = toZon ''\0b101010'';
        expected = "\"0b101010\"";
      };
      testEnum = {
        expr = toZon ''\.fortyTwo'';
        expected = "\".fortyTwo\"";
      };
      testBackslashBackslash = {
        expr = toZon ''\\.fortyTwo'';
        expected = "\"\\.fortyTwo\"";
      };
    };
  };
  arrays = {
    testEmpty = { expr = toZon []; expected = ".{}"; };
    testOneElement = { expr = toZon [42]; expected = ".{ 42 }"; };
    testMultipleElements = {
      expr = toZon [ 21 42 84 ];
      expected = ''
        .{
          21,
          42,
          84,
        }''
      ;
    };
    testNull = {
      expr = generators.toZon {
        suppressNullAttrValues = true;
      } [ 42 null 21 ];
      expected = ''
        .{
          42,
          null,
          21,
        }'';
    };
  };
  structs = {
    testEmpty = { expr = toZon {}; expected = ".{}"; };
    testDefault = {
      expr = toZon { fortyTwo = "fortyTwo"; };
      expected = ''
        .{
          .fortyTwo = "fortyTwo",
        }''
      ;
    };
    testNulls = {
      expr = toZon { a = null; b = "coucou"; };
      expected  = ''
        .{
          .a = null,
          .b = "coucou",
        }'';
    };
    testSuppressedNulls = {
      expr = generators.toZon {
        suppressNullAttrValues = true;
      } { a = null; b = "coucou"; };
      expected  = ''
        .{
          .b = "coucou",
        }'';
    };
    # keys are using alphabetical order here
    # to avoid that maybe something like
    # [zq](https://codeberg.org/tensorush/zq)
    # could be used with callPackage but
    # there is currently no nix package for it
    testMixed = {
      expr = generators.toZon { suppressNullAttrValues = true; } {
        "@invalid-identifier@" = 42;
        array = [ 21 42 84 ];
        emptyArray = [];
        emptyAttrSet = {};
        fortyTwo = {
          dividedBy = {
            four = 10.25;
            two = "twentyOne";
            shouldNotExists = null;
          };
          mutipliedBy = {
            two = "eightyFour";
            shouldNotExists = null;
          };
          shouldNotExists = null;
          self = "fortyTwo";
        };
        shouldNotExists = null;
        hex = "0x2a";
        n.e.s.t.e.d.one = "yay I'm nested !!!";
      };
      expected = ''
        .{
          .@"@invalid-identifier@" = 42,
          .array = .{
            21,
            42,
            84,
          },
          .emptyArray = .{},
          .emptyAttrSet = .{},
          .fortyTwo = .{
            .dividedBy = .{
              .four = 10.250000,
              .two = "twentyOne",
            },
            .mutipliedBy = .{
              .two = "eightyFour",
            },
            .self = "fortyTwo",
          },
          .hex = 0x2a,
          .n = .{
            .e = .{
              .s = .{
                .t = .{
                  .e = .{
                    .d = .{
                      .one = "yay I'm nested !!!",
                    },
                  },
                },
              },
            },
          },
        }''
      ;
    };
  };
}
