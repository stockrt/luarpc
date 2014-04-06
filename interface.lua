-- Os tipos que podem aparecer nesta especificação de interface são char,
-- string, double e void.
-- Os parâmetros podem ser declarados como in, out ou inout.

-- TODO: Suportar
-- char
-- string
-- double
-- void

-- Interface.
interface {
  name = "myInterface",
  methods = {
    foo = {
      resulttype = "double",
      args = {
        {direction = "in", type = "double"},
        {direction = "in", type = "double"},
        {direction = "out", type = "string"},
      },
    },
    boo = {
      resulttype = "void",
      args = {
        {direction = "inout", type = "double"},
      },
    },
    bar = {
      resulttype = "double",
      args = {
        {direction = "inout", type = "double"},
      },
    },
    baz = {
      resulttype = "string",
      args = {
        {direction = "in", type = "string"},
        {direction = "in", type = "string"},
        {direction = "out", type = "string"},
      },
    },
    cha = {
      resulttype = "string",
      args = {
        {direction = "in", type = "char"},
        {direction = "in", type = "char"},
        {direction = "out", type = "string"},
      },
    },
  }
}
