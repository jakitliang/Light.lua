package = "Light"
version = "0.3-2"

source = {
  url = "git@github.com:jakitliang/Light.lua.git",
}

description = {
  summary = "If I were the other shore, bright & magnanimous.",
  homepage = "https://github.com/jakitliang/Light",
  license = "BSD 2-Clause License",
  detailed = "Framework of everything"
}

dependencies = {
  "lua >= 5.1",
  "compat53 >= 0.7-1",
}

build = {
  modules = {
    ['Light.Object'] = 'Light/Object.lua',
  },
  type = 'builtin'
}
