local subject = require('cliargs.utils.wordwrap')

describe("utils::wordwrap", function()
  it("should work", function()
    -- takes: text, size, padding
    local text = "123456789 123456789 123456789!"
    local expected, result

    result = subject(text, 10)
    expected = "123456789\n123456789\n123456789!"
    assert.is.same(result, expected)

    -- exact length + 1 overflow
    result = subject(text, 9)
    expected = "123456789\n123456789\n123456789\n!"
    assert.is.same(result, expected)

    result = subject(text, 9, nil, true)
    expected = "123456789\n123456789\n123456789!"
    assert.is.same(result, expected)

    result = subject(text, 8)
    expected = "12345678\n9\n12345678\n9\n12345678\n9!"
    assert.is.same(result, expected)
  end)
end)
