local cli, defaults, result

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
local function populate_required()
  cli:add_argument("INPUT", "path to the input file")

  return { ["INPUT"] = nil }
end
local function populate_optarg(cnt)
  cnt = cnt or 1
  cli:optarg("OUTPUT", "path to the output file", "./out", cnt)
  if cnt == 1 then
    return { OUTPUT = "./out" }
  else
    return { OUTPUT = {"./out"}}
  end
end
local function populate_optionals()
  cli:add_option("-c, --compress=FILTER", "the filter to use for compressing output: gzip, lzma, bzip2, or none", "gzip")
  cli:add_option("-o FILE", "path to output file", "/dev/stdout")  

  return { c = "gzip", compress = "gzip", o = "/dev/stdout" }
end
local function populate_flags()
  cli:add_flag("-d", "script will run in DEBUG mode")
  cli:add_flag("-v, --version", "prints the program's version and exits")
  cli:add_flag("--verbose", "the script output will be very verbose")  

  return { d = false, v = false, version = false, verbose = false }
end

-- start tests
describe("Testing cliargs library parsing commandlines", function()

  setup(function()
    _G._TEST = true
  end)

  teardown(function()
    _G._TEST = nil
  end)

  before_each(function()
    _G.arg = nil
    package.loaded.cliargs = nil  -- Busted uses it, but must force to reload 
    cli = require("cliargs")
  end)

  it("tests no arguments set, nor provided", function()
    result = cli:parse()
    assert.are.same(result, {})
  end)
  
  it("tests only optionals, nothing provided", function()
    defaults = populate_optionals(cli)
    result = cli:parse()
    assert.are.same(result, defaults)
  end)
  
  it("tests only required, all provided", function()
    _G.arg = { "some_file" }
    populate_required(cli)
    result = cli:parse()
    assert.are.same(result, { ["INPUT"] = "some_file" })
  end)
  
  it("tests only optionals, all provided", function()
    _G.arg = { "-o", "/dev/cdrom", "--compress=lzma" }
    populate_optionals(cli)
    result = cli:parse()
    assert.are.same(result, { o = "/dev/cdrom", c = "lzma", compress = "lzma" })
  end)
  
  it("tests optionals + required, all provided", function()
    _G.arg = { "-o", "/dev/cdrom", "-c", "lzma", "some_file" }
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
    _G.arg = { "-c", "lzma" }
    defaults = populate_optionals(cli)
    defaults.c = "lzma"
    defaults.compress = "lzma"

    result = cli:parse()
    assert.are.same(result, defaults)
  end)

  it("tests optional using --expanded-key notation, --x=VALUE", function()
    _G.arg = { "--compress=lzma" }
    defaults = populate_optionals(cli)
    defaults.c = "lzma"
    defaults.compress = "lzma"

    result = cli:parse()

    assert.are.same(result, defaults)
  end)
  
  it("tests optional using alternate --expanded-key notation, --x VALUE", function()
    _G.arg = { "--compress", "lzma" }
    defaults = populate_optionals(cli)
    defaults.c = "lzma"
    defaults.compress = "lzma"

    result = cli:parse()

    assert.are.same(result, defaults)
  end)

  it("tests flag using -short-key notation", function()
    _G.arg = { "-v" }
    defaults = populate_flags(cli)
    defaults.v = true
    defaults.version = true
    result = cli:parse()
    assert.are.same(result, defaults)
  end)

  it("tests flag using --expanded-key notation", function()
    _G.arg = { "--version" }
    defaults = populate_flags(cli)
    defaults.v = true
    defaults.version = true
    result = cli:parse()
    assert.are.same(result, defaults)
  end)
  
  it("tests sk-only flag", function()
    _G.arg = { "-d" }
    defaults = populate_flags(cli)
    defaults.d = true
    result = cli:parse()
    assert.are.same(result, defaults)
  end)
    
  it("tests ek-only flag", function()
    _G.arg = { "--verbose" }
    defaults = populate_flags(cli)
    defaults.verbose = true
    result = cli:parse()
    assert.are.same(result, defaults)
  end)
  
  it("tests optionals + required, no optionals and to little required provided, ", function()
    _G.arg = { }
    populate_required(cli)
    populate_optionals(cli)
    result = cli:parse(true --[[no print]])
    assert.is.falsy(result)
  end)

  it("tests optionals + required, no optionals and to many required provided, ", function()
    _G.arg = { "some_file", "some_other_file" }
    populate_required(cli)
    populate_optionals(cli)
    result = cli:parse(true --[[no print]])
    assert.is.falsy(result)
  end)
  
  it("tests bad short-key notation, -x=VALUE", function()
    _G.arg = { "-o=some_file" }
    populate_optionals(cli)
    result = cli:parse(true --[[no print]])
    assert.is.falsy(result)
  end)
  
  it("tests unknown option", function()
    _G.arg = { "--foo=bar" }
    populate_optionals(cli)
    result = cli:parse(true --[[no print]])
    assert.is.falsy(result)
  end)

  it("tests unknown flag", function()
    _G.arg = { "--foo" }
    populate_optionals(cli)
    result = cli:parse(true --[[no print]])
    assert.is.falsy(result)
  end)

  it("tests optarg only, defaults, multiple allowed", function()
    defaults = populate_optarg(3)
    result,err = cli:parse(true --[[no print]])
    assert.is.same(defaults, result)
  end)

  it("tests optarg only, defaults, 1 allowed", function()
    defaults = populate_optarg(1)
    result = cli:parse(true --[[no print]])
    assert.is.same(defaults, result)
  end)

  it("tests optarg only, values, multiple allowed", function()
    _G.arg = {"/output1/", "/output2/"}
    defaults = populate_optarg(3)
    result = cli:parse(true --[[no print]])
    assert.is.same(result, { OUTPUT = {"/output1/", "/output2/"}})
  end)

  it("tests optarg only, values, 1 allowed", function()
    _G.arg = {"/output/"}
    defaults = populate_optarg(1)
    result = cli:parse(true --[[no print]])
    assert.is.same(result, { OUTPUT = "/output/" })
  end)

  it("tests optarg only, too many values", function()
    _G.arg = {"/output1/", "/output2/"}
    defaults = populate_optarg(1)
    result = cli:parse(true --[[no print]])
    assert.is.same(result, nil)
  end)

  it("tests optarg only, too many values", function()
    _G.arg = {"/input/", "/output/"}
    populate_required()
    populate_optarg(1)
    result = cli:parse(true --[[no print]])
    assert.is.same(result, { INPUT = "/input/", OUTPUT = "/output/" })
  end)

  it("tests clearing the default of an optional", function()
    local err
    _G.arg = { "--compress=" }
    populate_optionals(cli)
    result, err = cli:parse(true --[[no print]])
    assert.are.equal(nil,err)
    -- are_not.equal is not working when comparing against a nil as
    -- of luassert-1.2-1, using is.truthy instead for now
    -- assert.are_not.equal(nil,result)
    assert.is.truthy(result)
    assert.are.equal("", result.compress)
  end)

  it("tests parsing a flag (expanded-key) with a value provided", function()
    _G.arg = { "--verbose=something" }
    defaults = populate_flags(cli)
    defaults.verbose = true
    local result, err = cli:parse(true --[[no print]])
    assert(result == nil, "Adding a value to a flag must error out")
    assert(type(err) == "string", "Expected an error string")
  end)

  describe("Tests parsing with callback", function()
    local cb = {}

    local function callback(key, value, altkey)
        cb.key, cb.value, cb.altkey = key, value, altkey
    end

    before_each(function()
      cb = {}
    end)

    it("tests short-key option", function()
      _G.arg = { "-k", "myvalue" }
      cli:add_option("-k, --long-key=VALUE", "key descriptioin", "", callback)
      local expected = { k = "myvalue", ["long-key"] = "myvalue" }
      local result = cli:parse()
      assert.are.same(expected, result)
      assert.are.equal(cb.key, "k")
      assert.are.equal(cb.value, "myvalue")
      assert.are.equal(cb.altkey, "long-key")
    end)

    it("tests expanded-key option", function()
      _G.arg = { "--long-key", "val" }
      cli:add_option("-k, --long-key=VALUE", "key descriptioin", "", callback)
      local expected = { k = "val", ["long-key"] = "val" }
      local result = cli:parse()
      assert.are.same(expected, result)
      assert.are.equal(cb.key, "long-key")
      assert.are.equal(cb.value, "val")
      assert.are.equal(cb.altkey, "k")
    end)

    it("tests expanded-key flag with not short-key", function()
      _G.arg = { "--version" }
      cli:add_flag("--version", "prints the version and exits", callback)
      local expected = { version = true }
      local result = cli:parse()
      assert.are.same(expected, result)
      assert.are.equal(cb.key, "version")
      assert.are.equal(cb.value, true)
      assert.are.equal(cb.altkey, nil)
    end)

  end)

end)
