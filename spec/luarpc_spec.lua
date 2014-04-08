local luarpc = require("luarpc")

describe("luarpc module", function()
  describe("should work", function()
    -- encode
    it("should encode chars", function()
      assert.same(luarpc.encode("char", "a"), "a")
    end)

    it("should encode strings", function()
      assert.same(luarpc.encode("string", "abc"), "abc")
    end)

    it("should encode new lines", function()
      assert.same(luarpc.encode("string", "\n"), "\\n")
    end)

    it("should encode slashes", function()
      assert.same(luarpc.encode("string", "\\"), "\\\\")

      assert.same(luarpc.encode("string", "\\n"), "\\\\n")
      assert.same(luarpc.encode("string", "n\\"), "n\\\\")
      assert.same(luarpc.encode("string", "n\\n"), "n\\\\n")

      assert.same(luarpc.encode("string", "\\n\\n"), "\\\\n\\\\n")
      assert.same(luarpc.encode("string", "n\\n\\"), "n\\\\n\\\\")
      assert.same(luarpc.encode("string", "n\\n\\n"), "n\\\\n\\\\n")
    end)

    it("should encode doubles", function()
      assert.same(luarpc.encode("double", 3.1415), "3.1415")
    end)

    -- decode
    it("should decode chars", function()
      assert.same(luarpc.decode("char", "a"), "a")
    end)

    it("should decode strings", function()
      assert.same(luarpc.decode("string", "abc"), "abc")
    end)

    it("should decode new lines", function()
      assert.same(luarpc.decode("string", "\\n"), "\n")
    end)

    it("should decode slashes", function()
      assert.same(luarpc.decode("string", "\\\\"), "\\")

      assert.same(luarpc.decode("string", "\\\\n"), "\\n")
      assert.same(luarpc.decode("string", "n\\\\"), "n\\")
      assert.same(luarpc.decode("string", "n\\\\n"), "n\\n")

      assert.same(luarpc.decode("string", "\\\\n\\\\n"), "\\n\\n")
      assert.same(luarpc.decode("string", "n\\\\n\\\\"), "n\\n\\")
      assert.same(luarpc.decode("string", "n\\\\n\\\\n"), "n\\n\\n")
    end)

    it("should decode doubles", function()
      assert.same(luarpc.decode("double", "3.1415"), 3.1415)
    end)

    -- back to original
    it("should decode to original value", function()
      assert.same(luarpc.decode("char", luarpc.encode("char", "a")), "a")
      assert.same(luarpc.decode("string", luarpc.encode("string", "a")), "a")
      assert.same(luarpc.decode("string", luarpc.encode("string", "abc")), "abc")
      assert.same(luarpc.decode("string", luarpc.encode("string", "\\")), "\\")
      assert.same(luarpc.decode("string", luarpc.encode("string", "\\\\")), "\\\\")
      assert.same(luarpc.decode("string", luarpc.encode("string", "a\\b")), "a\\b")
      assert.same(luarpc.decode("string", luarpc.encode("string", "a\n")), "a\n")
      assert.same(luarpc.decode("string", luarpc.encode("string", "\na")), "\na")
      assert.same(luarpc.decode("string", luarpc.encode("string", "\n")), "\n")
      assert.same(luarpc.decode("string", luarpc.encode("string", "\\n")), "\\n")
      assert.same(luarpc.decode("string", luarpc.encode("string", "\\\n")), "\\\n")
      assert.same(luarpc.decode("string", luarpc.encode("string", "\\\\n")), "\\\\n")
      assert.same(luarpc.decode("string", luarpc.encode("string", "\n\n"), "\n\n"))
      assert.same(luarpc.decode("string", luarpc.encode("string", "\n\n\n"), "\n\n\n"))
      assert.same(luarpc.decode("string", luarpc.encode("string", "\\n\\"), "\\n\\"))
      assert.same(luarpc.decode("string", luarpc.encode("string", "\\n\\n\\"), "\\n\\n\\"))
      assert.same(luarpc.decode("string", luarpc.encode("string", "\\\\n\\\\n\\\\"), "\\\\n\\\\n\\\\"))
      assert.same(luarpc.decode("string", luarpc.encode("string", "\\\n\\n\\"), "\\\n\\n\\"))
      assert.same(luarpc.decode("string", luarpc.encode("string", "\\\n\\\n\\"), "\\\n\\\n\\"))
      assert.same(luarpc.decode("string", luarpc.encode("string", "n\\n"), "n\\n"))
      assert.same(luarpc.decode("string", luarpc.encode("string", "n\\\n"), "n\\\n"))
      assert.same(luarpc.decode("string", luarpc.encode("string", "n\\\\n"), "n\\\\n"))
      assert.same(luarpc.decode("double", luarpc.encode("double", 3.1415)), 3.1415)
    end)
  end)
end)
