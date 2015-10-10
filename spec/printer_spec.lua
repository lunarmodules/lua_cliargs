describe('printer', function()
  local cli

  before_each(function()
    cli = require("cliargs.core")()
  end)

  describe('for a repeatable/list-like option', function()
    it("should print [] as the default value in the --help listing", function()
      cli:add_option("-k, --key=VALUE", "key that can be specified multiple times", {})

      local help_msg = cli:print_help(true)

      assert.matches(
        "key that can be specified multiple times %(default: %[%]%)",
        help_msg
      )
    end)
  end)
end)