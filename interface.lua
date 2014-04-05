-- Os tipos que podem aparecer nesta especificação de interface são char,
-- string, double e void.
-- Os parâmetros podem ser declarados como in, out ou inout.

-- TODO: Suportar
-- char
-- string
-- double
-- void

interface {
  name = minhaInt,
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
  }
}
