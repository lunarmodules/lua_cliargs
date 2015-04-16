-- luacheck: globals describe it before_each, ignore dump

local cli

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
  cli:add_flag("-v, --version", "prints the program's version and exits")
  cli:add_flag("-d", "script will run in DEBUG mode")
  cli:add_flag("--verbose", "the script output will be very verbose")

  return { d = nil, v = nil, version = nil, verbose = nil }
end

-- start tests
describe("Testing cliargs library parsing commandlines", function()
  before_each(function()
    package.loaded.cliargs = nil  -- Busted uses it, but must force to reload
    cli = require("cliargs")
  end)

  it("tests no arguments set, nor provided", function()
    local args = {}
    local result = cli:parse(args)
    assert.are.same(result, {})
  end)

  it("tests uses global arg if arguments set not passed in", function()
    local defaults = populate_flags(cli)
    defaults.v = true
    defaults.version = true
    local result = cli:parse({ "--version" }, true --[[no print]])
    assert.are.same(result, defaults)
  end)

  it("tests only optionals, nothing provided", function()
    local args = {}
    local defaults = populate_optionals(cli)
    local result = cli:parse(args)
    assert.are.same(result, defaults)
  end)

  it("tests only required, all provided", function()
    local args = { "some_file" }
    populate_required(cli)
    local result = cli:parse(args)
    assert.are.same(result, { ["INPUT"] = "some_file" })
  end)

  it("tests only optionals, all provided", function()
    local args = { "-o", "/dev/cdrom", "--compress=lzma" }
    populate_optionals(cli)
    local result = cli:parse(args)
    assert.are.same(result, { o = "/dev/cdrom", c = "lzma", compress = "lzma" })
  end)

  it("tests optionals + required, all provided", function()
    local args = { "-o", "/dev/cdrom", "-c", "lzma", "some_file" }
    populate_required(cli)
    populate_optionals(cli)
    local result = cli:parse(args)
    assert.are.same(result, {
      o = "/dev/cdrom",
      c = "lzma", compress = "lzma",
      ["INPUT"] = "some_file"
    })
  end)

  it("tests optional using -short-key notation", function()
    local defaults = populate_optionals(cli)
    defaults.c = "lzma"
    defaults.compress = "lzma"

    local result = cli:parse({ "-c", "lzma" })
    assert.are.same(result, defaults)
  end)

  it("tests option using -short-key value notation", function()
    cli:add_opt("-out VALUE", "output file")
    local defaults = { out = "outfile" }
    local result = cli:parse({ "-out", "outfile" })
    assert.are.same(result, defaults)
  end)

  it("tests optional using --expanded-key notation, --x=VALUE", function()
    local defaults = populate_optionals(cli)
    defaults.c = "lzma"
    defaults.compress = "lzma"

    local result = cli:parse({ "--compress=lzma" })

    assert.are.same(result, defaults)
  end)

  it("tests optional using alternate --expanded-key notation, --x VALUE", function()
    local defaults = populate_optionals(cli)
    defaults.c = "lzma"
    defaults.compress = "lzma"

    local result = cli:parse({ "--compress", "lzma" })

    assert.are.same(result, defaults)
  end)

  describe("no-flag", function()
    it("can set default to false for flag", function()
      cli:add_flag("-R, --[no-]recursive", "copy recursively", false)
      local expected = { R = false, recursive = false }
      local result = cli:parse({})
      assert.are.same(expected, result)
    end)

    it("can set default to true for flag", function()
      cli:add_flag("-R, --[no-]recursive", "copy recursively", true)
      local expected = { R = true, recursive = true }
      local result = cli:parse({})
      assert.are.same(expected, result)
    end)

    it("sets flag value to false", function()
      cli:add_flag("-k, --[no-]keep-going", "continue as much as possible after an error", true)
      local expected = { k = false, ['keep-going'] = false }
      local result = cli:parse({ "--no-keep-going" })
      assert.are.same(expected, result)
    end)

    it("sets flag value true then overwrites to false", function()
      cli:add_flag("-k, --[no-]keep-going", "continue as much as possible after an error", true)
      local expected = { k = false, ['keep-going'] = false }
      local result = cli:parse({ "-k", "--no-keep-going" })
      assert.are.same(expected, result)
    end)

    it("sets flag value false then overwrites to true", function()
      cli:add_flag("-k, --[no-]keep-going", "continue as much as possible after an error", true)
      local expected = { k = true, ['keep-going'] = true }
      local result = cli:parse({ "--no-keep-going", "--keep-going" })
      assert.are.same(expected, result)
    end)
  end)

  describe("multiple values for a single key", function()
    it("should work for keys that explicitly permit it", function()
      cli:add_option("-k, --key=VALUE", "key that can be specified multiple times", {})

      local defaults = { key = {"value1", "value2", "value3"} }
      defaults.k = defaults.key

      local result = cli:parse({ "--key", "value1", "-k", "value2", "--key=value3" })

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

  describe("flag options", function()
    it("should turn them on using the -short-key notation", function()
      local defaults = populate_flags(cli)
      defaults.v = true
      defaults.version = true
      local result = cli:parse({ "-v" })
      assert.are.same(result, defaults)
    end)

    it("should turn them on using the --expanded-key notation", function()
      local defaults = populate_flags(cli)
      defaults.v = true
      defaults.version = true
      local result = cli:parse({ "--version" })
      assert.are.same(result, defaults)
    end)

    describe("given a -short-key only flag option", function()
      it("works", function()
        cli:add_flag("-d", "script will run in DEBUG mode")
        local result = cli:parse({ "-d" })
        assert.are.same(result, { d = true })
      end)
    end)

    describe("given an --expanded-key only flag option", function()
      it("works", function()
        local defaults = populate_flags(cli)
        defaults.verbose = true
        local result = cli:parse({ "--verbose" })
        assert.are.same(result, defaults)
      end)
    end)

    describe("given a value for a flag", function()
      it("bails", function()
        local defaults = populate_flags(cli)
        defaults.verbose = true
        local result, err = cli:parse({ "--verbose=something" }, true --[[no print]])

        assert(result == nil, "Adding a value to a flag must error out")
        assert(type(err) == "string", "Expected an error string")
      end)
    end)
  end)

  it("tests optionals + required, no optionals and to little required provided, ", function()
    populate_required(cli)
    populate_optionals(cli)
    local result = cli:parse({}, true --[[no print]])
    assert.is.falsy(result)
  end)

  it("tests optionals + required, no optionals and too many required provided, ", function()
    populate_required(cli)
    populate_optionals(cli)
    local result = cli:parse({ "some_file", "some_other_file" }, true --[[no print]])
    assert.is.falsy(result)
  end)

  it("tests optionals + required + optarg, '--' as end of optionals", function()
    populate_required(cli)
    populate_optarg(1)
    local expected = populate_flags(cli)
    expected.INPUT = "--input"
    expected.OUTPUT = "-d"
    expected.verbose = true
    local result = cli:parse({ "--verbose", "--", "--input", "-d" })
    assert.is.same(expected, result)
  end)

  it("tests bad short-key notation, -x=VALUE", function()
    populate_optionals(cli)
    local result = cli:parse({ "-o=some_file" }, true --[[no print]])
    assert.is.falsy(result)
  end)

  it("tests unknown option", function()
    populate_optionals(cli)
    local result = cli:parse({ "--foo=bar" }, true --[[no print]])
    assert.is.falsy(result)
  end)

  it("tests unknown flag", function()
    populate_optionals(cli)
    local result = cli:parse({ "--foo" }, true --[[no print]])
    assert.is.falsy(result)
  end)

  it("tests optarg only, defaults, multiple allowed", function()
    local defaults = populate_optarg(3)
    local result = cli:parse(defaults, true --[[no print]])
    assert.is.same(defaults, result)
  end)

  it("tests optarg only, defaults, 1 allowed", function()
    local defaults = populate_optarg(1)
    local result = cli:parse(defaults, true --[[no print]])
    assert.is.same(defaults, result)
  end)

  it("tests optarg only, values, multiple allowed", function()
    populate_optarg(3)
    local result = cli:parse({"/output1/", "/output2/"}, true --[[no print]])
    assert.is.same(result, { OUTPUT = {"/output1/", "/output2/"}})
  end)

  it("tests optarg only, values, 1 allowed", function()
    populate_optarg(1)
    local result = cli:parse({"/output/"}, true --[[no print]])
    assert.is.same(result, { OUTPUT = "/output/" })
  end)

  it("tests optarg only, too many values", function()
    populate_optarg(1)
    local result = cli:parse({"/output1/", "/output2/"}, true --[[no print]])
    assert.is.same(result, nil)
  end)

  it("tests optarg only, too many values", function()
    populate_required()
    populate_optarg(1)
    local result = cli:parse({"/input/", "/output/"}, true --[[no print]])
    assert.is.same(result, { INPUT = "/input/", OUTPUT = "/output/" })
  end)

  it("tests clearing the default of an optional", function()
    populate_optionals(cli)
    local result, err = cli:parse({ "--compress=" }, true --[[no print]])
    assert.are.equal(nil,err)
    -- are_not.equal is not working when comparing against a nil as
    -- of luassert-1.2-1, using is.truthy instead for now
    -- assert.are_not.equal(nil,result)
    assert.is.truthy(result)
    assert.are.equal("", result.compress)
  end)

  describe("Tests options parsing with callback", function()
    local cb = {}

    local function callback(key, value, altkey)
      cb.key, cb.value, cb.altkey = key, value, altkey
      return true
    end

    local function callback_fail(_, _, _, opt)
      return nil, "bad argument to " .. opt
    end

    before_each(function()
      cb = {}
    end)

    it("tests short-key option", function()
      cli:add_option("-k, --long-key=VALUE", "key description", "", callback)
      local expected = { k = "myvalue", ["long-key"] = "myvalue" }
      local result = cli:parse({ "-k", "myvalue" })
      assert.are.same(expected, result)
      assert.are.equal("k", cb.key)
      assert.are.equal("myvalue", cb.value)
      assert.are.equal("long-key", cb.altkey)
    end)

    it("tests expanded-key option", function()
      cli:add_option("-k, --long-key=VALUE", "key description", "", callback)
      local expected = { k = "val", ["long-key"] = "val" }
      local result = cli:parse({ "--long-key", "val" })
      assert.are.same(expected, result)
      assert.are.equal("long-key", cb.key)
      assert.are.equal("val", cb.value)
      assert.are.equal("k", cb.altkey)
    end)

    it("tests expanded-key flag with not short-key", function()
      cli:add_flag("--version", "prints the version and exits", callback)
      local expected = { version = true }
      local result = cli:parse({ "--version" })
      assert.are.same(expected, result)
      assert.are.equal("version", cb.key)
      assert.are.equal(true, cb.value)
      assert.are.equal(nil, cb.altkey)
    end)

    it("tests callback for no-flags", function()
      cli:add_flag("-k, --[no-]long-key", "key description", callback)
      local expected = { k = false, ["long-key"] = false }
      local result = cli:parse({ "--no-long-key" })
      assert.are.same(expected, result)
      assert.are.equal("long-key", cb.key)
      assert.are.equal(false, cb.value)
      assert.are.equal("k", cb.altkey)
    end)

    it("tests callback returning error", function()
      cli:set_name('myapp')
      cli:add_option("-k, --long-key=VALUE", "key description", "", callback_fail)
      local result, err = cli:parse({ "--long-key", "val" }, true --[[no print]])
      assert(result == nil, "Failure in callback returns nil")
      assert(type(err) == "string", "Expected an error string")
      assert.are.equal(err, "myapp: error: bad argument to --long-key; re-run with --help for usage.")
    end)
  end)

  describe("Tests argument parsing with callback", function()
    local cb = {}

    local function callback(key, value)
      cb.key, cb.value = key, value
      return true
    end

    local function callback_arg(key, value)
      table.insert(cb, { key = key, value = value })
      return true
    end

    local function callback_fail(key)
      return nil, "bad argument for " .. key
    end

    before_each(function()
      cb = {}
    end)

    it("tests one required argument", function()
      cli:add_arg("ARG", "arg description", callback)
      local expected = { ARG = "arg_val" }
      local result = cli:parse({ "arg_val" })
      assert.are.same(expected, result)
      assert.are.equal("ARG", cb.key)
      assert.are.equal("arg_val", cb.value)
    end)

    it("tests required argument callback returning error", function()
      cli:set_name('myapp')
      cli:add_arg("ARG", "arg description", callback_fail)
      local result, err = cli:parse({ "arg_val" }, true --[[no print]])
      assert(result == nil, "Failure in callback returns nil")
      assert(type(err) == "string", "Expected an error string")
      assert.are.equal(err, "myapp: error: bad argument for ARG; re-run with --help for usage.")
    end)

    it("tests many required arguments", function()
      cli:add_arg("ARG1", "arg1 description", callback_arg)
      cli:add_arg("ARG2", "arg2 description", callback_arg)
      cli:add_arg("ARG3", "arg3 description", callback_arg)
      local expected = { ARG1 = "arg1_val", ARG2 = "arg2_val", ARG3 = "arg3_val" }
      local result = cli:parse({ "arg1_val", "arg2_val", "arg3_val" })
      assert.are.same(expected, result)
      assert.are.same({ key = "ARG1", value = "arg1_val"}, cb[1])
      assert.are.same({ key = "ARG2", value = "arg2_val"}, cb[2])
      assert.are.same({ key = "ARG3", value = "arg3_val"}, cb[3])
    end)

    it("tests one optional argument", function()
      cli:optarg("OPTARG", "optional arg description", nil, 1, callback)
      local expected = { OPTARG = "opt_arg" }
      local result = cli:parse({ "opt_arg" })
      assert.are.same(expected, result)
      assert.are.equal("OPTARG", cb.key)
      assert.are.equal("opt_arg", cb.value)
    end)

    it("tests optional argument callback returning error", function()
      cli:set_name('myapp')
      cli:optarg("OPTARG", "optinoal arg description", nil, 1, callback_fail)
      local result, err = cli:parse({ "opt_arg" }, true --[[no print]])
      assert(result == nil, "Failure in callback returns nil")
      assert(type(err) == "string", "Expected an error string")
      assert.are.equal(err, "myapp: error: bad argument for OPTARG; re-run with --help for usage.")
    end)

    it("tests many optional arguments", function()
      cli:optarg("OPTARG", "optional arg description", nil, 3, callback_arg)
      local expected = { OPTARG = { "opt_arg1", "opt_arg2", "opt_arg3" } }
      local result = cli:parse({ "opt_arg1", "opt_arg2", "opt_arg3" })
      assert.are.same(expected, result)
      assert.are.same({ key = "OPTARG", value = "opt_arg1"}, cb[1])
      assert.are.same({ key = "OPTARG", value = "opt_arg2"}, cb[2])
      assert.are.same({ key = "OPTARG", value = "opt_arg3"}, cb[3])
    end)
  end)
end)
