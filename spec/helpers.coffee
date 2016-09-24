TextEditor = null

module.exports =
  buildTextEditor: (params) ->
    if atom.workspace.buildTextEditor?
      atom.workspace.buildTextEditor(params)
    else
      TextEditor ?= require('atom').TextEditor
      new TextEditor(params)
