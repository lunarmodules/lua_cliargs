require("busted")

-- some helper stuff for debugging
local quoted = function(s)
  return "'" .. tostring(s) .. "'" 
end
local dump = function(t)
  print(" ============= Dump " .. tostring(t) .. " =============")
  if type(t) ~= "table" then
    print(quoted(tostring(t)))
  else
    for k,v in pairs(t) do
      print(quoted(k),quoted(v))
    end
  end
  print(" ============= Dump " .. tostring(t) .. " =============")
end

-- fixture
local function populate_required(cli)
  cli:add_argument("INPUT", "path to the input file")

  return { ["INPUT"] = nil }
end
local function populate_optionals(cli)
  cli:add_option("-c, --compress=FILTER", "the filter to use for compressing output: gzip, lzma, bzip2, or none", nil, "gzip")
  cli:add_option("-o FILE", "path to output file", nil, "/dev/stdout")  

  return { c = "gzip", compress = "gzip", o = "/dev/stdout" }
end
local function populate_flags(cli)
  cli:add_flag("-d", "script will run in DEBUG mode")
  cli:add_flag("-v, --version", "prints the program's version and exits")
  cli:add_flag("--verbose", "the script output will be very verbose")  

  return { d = false, v = false, version = false, verbose = false }
end

local cli, defaults, result
-- start tests
describe("Testing cliargs library parsing commandlines", function()

  setup(function()
    _TEST = true
    package.loaded.cliargs = false  -- Busted uses it, but must force to reload 
    cli = require("cliargs")
  end)

  teardown(function()
    _TEST = false
  end)
  
  before_each(function()
    cli.optional = {}
    cli.required = {}
  end)

  it("tests no arguments set, nor provided", function()
    arg = nil
    result = cli:parse()
    assert.are.same(result, {})
  end)
  
  it("tests only optionals, nothing provided", function()
    arg = nil
    defaults = populate_optionals(cli)
    result = cli:parse()
    assert.are.same(result, defaults)
  end)
  
  it("tests only required, all provided", function()
    arg = { "some_file" }
    populate_required(cli)
    result = cli:parse()
    assert.are.same(result, { ["INPUT"] = "some_file" })
  end)
  
  it("tests only optionals, all provided", function()
    arg = { "-o", "/dev/cdrom", "--compress=lzma" }
    populate_optionals(cli)
    result = cli:parse()
    assert.are.same(result, { o = "/dev/cdrom", c = "lzma", compress = "lzma" })
  end)
  
  it("tests optionals + required, all provided", function()
    arg = { "-o", "/dev/cdrom", "-c", "lzma", "some_file" }
    populate_required(cli)
    populate_optionals(cli)
    result = cli:parse()
    assert.are.same(result, {
      o = "/dev/cdrom",
      c = "lzma", compress = "lzma",
      ["INPUT"] = "some_file"
    })
  end)

  it("tests optional using -short-key notation", function()
    arg = { "-c", "lzma" }
    defaults = populate_optionals(cli)
    defaults.c = "lzma"
    defaults.compress = "lzma"

    result = cli:parse()
    assert.are.same(result, defaults)
  end)

  it("tests optional using --expanded-key notation", function()
    arg = { "--compress=lzma" }
    defaults = populate_optionals(cli)
    defaults.c = "lzma"
    defaults.compress = "lzma"

    result = cli:parse()

    assert.are.same(result, defaults)
  end)
  
  it("tests flag using -short-key notation", function()
    arg = { "-v" }
    defaults = populate_flags(cli)
    defaults.v = true
    defaults.version = true
    result = cli:parse()
    assert.are.same(result, defaults)
  end)

  it("tests flag using --expanded-key notation", function()
    arg = { "--version" }
    defaults = populate_flags(cli)
    defaults.v = true
    defaults.version = true
    result = cli:parse()
    assert.are.same(result, defaults)
  end)
  
  it("tests sk-only flag", function()
    arg = { "-d" }
    defaults = populate_flags(cli)
    defaults.d = true
    result = cli:parse()
    assert.are.same(result, defaults)
  end)
    
  it("tests ek-only flag", function()
    arg = { "--verbose" }
    defaults = populate_flags(cli)
    defaults.verbose = true
    result = cli:parse()
    assert.are.same(result, defaults)
  end)
  
  it("tests optionals + required, no optionals and to little required provided, ", function()
    arg = { }
    populate_required(cli)
    populate_optionals(cli)
    result = cli:parse(true --[[no print]])
    assert.is.falsy(result)
  end)

  it("tests optionals + required, no optionals and to many required provided, ", function()
    arg = { "some_file", "some_other_file" }
    populate_required(cli)
    populate_optionals(cli)
    result = cli:parse(true --[[no print]])
    assert.is.falsy(result)
  end)
  
  it("tests bad short-key notation, -x=VALUE", function()
    arg = { "-o=some_file" }
    populate_optionals(cli)
    result = cli:parse(true --[[no print]])
    assert.is.falsy(result)
  end)
  
  it("tests bad --expanded-key notation, --x VALUE", function()
    arg = { "--compress", "lzma" }
    populate_optionals(cli)
    result = cli:parse(true --[[no print]])
    assert.is.falsy(result)
  end)  

  it("tests unknown option", function()
    arg = { "--foo=bar" }
    populate_optionals(cli)
    result = cli:parse(true --[[no print]])
    assert.is.falsy(result)
  end)

  it("tests unknown flag", function()
    arg = { "--foo" }
    populate_optionals(cli)
    result = cli:parse(true --[[no print]])
    assert.is.falsy(result)
  end)

end)