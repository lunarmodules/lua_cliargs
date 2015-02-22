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
    local args = {}
    result = cli:parse(args)
    assert.are.same(result, {})
  end)

  it("tests uses global arg if arguments set not passed in", function()
    _G.arg = { "--version" }
    defaults = populate_flags(cli)
    defaults.v = true
    defaults.version = true
    result = cli:parse(true --[[no print]])
    assert.are.same(result, defaults)
  end)

  it("tests only optionals, nothing provided", function()
    local args = {}
    defaults = populate_optionals(cli)
    result = cli:parse(args)
    assert.are.same(result, defaults)
  end)

  it("tests only required, all provided", function()
    local args = { "some_file" }
    populate_required(cli)
    result = cli:parse(args)
    assert.are.same(result, { ["INPUT"] = "some_file" })
  end)

  it("tests only optionals, all provided", function()
    local args = { "-o", "/dev/cdrom", "--compress=lzma" }
    populate_optionals(cli)
    result = cli:parse(args)
    assert.are.same(result, { o = "/dev/cdrom", c = "lzma", compress = "lzma" })
  end)

  it("tests optionals + required, all provided", function()
    local args = { "-o", "/dev/cdrom", "-c", "lzma", "some_file" }
    populate_required(cli)
    populate_optionals(cli)
    result = cli:parse(args)
    assert.are.same(result, {
      o = "/dev/cdrom",
      c = "lzma", compress = "lzma",
      ["INPUT"] = "some_file"
    })
  end)

  it("tests optional using -short-key notation", function()
    local args = { "-c", "lzma" }
    defaults = populate_optionals(cli)
    defaults.c = "lzma"
    defaults.compress = "lzma"

    result = cli:parse(args)
    assert.are.same(result, defaults)
  end)

  it("tests optional using --expanded-key notation, --x=VALUE", function()
    local args = { "--compress=lzma" }
    defaults = populate_optionals(cli)
    defaults.c = "lzma"
    defaults.compress = "lzma"

    result = cli:parse(args)

    assert.are.same(result, defaults)
  end)

  it("tests optional using alternate --expanded-key notation, --x VALUE", function()
    local args = { "--compress", "lzma" }
    defaults = populate_optionals(cli)
    defaults.c = "lzma"
    defaults.compress = "lzma"

    result = cli:parse(args)

    assert.are.same(result, defaults)
  end)

  describe("multiple values for a single key", function()
    it("should work for keys that explicitly permit it", function()
      local args = { "--key", "value1", "-k", "value2", "--key=value3" }
      cli:add_option("-k, --key=VALUE", "key that can be specified multiple times", {})
      defaults = { key = {"value1", "value2", "value3"} }
      defaults.k = defaults.key

      result = cli:parse(args)

      assert.are.same(result, defaults)
    end)

    it("should bail if the default value is not an empty table", function()
      assert.is.error(function()
        cli:add_option("-k", "a key that can be specified multiple times", { "foo" })
      end, "Default argument: expected a")
    end)

    it("should print [] as the default value in the --help listing", function()
      cli:add_option("-k, --key=VALUE", "key that can be specified multiple times", {})

      local help_msg = cli:print_help(true)

      assert.is_true(
        nil ~= help_msg:match("key that can be specified multiple times %(default: %[%]%)")
      )
    end)
  end)

  it("tests flag using -short-key notation", function()
    local args = { "-v" }
    defaults = populate_flags(cli)
    defaults.v = true
    defaults.version = true
    result = cli:parse(args)
    assert.are.same(result, defaults)
  end)

  it("tests flag using --expanded-key notation", function()
    local args = { "--version" }
    defaults = populate_flags(cli)
    defaults.v = true
    defaults.version = true
    result = cli:parse(args)
    assert.are.same(result, defaults)
  end)

  it("tests sk-only flag", function()
    local args = { "-d" }
    defaults = populate_flags(cli)
    defaults.d = true
    result = cli:parse(args)
    assert.are.same(result, defaults)
  end)

  it("tests ek-only flag", function()
    local args = { "--verbose" }
    defaults = populate_flags(cli)
    defaults.verbose = true
    result = cli:parse(args)
    assert.are.same(result, defaults)
  end)

  it("tests optionals + required, no optionals and to little required provided, ", function()
    local args = { }
    populate_required(cli)
    populate_optionals(cli)
    result = cli:parse(args, true --[[no print]])
    assert.is.falsy(result)
  end)

  it("tests optionals + required, no optionals and to many required provided, ", function()
    local args = { "some_file", "some_other_file" }
    populate_required(cli)
    populate_optionals(cli)
    result = cli:parse(args, true --[[no print]])
    assert.is.falsy(result)
  end)

  it("tests bad short-key notation, -x=VALUE", function()
    local args = { "-o=some_file" }
    populate_optionals(cli)
    result = cli:parse(args, true --[[no print]])
    assert.is.falsy(result)
  end)

  it("tests unknown option", function()
    local args = { "--foo=bar" }
    populate_optionals(cli)
    result = cli:parse(args, true --[[no print]])
    assert.is.falsy(result)
  end)

  it("tests unknown flag", function()
    local args = { "--foo" }
    populate_optionals(cli)
    result = cli:parse(args, true --[[no print]])
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
    local args = {"/output1/", "/output2/"}
    defaults = populate_optarg(3)
    result = cli:parse(args, true --[[no print]])
    assert.is.same(result, { OUTPUT = {"/output1/", "/output2/"}})
  end)

  it("tests optarg only, values, 1 allowed", function()
    local args = {"/output/"}
    defaults = populate_optarg(1)
    result = cli:parse(args, true --[[no print]])
    assert.is.same(result, { OUTPUT = "/output/" })
  end)

  it("tests optarg only, too many values", function()
    local args = {"/output1/", "/output2/"}
    defaults = populate_optarg(1)
    result = cli:parse(args, true --[[no print]])
    assert.is.same(result, nil)
  end)

  it("tests optarg only, too many values", function()
    local args = {"/input/", "/output/"}
    populate_required()
    populate_optarg(1)
    result = cli:parse(args, true --[[no print]])
    assert.is.same(result, { INPUT = "/input/", OUTPUT = "/output/" })
  end)

  it("tests clearing the default of an optional", function()
    local err
    local args = { "--compress=" }
    populate_optionals(cli)
    result, err = cli:parse(args, true --[[no print]])
    assert.are.equal(nil,err)
    -- are_not.equal is not working when comparing against a nil as
    -- of luassert-1.2-1, using is.truthy instead for now
    -- assert.are_not.equal(nil,result)
    assert.is.truthy(result)
    assert.are.equal("", result.compress)
  end)

  it("tests parsing a flag (expanded-key) with a value provided", function()
    local args = { "--verbose=something" }
    defaults = populate_flags(cli)
    defaults.verbose = true
    local result, err = cli:parse(args, true --[[no print]])
    assert(result == nil, "Adding a value to a flag must error out")
    assert(type(err) == "string", "Expected an error string")
  end)

end)
