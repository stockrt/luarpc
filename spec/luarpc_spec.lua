local luarpc = require("luarpc")

-- TODO: Encode/decode with wrong type behavior.

describe("luarpc module", function()
  describe("should work", function()
    -- Encode.
    it("should encode chars", function()
      assert.same("a", luarpc.encode("char", "a"))
    end)

    it("should encode strings", function()
      assert.same("abc", luarpc.encode("string", "abc"))
    end)

    it("should encode new lines", function()
      local x = [[hello
world]]
      assert.same("hello\\nworld", luarpc.encode("string", x))
      assert.same("\\n", luarpc.encode("string", "\n"))
      assert.same("\\n\\n", luarpc.encode("string", "\n\n"))
      assert.same("\\n\\n\\n", luarpc.encode("string", "\n\n\n"))
    end)

    it("should encode slashes", function()
      assert.same("\\\\", luarpc.encode("string", "\\"))
      assert.same("\\\\\\\\", luarpc.encode("string", "\\\\"))
      assert.same("\\\\\\\\\\\\", luarpc.encode("string", "\\\\\\"))
    end)

    it("should encode doubles", function()
      assert.same("3.1415", luarpc.encode("double", 3.1415))
      assert.same("1", luarpc.encode("double", 1))
      assert.same("123", luarpc.encode("double", 123))
    end)

    -- Decode.
    it("should decode chars", function()
      assert.same("a", luarpc.decode("char", "a"))
    end)

    it("should decode strings", function()
      assert.same("abc", luarpc.decode("string", "abc"))
    end)

    it("should decode new lines", function()
      local x = [[hello
world]]
      assert.same(x, luarpc.decode("string", "hello\\nworld"))
      assert.same("\n", luarpc.decode("string", "\\n"))
      assert.same("\n\n", luarpc.decode("string", "\\n\\n"))
      assert.same("\n\n\n", luarpc.decode("string", "\\n\\n\\n"))
    end)

    it("should decode slashes", function()
      assert.same("\\", luarpc.decode("string", "\\\\"))
      assert.same("\\\\", luarpc.decode("string", "\\\\\\\\"))
      assert.same("\\\\\\", luarpc.decode("string", "\\\\\\\\\\\\"))
    end)

    it("should decode doubles", function()
      assert.same(3.1415, luarpc.decode("double", "3.1415"))
      assert.same(1, luarpc.decode("double", "1"))
      assert.same(123, luarpc.decode("double", "123"))
    end)

    -- Back to original.
    it("should decode to original value", function()
      local x = "a"
      assert.same(x, luarpc.decode("char", luarpc.encode("char", x)))

      local x = "a"
      assert.same(x, luarpc.decode("string", luarpc.encode("string", x)))

      local x = [[hello
world]]
      assert.same(x, luarpc.decode("string", luarpc.encode("string", x)))

      local x = "hello\nworld"
      assert.same(x, luarpc.decode("string", luarpc.encode("string", x)))

      local x = "abc"
      assert.same(x, luarpc.decode("string", luarpc.encode("string", x)))

      local x = "\\"
      assert.same(x, luarpc.decode("string", luarpc.encode("string", x)))

      local x = "\\\\"
      assert.same(x, luarpc.decode("string", luarpc.encode("string", x)))

      local x = "\\\\\\"
      assert.same(x, luarpc.decode("string", luarpc.encode("string", x)))

      local x = "\\\\\\\\"
      assert.same(x, luarpc.decode("string", luarpc.encode("string", x)))

      local x = "\\\\\\\\\\"
      assert.same(x, luarpc.decode("string", luarpc.encode("string", x)))

      local x = "\\\\\\\\\\\\"
      assert.same(x, luarpc.decode("string", luarpc.encode("string", x)))

      local x = "\n"
      assert.same(x, luarpc.decode("string", luarpc.encode("string", x)))

      local x = "\n\n"
      assert.same(x, luarpc.decode("string", luarpc.encode("string", x)))

      local x = "\n\n\n"
      assert.same(x, luarpc.decode("string", luarpc.encode("string", x)))

      local x = 3.1415
      assert.same(x, luarpc.decode("double", luarpc.encode("double", x)))

      local x = 1
      assert.same(x, luarpc.decode("double", luarpc.encode("double", x)))

      local x = 123
      assert.same(x, luarpc.decode("double", luarpc.encode("double", x)))
    end)
  end)
end)
