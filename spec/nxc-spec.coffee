TextEditor = null
buildTextEditor = (params) ->
  if atom.workspace.buildTextEditor?
    atom.workspace.buildTextEditor(params)
  else
    TextEditor ?= require('atom').TextEditor
    new TextEditor(params)

describe "Language-NXC", ->
  grammar = null

  beforeEach ->
    waitsForPromise ->
      atom.packages.activatePackage('language-nxc')

  describe "NXC", ->
    beforeEach ->
      grammar = atom.grammars.grammarForScopeName('source.nxc')

    it "parses the grammar", ->
      expect(grammar).toBeTruthy()
      expect(grammar.scopeName).toBe 'source.nxc'

    it "tokenizes functions", ->
      lines = grammar.tokenizeLines '''
        int something(int param) {
          return 0;
        }
      '''
      expect(lines[0][0]).toEqual value: 'int', scopes: ['source.nxc', 'storage.type.nxc']
      expect(lines[0][2]).toEqual value: 'something', scopes: ['source.nxc', 'meta.function.nxc', 'entity.name.function.nxc']
      expect(lines[0][3]).toEqual value: '(', scopes: ['source.nxc', 'meta.function.nxc', 'meta.parens.nxc', 'punctuation.section.parens.begin.nxc']
      expect(lines[0][4]).toEqual value: 'int', scopes: ['source.nxc', 'meta.function.nxc', 'meta.parens.nxc', 'storage.type.nxc']
      expect(lines[0][6]).toEqual value: ')', scopes: ['source.nxc', 'meta.function.nxc', 'meta.parens.nxc', 'punctuation.section.parens.end.nxc']
      expect(lines[0][8]).toEqual value: '{', scopes: ['source.nxc', 'meta.function.nxc', 'meta.block.nxc', 'punctuation.section.block.begin.nxc']
      expect(lines[1][1]).toEqual value: 'return', scopes: ['source.nxc', 'meta.function.nxc', 'meta.block.nxc', 'keyword.control.nxc']
      expect(lines[1][3]).toEqual value: '0', scopes: ['source.nxc', 'meta.function.nxc', 'meta.block.nxc', 'constant.numeric.nxc']
      expect(lines[2][0]).toEqual value: '}', scopes: ['source.nxc', 'meta.function.nxc', 'meta.block.nxc', 'punctuation.section.block.end.nxc']

    it "tokenizes various _t types", ->
      {tokens} = grammar.tokenizeLine 'size_t var;'
      expect(tokens[0]).toEqual value: 'size_t', scopes: ['source.nxc', 'support.type.sys-types.nxc']

      {tokens} = grammar.tokenizeLine 'pthread_t var;'
      expect(tokens[0]).toEqual value: 'pthread_t', scopes: ['source.nxc', 'support.type.pthread.nxc']

      {tokens} = grammar.tokenizeLine 'int32_t var;'
      expect(tokens[0]).toEqual value: 'int32_t', scopes: ['source.nxc', 'support.type.stdint.nxc']

      {tokens} = grammar.tokenizeLine 'myType_t var;'
      expect(tokens[0]).toEqual value: 'myType_t', scopes: ['source.nxc', 'support.type.posix-reserved.nxc']

    it "tokenizes 'line continuation' character", ->
      {tokens} = grammar.tokenizeLine 'ma' + '\\' + '\n' + 'in(){};'
      expect(tokens[0]).toEqual value: 'ma', scopes: ['source.nxc']
      expect(tokens[1]).toEqual value: '\\', scopes: ['source.nxc', 'constant.character.escape.line-continuation.nxc']
      expect(tokens[3]).toEqual value: 'in', scopes: ['source.nxc', 'meta.function.nxc', 'entity.name.function.nxc']

    describe "strings", ->
      it "tokenizes them", ->
        delimsByScope =
          'string.quoted.double.nxc': '"'
          'string.quoted.single.nxc': '\''

        for scope, delim of delimsByScope
          {tokens} = grammar.tokenizeLine delim + 'a' + delim
          expect(tokens[0]).toEqual value: delim, scopes: ['source.nxc', scope, 'punctuation.definition.string.begin.nxc']
          expect(tokens[1]).toEqual value: 'a', scopes: ['source.nxc', scope]
          expect(tokens[2]).toEqual value: delim, scopes: ['source.nxc', scope, 'punctuation.definition.string.end.nxc']

          {tokens} = grammar.tokenizeLine delim + 'a' + '\\' + '\n' + 'b' + delim
          expect(tokens[0]).toEqual value: delim, scopes: ['source.nxc', scope, 'punctuation.definition.string.begin.nxc']
          expect(tokens[1]).toEqual value: 'a', scopes: ['source.nxc', scope]
          expect(tokens[2]).toEqual value: '\\', scopes: ['source.nxc', scope, 'constant.character.escape.line-continuation.nxc']
          expect(tokens[4]).toEqual value: 'b', scopes: ['source.nxc', scope]
          expect(tokens[5]).toEqual value: delim, scopes: ['source.nxc', scope, 'punctuation.definition.string.end.nxc']

    describe "comments", ->
      it "tokenizes them", ->
        {tokens} = grammar.tokenizeLine '/**/'
        expect(tokens[0]).toEqual value: '/*', scopes: ['source.nxc', 'comment.block.nxc', 'punctuation.definition.comment.begin.nxc']
        expect(tokens[1]).toEqual value: '*/', scopes: ['source.nxc', 'comment.block.nxc', 'punctuation.definition.comment.end.nxc']

        {tokens} = grammar.tokenizeLine '/* foo */'
        expect(tokens[0]).toEqual value: '/*', scopes: ['source.nxc', 'comment.block.nxc', 'punctuation.definition.comment.begin.nxc']
        expect(tokens[1]).toEqual value: ' foo ', scopes: ['source.nxc', 'comment.block.nxc']
        expect(tokens[2]).toEqual value: '*/', scopes: ['source.nxc', 'comment.block.nxc', 'punctuation.definition.comment.end.nxc']

        {tokens} = grammar.tokenizeLine '*/*'
        expect(tokens[0]).toEqual value: '*/*', scopes: ['source.nxc', 'invalid.illegal.stray-comment-end.nxc']

    describe "preprocessor directives", ->
      it "tokenizes '#line'", ->
        {tokens} = grammar.tokenizeLine '#line 151 "copy.c"'
        expect(tokens[0]).toEqual value: '#', scopes: ['source.nxc', 'meta.preprocessor.nxc', 'keyword.control.directive.line.nxc', 'punctuation.definition.directive.nxc']
        expect(tokens[1]).toEqual value: 'line', scopes: ['source.nxc', 'meta.preprocessor.nxc', 'keyword.control.directive.line.nxc']
        expect(tokens[3]).toEqual value: '151', scopes: ['source.nxc', 'meta.preprocessor.nxc', 'constant.numeric.nxc']
        expect(tokens[5]).toEqual value: '"', scopes: ['source.nxc', 'meta.preprocessor.nxc', 'string.quoted.double.nxc', 'punctuation.definition.string.begin.nxc']
        expect(tokens[6]).toEqual value: 'copy.nxc', scopes: ['source.nxc', 'meta.preprocessor.nxc', 'string.quoted.double.nxc']
        expect(tokens[7]).toEqual value: '"', scopes: ['source.nxc', 'meta.preprocessor.nxc', 'string.quoted.double.nxc', 'punctuation.definition.string.end.nxc']

      it "tokenizes '#undef'", ->
        {tokens} = grammar.tokenizeLine '#undef FOO'
        expect(tokens[0]).toEqual value: '#', scopes: ['source.nxc', 'meta.preprocessor.nxc', 'keyword.control.directive.undef.nxc', 'punctuation.definition.directive.nxc']
        expect(tokens[1]).toEqual value: 'undef', scopes: ['source.nxc', 'meta.preprocessor.nxc', 'keyword.control.directive.undef.nxc']
        expect(tokens[2]).toEqual value: ' FOO', scopes: ['source.nxc', 'meta.preprocessor.nxc']

      it "tokenizes '#pragma'", ->
        {tokens} = grammar.tokenizeLine '#pragma once'
        expect(tokens[0]).toEqual value: '#', scopes: ['source.nxc', 'meta.preprocessor.nxc', 'keyword.control.directive.pragma.nxc', 'punctuation.definition.directive.nxc']
        expect(tokens[1]).toEqual value: 'pragma', scopes: ['source.nxc', 'meta.preprocessor.nxc', 'keyword.control.directive.pragma.nxc']
        expect(tokens[2]).toEqual value: ' once', scopes: ['source.nxc', 'meta.preprocessor.nxc']

        {tokens} = grammar.tokenizeLine '#pragma clang diagnostic push'
        expect(tokens[0]).toEqual value: '#', scopes: ['source.nxc', 'meta.preprocessor.nxc', 'keyword.control.directive.pragma.nxc', 'punctuation.definition.directive.nxc']
        expect(tokens[1]).toEqual value: 'pragma', scopes: ['source.nxc', 'meta.preprocessor.nxc', 'keyword.control.directive.pragma.nxc']
        expect(tokens[2]).toEqual value: ' clang diagnostic push', scopes: ['source.nxc', 'meta.preprocessor.nxc']

        {tokens} = grammar.tokenizeLine '#pragma mark – Initialization'
        expect(tokens[0]).toEqual value: '#', scopes: ['source.nxc', 'meta.section', 'meta.preprocessor.nxc', 'keyword.control.directive.pragma.pragma-mark.nxc',  'punctuation.definition.directive.nxc']
        expect(tokens[1]).toEqual value: 'pragma mark', scopes: ['source.nxc', 'meta.section',  'meta.preprocessor.nxc', 'keyword.control.directive.pragma.pragma-mark.nxc']
        expect(tokens[3]).toEqual value: '– Initialization', scopes: ['source.nxc', 'meta.section',  'meta.preprocessor.nxc', 'meta.toc-list.pragma-mark.nxc']

      describe "define", ->
        it "tokenizes '#define [identifier name]'", ->
          {tokens} = grammar.tokenizeLine '#define _FILE_NAME_H_'
          expect(tokens[0]).toEqual value: '#', scopes: ['source.nxc', 'meta.preprocessor.macro.nxc', 'keyword.control.directive.define.nxc', 'punctuation.definition.directive.nxc']
          expect(tokens[1]).toEqual value: 'define', scopes: ['source.nxc', 'meta.preprocessor.macro.nxc', 'keyword.control.directive.define.nxc']
          expect(tokens[3]).toEqual value: '_FILE_NAME_H_', scopes: ['source.nxc', 'meta.preprocessor.macro.nxc', 'entity.name.function.preprocessor.nxc']

        it "tokenizes '#define [identifier name] [value]'", ->
          {tokens} = grammar.tokenizeLine '#define WIDTH 80'
          expect(tokens[0]).toEqual value: '#', scopes: ['source.nxc', 'meta.preprocessor.macro.nxc', 'keyword.control.directive.define.nxc', 'punctuation.definition.directive.nxc']
          expect(tokens[1]).toEqual value: 'define', scopes: ['source.nxc', 'meta.preprocessor.macro.nxc', 'keyword.control.directive.define.nxc']
          expect(tokens[3]).toEqual value: 'WIDTH', scopes: ['source.nxc', 'meta.preprocessor.macro.nxc', 'entity.name.function.preprocessor.nxc']
          expect(tokens[5]).toEqual value: '80', scopes: ['source.nxc', 'meta.preprocessor.macro.nxc', 'constant.numeric.nxc']

          {tokens} = grammar.tokenizeLine '#define ABC XYZ(1)'
          expect(tokens[0]).toEqual value: '#', scopes: ['source.nxc', 'meta.preprocessor.macro.nxc', 'keyword.control.directive.define.nxc', 'punctuation.definition.directive.nxc']
          expect(tokens[1]).toEqual value: 'define', scopes: ['source.nxc', 'meta.preprocessor.macro.nxc', 'keyword.control.directive.define.nxc']
          expect(tokens[3]).toEqual value: 'ABC', scopes: ['source.nxc', 'meta.preprocessor.macro.nxc', 'entity.name.function.preprocessor.nxc']
          expect(tokens[4]).toEqual value: ' ', scopes: ['source.nxc', 'meta.preprocessor.macro.nxc', 'meta.function.nxc', 'punctuation.whitespace.function.leading.nxc']
          expect(tokens[5]).toEqual value: 'XYZ', scopes: ['source.nxc', 'meta.preprocessor.macro.nxc', 'meta.function.nxc', 'entity.name.function.nxc']
          expect(tokens[6]).toEqual value: '(', scopes: ['source.nxc', 'meta.preprocessor.macro.nxc', 'meta.function.nxc', 'meta.parens.nxc', 'punctuation.section.parens.begin.nxc']
          expect(tokens[7]).toEqual value: '1', scopes: ['source.nxc', 'meta.preprocessor.macro.nxc', 'meta.function.nxc', 'meta.parens.nxc', 'constant.numeric.nxc']
          expect(tokens[8]).toEqual value: ')', scopes: ['source.nxc', 'meta.preprocessor.macro.nxc', 'meta.function.nxc', 'meta.parens.nxc', 'punctuation.section.parens.end.nxc']

          {tokens} = grammar.tokenizeLine '#define PI_PLUS_ONE (3.14 + 1)'
          expect(tokens[0]).toEqual value: '#', scopes: ['source.nxc', 'meta.preprocessor.macro.nxc', 'keyword.control.directive.define.nxc', 'punctuation.definition.directive.nxc']
          expect(tokens[1]).toEqual value: 'define', scopes: ['source.nxc', 'meta.preprocessor.macro.nxc', 'keyword.control.directive.define.nxc']
          expect(tokens[3]).toEqual value: 'PI_PLUS_ONE', scopes: ['source.nxc', 'meta.preprocessor.macro.nxc', 'entity.name.function.preprocessor.nxc']
          expect(tokens[4]).toEqual value: ' (', scopes: ['source.nxc', 'meta.preprocessor.macro.nxc']
          expect(tokens[5]).toEqual value: '3.14', scopes: ['source.nxc', 'meta.preprocessor.macro.nxc', 'constant.numeric.nxc']
          expect(tokens[6]).toEqual value: ' + ', scopes: ['source.nxc', 'meta.preprocessor.macro.nxc']
          expect(tokens[7]).toEqual value: '1', scopes: ['source.nxc', 'meta.preprocessor.macro.nxc', 'constant.numeric.nxc']
          expect(tokens[8]).toEqual value: ')', scopes: ['source.nxc', 'meta.preprocessor.macro.nxc']

        describe "macros", ->
          it "tokenizes them", ->
            {tokens} = grammar.tokenizeLine '#define INCREMENT(x) x++'
            expect(tokens[0]).toEqual value: '#', scopes: ['source.nxc', 'meta.preprocessor.macro.nxc', 'keyword.control.directive.define.nxc', 'punctuation.definition.directive.nxc']
            expect(tokens[1]).toEqual value: 'define', scopes: ['source.nxc', 'meta.preprocessor.macro.nxc', 'keyword.control.directive.define.nxc']
            expect(tokens[3]).toEqual value: 'INCREMENT', scopes: ['source.nxc', 'meta.preprocessor.macro.nxc', 'entity.name.function.preprocessor.nxc']
            expect(tokens[4]).toEqual value: '(', scopes: ['source.nxc', 'meta.preprocessor.macro.nxc', 'punctuation.definition.parameters.begin.nxc']
            expect(tokens[5]).toEqual value: 'x', scopes: ['source.nxc', 'meta.preprocessor.macro.nxc', 'variable.parameter.preprocessor.nxc']
            expect(tokens[6]).toEqual value: ')', scopes: ['source.nxc', 'meta.preprocessor.macro.nxc', 'punctuation.definition.parameters.end.nxc']
            expect(tokens[7]).toEqual value: ' x++', scopes: ['source.nxc', 'meta.preprocessor.macro.nxc']

            {tokens} = grammar.tokenizeLine '#define MULT(x, y) (x) * (y)'
            expect(tokens[0]).toEqual value: '#', scopes: ['source.nxc', 'meta.preprocessor.macro.nxc', 'keyword.control.directive.define.nxc', 'punctuation.definition.directive.nxc']
            expect(tokens[1]).toEqual value: 'define', scopes: ['source.nxc', 'meta.preprocessor.macro.nxc', 'keyword.control.directive.define.nxc']
            expect(tokens[3]).toEqual value: 'MULT', scopes: ['source.nxc', 'meta.preprocessor.macro.nxc', 'entity.name.function.preprocessor.nxc']
            expect(tokens[4]).toEqual value: '(', scopes: ['source.nxc', 'meta.preprocessor.macro.nxc', 'punctuation.definition.parameters.begin.nxc']
            expect(tokens[5]).toEqual value: 'x', scopes: ['source.nxc', 'meta.preprocessor.macro.nxc', 'variable.parameter.preprocessor.nxc']
            expect(tokens[6]).toEqual value: ',', scopes: ['source.nxc', 'meta.preprocessor.macro.nxc', 'variable.parameter.preprocessor.nxc', 'punctuation.separator.parameters.nxc']
            expect(tokens[7]).toEqual value: ' y', scopes: ['source.nxc', 'meta.preprocessor.macro.nxc', 'variable.parameter.preprocessor.nxc']
            expect(tokens[8]).toEqual value: ')', scopes: ['source.nxc', 'meta.preprocessor.macro.nxc', 'punctuation.definition.parameters.end.nxc']
            expect(tokens[9]).toEqual value: ' (x) * (y)', scopes: ['source.nxc', 'meta.preprocessor.macro.nxc']

            {tokens} = grammar.tokenizeLine '#define SWAP(a, b)  do { a ^= b; b ^= a; a ^= b; } while ( 0 )'
            expect(tokens[0]).toEqual value: '#', scopes: ['source.nxc', 'meta.preprocessor.macro.nxc', 'keyword.control.directive.define.nxc', 'punctuation.definition.directive.nxc']
            expect(tokens[1]).toEqual value: 'define', scopes: ['source.nxc', 'meta.preprocessor.macro.nxc', 'keyword.control.directive.define.nxc']
            expect(tokens[3]).toEqual value: 'SWAP', scopes: ['source.nxc', 'meta.preprocessor.macro.nxc', 'entity.name.function.preprocessor.nxc']
            expect(tokens[4]).toEqual value: '(', scopes: ['source.nxc', 'meta.preprocessor.macro.nxc', 'punctuation.definition.parameters.begin.nxc']
            expect(tokens[5]).toEqual value: 'a', scopes: ['source.nxc', 'meta.preprocessor.macro.nxc', 'variable.parameter.preprocessor.nxc']
            expect(tokens[6]).toEqual value: ',', scopes: ['source.nxc', 'meta.preprocessor.macro.nxc', 'variable.parameter.preprocessor.nxc', 'punctuation.separator.parameters.nxc']
            expect(tokens[7]).toEqual value: ' b', scopes: ['source.nxc', 'meta.preprocessor.macro.nxc', 'variable.parameter.preprocessor.nxc']
            expect(tokens[8]).toEqual value: ')', scopes: ['source.nxc', 'meta.preprocessor.macro.nxc', 'punctuation.definition.parameters.end.nxc']
            expect(tokens[10]).toEqual value: 'do', scopes: ['source.nxc', 'meta.preprocessor.macro.nxc', 'keyword.control.nxc']
            expect(tokens[12]).toEqual value: '{', scopes: ['source.nxc', 'meta.preprocessor.macro.nxc', 'meta.block.nxc', 'punctuation.section.block.begin.nxc']
            expect(tokens[13]).toEqual value: ' a ^= b; b ^= a; a ^= b; ', scopes: ['source.nxc', 'meta.preprocessor.macro.nxc', 'meta.block.nxc']
            expect(tokens[14]).toEqual value: '}', scopes: ['source.nxc', 'meta.preprocessor.macro.nxc', 'meta.block.nxc', 'punctuation.section.block.end.nxc']
            expect(tokens[16]).toEqual value: 'while', scopes: ['source.nxc', 'meta.preprocessor.macro.nxc', 'keyword.control.nxc']
            expect(tokens[17]).toEqual value: ' ( ', scopes: ['source.nxc', 'meta.preprocessor.macro.nxc']
            expect(tokens[18]).toEqual value: '0', scopes: ['source.nxc', 'meta.preprocessor.macro.nxc', 'constant.numeric.nxc']
            expect(tokens[19]).toEqual value: ' )', scopes: ['source.nxc', 'meta.preprocessor.macro.nxc']

          it "tokenizes multiline macros", ->
            lines = grammar.tokenizeLines '''
              #define max(a,b) (a>b)? \\
                                a:b
            '''
            expect(lines[0][10]).toEqual value: '\\', scopes: ['source.nxc', 'meta.preprocessor.macro.nxc', 'constant.character.escape.line-continuation.nxc']

            lines = grammar.tokenizeLines '''
              #define SWAP(a, b)  { \\
                a ^= b; \\
                b ^= a; \\
                a ^= b; \\
              }
            '''
            expect(lines[0][0]).toEqual value: '#', scopes: ['source.nxc', 'meta.preprocessor.macro.nxc', 'keyword.control.directive.define.nxc', 'punctuation.definition.directive.nxc']
            expect(lines[0][1]).toEqual value: 'define', scopes: ['source.nxc', 'meta.preprocessor.macro.nxc', 'keyword.control.directive.define.nxc']
            expect(lines[0][3]).toEqual value: 'SWAP', scopes: ['source.nxc', 'meta.preprocessor.macro.nxc', 'entity.name.function.preprocessor.nxc']
            expect(lines[0][4]).toEqual value: '(', scopes: ['source.nxc', 'meta.preprocessor.macro.nxc', 'punctuation.definition.parameters.begin.nxc']
            expect(lines[0][5]).toEqual value: 'a', scopes: ['source.nxc', 'meta.preprocessor.macro.nxc', 'variable.parameter.preprocessor.nxc']
            expect(lines[0][6]).toEqual value: ',', scopes: ['source.nxc', 'meta.preprocessor.macro.nxc', 'variable.parameter.preprocessor.nxc', 'punctuation.separator.parameters.nxc']
            expect(lines[0][7]).toEqual value: ' b', scopes: ['source.nxc', 'meta.preprocessor.macro.nxc', 'variable.parameter.preprocessor.nxc']
            expect(lines[0][8]).toEqual value: ')', scopes: ['source.nxc', 'meta.preprocessor.macro.nxc', 'punctuation.definition.parameters.end.nxc']
            expect(lines[0][10]).toEqual value: '{', scopes: ['source.nxc', 'meta.preprocessor.macro.nxc', 'meta.block.nxc', 'punctuation.section.block.begin.nxc']
            expect(lines[0][12]).toEqual value: '\\', scopes: ['source.nxc', 'meta.preprocessor.macro.nxc', 'meta.block.nxc', 'constant.character.escape.line-continuation.nxc']
            expect(lines[1][0]).toEqual value: '  a ^= b; ', scopes: ['source.nxc', 'meta.preprocessor.macro.nxc', 'meta.block.nxc']
            expect(lines[1][1]).toEqual value: '\\', scopes: ['source.nxc', 'meta.preprocessor.macro.nxc', 'meta.block.nxc', 'constant.character.escape.line-continuation.nxc']
            expect(lines[2][0]).toEqual value: '  b ^= a; ', scopes: ['source.nxc', 'meta.preprocessor.macro.nxc', 'meta.block.nxc']
            expect(lines[2][1]).toEqual value: '\\', scopes: ['source.nxc', 'meta.preprocessor.macro.nxc', 'meta.block.nxc', 'constant.character.escape.line-continuation.nxc']
            expect(lines[3][0]).toEqual value: '  a ^= b; ', scopes: ['source.nxc', 'meta.preprocessor.macro.nxc', 'meta.block.nxc']
            expect(lines[3][1]).toEqual value: '\\', scopes: ['source.nxc', 'meta.preprocessor.macro.nxc', 'meta.block.nxc', 'constant.character.escape.line-continuation.nxc']
            expect(lines[4][0]).toEqual value: '}', scopes: ['source.nxc', 'meta.preprocessor.macro.nxc', 'meta.block.nxc', 'punctuation.section.block.end.nxc']

      describe "includes", ->
        it "tokenizes '#include'", ->
          {tokens} = grammar.tokenizeLine '#include <stdio.h>'
          expect(tokens[0]).toEqual value: '#', scopes: ['source.nxc', 'meta.preprocessor.include.nxc', 'keyword.control.directive.include.nxc', 'punctuation.definition.directive.nxc']
          expect(tokens[1]).toEqual value: 'include', scopes: ['source.nxc', 'meta.preprocessor.include.nxc', 'keyword.control.directive.include.nxc']
          expect(tokens[3]).toEqual value: '<', scopes: ['source.nxc', 'meta.preprocessor.include.nxc', 'string.quoted.other.lt-gt.include.nxc', 'punctuation.definition.string.begin.nxc']
          expect(tokens[4]).toEqual value: 'stdio.h', scopes: ['source.nxc', 'meta.preprocessor.include.nxc', 'string.quoted.other.lt-gt.include.nxc']
          expect(tokens[5]).toEqual value: '>', scopes: ['source.nxc', 'meta.preprocessor.include.nxc', 'string.quoted.other.lt-gt.include.nxc', 'punctuation.definition.string.end.nxc']

          {tokens} = grammar.tokenizeLine '#include<stdio.h>'
          expect(tokens[0]).toEqual value: '#', scopes: ['source.nxc', 'meta.preprocessor.include.nxc', 'keyword.control.directive.include.nxc', 'punctuation.definition.directive.nxc']
          expect(tokens[1]).toEqual value: 'include', scopes: ['source.nxc', 'meta.preprocessor.include.nxc', 'keyword.control.directive.include.nxc']
          expect(tokens[2]).toEqual value: '<', scopes: ['source.nxc', 'meta.preprocessor.include.nxc', 'string.quoted.other.lt-gt.include.nxc', 'punctuation.definition.string.begin.nxc']
          expect(tokens[3]).toEqual value: 'stdio.h', scopes: ['source.nxc', 'meta.preprocessor.include.nxc', 'string.quoted.other.lt-gt.include.nxc']
          expect(tokens[4]).toEqual value: '>', scopes: ['source.nxc', 'meta.preprocessor.include.nxc', 'string.quoted.other.lt-gt.include.nxc', 'punctuation.definition.string.end.nxc']

          {tokens} = grammar.tokenizeLine '#include_<stdio.h>'
          expect(tokens[0]).toEqual value: '#include_<stdio.h>', scopes: ['source.nxc']

          {tokens} = grammar.tokenizeLine '#include "file"'
          expect(tokens[0]).toEqual value: '#', scopes: ['source.nxc', 'meta.preprocessor.include.nxc', 'keyword.control.directive.include.nxc', 'punctuation.definition.directive.nxc']
          expect(tokens[1]).toEqual value: 'include', scopes: ['source.nxc', 'meta.preprocessor.include.nxc', 'keyword.control.directive.include.nxc']
          expect(tokens[3]).toEqual value: '"', scopes: ['source.nxc', 'meta.preprocessor.include.nxc', 'string.quoted.double.include.nxc', 'punctuation.definition.string.begin.nxc']
          expect(tokens[4]).toEqual value: 'file', scopes: ['source.nxc', 'meta.preprocessor.include.nxc', 'string.quoted.double.include.nxc']
          expect(tokens[5]).toEqual value: '"', scopes: ['source.nxc', 'meta.preprocessor.include.nxc', 'string.quoted.double.include.nxc', 'punctuation.definition.string.end.nxc']

        it "tokenizes '#import'", ->
          {tokens} = grammar.tokenizeLine '#import "file"'
          expect(tokens[0]).toEqual value: '#', scopes: ['source.nxc', 'meta.preprocessor.include.nxc', 'keyword.control.directive.import.nxc', 'punctuation.definition.directive.nxc']
          expect(tokens[1]).toEqual value: 'import', scopes: ['source.nxc', 'meta.preprocessor.include.nxc', 'keyword.control.directive.import.nxc']
          expect(tokens[3]).toEqual value: '"', scopes: ['source.nxc', 'meta.preprocessor.include.nxc', 'string.quoted.double.include.nxc', 'punctuation.definition.string.begin.nxc']
          expect(tokens[4]).toEqual value: 'file', scopes: ['source.nxc', 'meta.preprocessor.include.nxc', 'string.quoted.double.include.nxc']
          expect(tokens[5]).toEqual value: '"', scopes: ['source.nxc', 'meta.preprocessor.include.nxc', 'string.quoted.double.include.nxc', 'punctuation.definition.string.end.nxc']

      describe "diagnostics", ->
        it "tokenizes '#error'", ->
          {tokens} = grammar.tokenizeLine '#error NXC compiler required.'
          expect(tokens[0]).toEqual value: '#', scopes: ['source.nxc', 'meta.preprocessor.diagnostic.nxc', 'keyword.control.directive.diagnostic.error.nxc', 'punctuation.definition.directive.nxc']
          expect(tokens[1]).toEqual value: 'error', scopes: ['source.nxc', 'meta.preprocessor.diagnostic.nxc', 'keyword.control.directive.diagnostic.error.nxc']
          expect(tokens[2]).toEqual value: ' NXC compiler required.', scopes: ['source.nxc', 'meta.preprocessor.diagnostic.nxc']

        it "tokenizes '#warning'", ->
          {tokens} = grammar.tokenizeLine '#warning This is a warning.'
          expect(tokens[0]).toEqual value: '#', scopes: ['source.nxc', 'meta.preprocessor.diagnostic.nxc', 'keyword.control.directive.diagnostic.warning.nxc', 'punctuation.definition.directive.nxc']
          expect(tokens[1]).toEqual value: 'warning', scopes: ['source.nxc', 'meta.preprocessor.diagnostic.nxc', 'keyword.control.directive.diagnostic.warning.nxc']
          expect(tokens[2]).toEqual value: ' This is a warning.', scopes: ['source.nxc', 'meta.preprocessor.diagnostic.nxc']

      describe "conditionals", ->
        it "tokenizes if-elif-else preprocessor blocks", ->
          lines = grammar.tokenizeLines '''
            #if defined(CREDIT)
                credit();
            #elif defined(DEBIT)
                debit();
            #else
                printerror();
            #endif
          '''
          expect(lines[0][0]).toEqual value: '#', scopes: ['source.nxc', 'meta.preprocessor.nxc', 'keyword.control.directive.conditional.nxc', 'punctuation.definition.directive.nxc']
          expect(lines[0][1]).toEqual value: 'if', scopes: ['source.nxc', 'meta.preprocessor.nxc', 'keyword.control.directive.conditional.nxc']
          expect(lines[0][2]).toEqual value: ' defined(CREDIT)', scopes: ['source.nxc', 'meta.preprocessor.nxc']
          expect(lines[1][1]).toEqual value: 'credit', scopes: ['source.nxc', 'meta.function.nxc', 'entity.name.function.nxc']
          expect(lines[1][2]).toEqual value: '(', scopes: ['source.nxc', 'meta.function.nxc', 'meta.parens.nxc', 'punctuation.section.parens.begin.nxc']
          expect(lines[1][3]).toEqual value: ')', scopes: ['source.nxc', 'meta.function.nxc', 'meta.parens.nxc', 'punctuation.section.parens.end.nxc']
          expect(lines[2][0]).toEqual value: '#', scopes: ['source.nxc', 'meta.preprocessor.nxc', 'keyword.control.directive.conditional.nxc', 'punctuation.definition.directive.nxc']
          expect(lines[2][1]).toEqual value: 'elif', scopes: ['source.nxc', 'meta.preprocessor.nxc', 'keyword.control.directive.conditional.nxc']
          expect(lines[2][2]).toEqual value: ' defined(DEBIT)', scopes: ['source.nxc', 'meta.preprocessor.nxc']
          expect(lines[3][1]).toEqual value: 'debit', scopes: ['source.nxc', 'meta.function.nxc', 'entity.name.function.nxc']
          expect(lines[3][2]).toEqual value: '(', scopes: ['source.nxc', 'meta.function.nxc', 'meta.parens.nxc', 'punctuation.section.parens.begin.nxc']
          expect(lines[3][3]).toEqual value: ')', scopes: ['source.nxc', 'meta.function.nxc', 'meta.parens.nxc', 'punctuation.section.parens.end.nxc']
          expect(lines[4][0]).toEqual value: '#', scopes: ['source.nxc', 'meta.preprocessor.nxc', 'keyword.control.directive.conditional.nxc', 'punctuation.definition.directive.nxc']
          expect(lines[4][1]).toEqual value: 'else', scopes: ['source.nxc', 'meta.preprocessor.nxc', 'keyword.control.directive.conditional.nxc']
          expect(lines[5][1]).toEqual value: 'printerror', scopes: ['source.nxc', 'meta.function.nxc', 'entity.name.function.nxc']
          expect(lines[5][2]).toEqual value: '(', scopes: ['source.nxc', 'meta.function.nxc', 'meta.parens.nxc', 'punctuation.section.parens.begin.nxc']
          expect(lines[5][3]).toEqual value: ')', scopes: ['source.nxc', 'meta.function.nxc', 'meta.parens.nxc', 'punctuation.section.parens.end.nxc']
          expect(lines[6][0]).toEqual value: '#', scopes: ['source.nxc', 'meta.preprocessor.nxc', 'keyword.control.directive.conditional.nxc', 'punctuation.definition.directive.nxc']
          expect(lines[6][1]).toEqual value: 'endif', scopes: ['source.nxc', 'meta.preprocessor.nxc', 'keyword.control.directive.conditional.nxc']

        it "tokenizes if-true-else blocks", ->
          lines = grammar.tokenizeLines '''
            #if 1
            int something() {
              #if 1
                return 1;
              #else
                return 0;
              #endif
            }
            #else
            int something() {
              return 0;
            }
            #endif
          '''
          expect(lines[0][0]).toEqual value: '#', scopes: ['source.nxc', 'meta.preprocessor.nxc', 'keyword.control.directive.conditional.nxc', 'punctuation.definition.directive.nxc']
          expect(lines[0][1]).toEqual value: 'if', scopes: ['source.nxc', 'meta.preprocessor.nxc', 'keyword.control.directive.conditional.nxc']
          expect(lines[0][3]).toEqual value: '1', scopes: ['source.nxc', 'meta.preprocessor.nxc', 'constant.numeric.preprocessor.nxc']
          expect(lines[1][0]).toEqual value: 'int', scopes: ['source.nxc', 'storage.type.nxc']
          expect(lines[1][2]).toEqual value: 'something', scopes: ['source.nxc', 'meta.function.nxc', 'entity.name.function.nxc']
          expect(lines[2][1]).toEqual value: '#', scopes: ['source.nxc', 'meta.function.nxc', 'meta.block.nxc', 'meta.preprocessor.nxc', 'keyword.control.directive.conditional.nxc', 'punctuation.definition.directive.nxc']
          expect(lines[2][2]).toEqual value: 'if', scopes: ['source.nxc', 'meta.function.nxc', 'meta.block.nxc', 'meta.preprocessor.nxc', 'keyword.control.directive.conditional.nxc']
          expect(lines[2][4]).toEqual value: '1', scopes: ['source.nxc', 'meta.function.nxc', 'meta.block.nxc', 'meta.preprocessor.nxc', 'constant.numeric.preprocessor.nxc']
          expect(lines[3][1]).toEqual value: 'return', scopes: ['source.nxc', 'meta.function.nxc', 'meta.block.nxc', 'keyword.control.nxc']
          expect(lines[3][3]).toEqual value: '1', scopes: ['source.nxc', 'meta.function.nxc', 'meta.block.nxc', 'constant.numeric.nxc']
          expect(lines[4][1]).toEqual value: '#', scopes: ['source.nxc', 'meta.function.nxc', 'meta.block.nxc', 'meta.preprocessor.nxc', 'keyword.control.directive.conditional.nxc', 'punctuation.definition.directive.nxc']
          expect(lines[4][2]).toEqual value: 'else', scopes: ['source.nxc', 'meta.function.nxc', 'meta.block.nxc', 'meta.preprocessor.nxc', 'keyword.control.directive.conditional.nxc']
          expect(lines[5][0]).toEqual value: '    return 0;', scopes: ['source.nxc', 'meta.function.nxc', 'meta.block.nxc', 'comment.block.preprocessor.else-branch.in-block']
          expect(lines[6][1]).toEqual value: '#', scopes: ['source.nxc', 'meta.function.nxc', 'meta.block.nxc', 'meta.preprocessor.nxc', 'keyword.control.directive.conditional.nxc', 'punctuation.definition.directive.nxc']
          expect(lines[6][2]).toEqual value: 'endif', scopes: ['source.nxc', 'meta.function.nxc', 'meta.block.nxc', 'meta.preprocessor.nxc', 'keyword.control.directive.conditional.nxc']
          expect(lines[8][0]).toEqual value: '#', scopes: ['source.nxc', 'meta.preprocessor.nxc', 'keyword.control.directive.conditional.nxc', 'punctuation.definition.directive.nxc']
          expect(lines[8][1]).toEqual value: 'else', scopes: ['source.nxc', 'meta.preprocessor.nxc', 'keyword.control.directive.conditional.nxc']
          expect(lines[9][0]).toEqual value: 'int something() {', scopes: ['source.nxc', 'comment.block.preprocessor.else-branch']
          expect(lines[12][0]).toEqual value: '#', scopes: ['source.nxc', 'meta.preprocessor.nxc', 'keyword.control.directive.conditional.nxc', 'punctuation.definition.directive.nxc']
          expect(lines[12][1]).toEqual value: 'endif', scopes: ['source.nxc', 'meta.preprocessor.nxc', 'keyword.control.directive.conditional.nxc']

        it "tokenizes if-false-else blocks", ->
          lines = grammar.tokenizeLines '''
            int something() {
              #if 0
                return 1;
              #else
                return 0;
              #endif
            }
          '''
          expect(lines[0][0]).toEqual value: 'int', scopes: ['source.nxc', 'storage.type.nxc']
          expect(lines[0][2]).toEqual value: 'something', scopes: ['source.nxc', 'meta.function.nxc', 'entity.name.function.nxc']
          expect(lines[1][1]).toEqual value: '#', scopes: ['source.nxc', 'meta.function.nxc', 'meta.block.nxc', 'meta.preprocessor.nxc', 'keyword.control.directive.conditional.nxc', 'punctuation.definition.directive.nxc']
          expect(lines[1][2]).toEqual value: 'if', scopes: ['source.nxc', 'meta.function.nxc', 'meta.block.nxc', 'meta.preprocessor.nxc', 'keyword.control.directive.conditional.nxc']
          expect(lines[1][4]).toEqual value: '0', scopes: ['source.nxc', 'meta.function.nxc', 'meta.block.nxc', 'meta.preprocessor.nxc', 'constant.numeric.preprocessor.nxc']
          expect(lines[2][0]).toEqual value: '    return 1;', scopes: ['source.nxc', 'meta.function.nxc', 'meta.block.nxc', 'comment.block.preprocessor.if-branch.in-block']
          expect(lines[3][1]).toEqual value: '#', scopes: ['source.nxc', 'meta.function.nxc', 'meta.block.nxc', 'meta.preprocessor.nxc', 'keyword.control.directive.conditional.nxc', 'punctuation.definition.directive.nxc']
          expect(lines[3][2]).toEqual value: 'else', scopes: ['source.nxc', 'meta.function.nxc', 'meta.block.nxc', 'meta.preprocessor.nxc', 'keyword.control.directive.conditional.nxc']
          expect(lines[4][1]).toEqual value: 'return', scopes: ['source.nxc', 'meta.function.nxc', 'meta.block.nxc', 'keyword.control.nxc']
          expect(lines[4][3]).toEqual value: '0', scopes: ['source.nxc', 'meta.function.nxc', 'meta.block.nxc', 'constant.numeric.nxc']
          expect(lines[5][1]).toEqual value: '#', scopes: ['source.nxc', 'meta.function.nxc', 'meta.block.nxc', 'meta.preprocessor.nxc', 'keyword.control.directive.conditional.nxc', 'punctuation.definition.directive.nxc']
          expect(lines[5][2]).toEqual value: 'endif', scopes: ['source.nxc', 'meta.function.nxc', 'meta.block.nxc', 'meta.preprocessor.nxc', 'keyword.control.directive.conditional.nxc']

          lines = grammar.tokenizeLines '''
            #if 0
              something();
            #endif
          '''
          expect(lines[0][0]).toEqual value: '#', scopes: ['source.nxc', 'meta.preprocessor.nxc', 'keyword.control.directive.conditional.nxc', 'punctuation.definition.directive.nxc']
          expect(lines[0][1]).toEqual value: 'if', scopes: ['source.nxc', 'meta.preprocessor.nxc', 'keyword.control.directive.conditional.nxc']
          expect(lines[0][3]).toEqual value: '0', scopes: ['source.nxc', 'meta.preprocessor.nxc', 'constant.numeric.preprocessor.nxc']
          expect(lines[1][0]).toEqual value: '  something();', scopes: ['source.nxc', 'comment.block.preprocessor.if-branch']
          expect(lines[2][0]).toEqual value: '#', scopes: ['source.nxc', 'meta.preprocessor.nxc', 'keyword.control.directive.conditional.nxc', 'punctuation.definition.directive.nxc']
          expect(lines[2][1]).toEqual value: 'endif', scopes: ['source.nxc', 'meta.preprocessor.nxc', 'keyword.control.directive.conditional.nxc']

        it "tokenizes ifdef-elif blocks", ->
          lines = grammar.tokenizeLines '''
            #ifdef __unix__ /* is defined by compilers targeting Unix systems */
              # include <unistd.h>
            #elif defined _WIN32 /* is defined by compilers targeting Windows systems */
              # include <windows.h>
            #endif
          '''
          expect(lines[0][0]).toEqual value: '#', scopes: ['source.nxc', 'meta.preprocessor.nxc', 'keyword.control.directive.conditional.nxc', 'punctuation.definition.directive.nxc']
          expect(lines[0][1]).toEqual value: 'ifdef', scopes: ['source.nxc', 'meta.preprocessor.nxc', 'keyword.control.directive.conditional.nxc']
          expect(lines[0][2]).toEqual value: ' __unix__ ', scopes: ['source.nxc', 'meta.preprocessor.nxc']
          expect(lines[0][3]).toEqual value: '/*', scopes: ['source.nxc', 'comment.block.nxc', 'punctuation.definition.comment.begin.nxc']
          expect(lines[0][4]).toEqual value: ' is defined by compilers targeting Unix systems ', scopes: ['source.nxc', 'comment.block.nxc']
          expect(lines[0][5]).toEqual value: '*/', scopes: ['source.nxc', 'comment.block.nxc', 'punctuation.definition.comment.end.nxc']
          expect(lines[1][1]).toEqual value: '#', scopes: ['source.nxc', 'meta.preprocessor.include.nxc', 'keyword.control.directive.include.nxc', 'punctuation.definition.directive.nxc']
          expect(lines[1][2]).toEqual value: ' include', scopes: ['source.nxc', 'meta.preprocessor.include.nxc', 'keyword.control.directive.include.nxc']
          expect(lines[1][4]).toEqual value: '<', scopes: ['source.nxc', 'meta.preprocessor.include.nxc', 'string.quoted.other.lt-gt.include.nxc', 'punctuation.definition.string.begin.nxc']
          expect(lines[1][5]).toEqual value: 'unistd.h', scopes: ['source.nxc', 'meta.preprocessor.include.nxc', 'string.quoted.other.lt-gt.include.nxc']
          expect(lines[1][6]).toEqual value: '>', scopes: ['source.nxc', 'meta.preprocessor.include.nxc', 'string.quoted.other.lt-gt.include.nxc', 'punctuation.definition.string.end.nxc']
          expect(lines[2][0]).toEqual value: '#', scopes: ['source.nxc', 'meta.preprocessor.nxc', 'keyword.control.directive.conditional.nxc', 'punctuation.definition.directive.nxc']
          expect(lines[2][1]).toEqual value: 'elif', scopes: ['source.nxc', 'meta.preprocessor.nxc', 'keyword.control.directive.conditional.nxc']
          expect(lines[2][2]).toEqual value: ' defined _WIN32 ', scopes: ['source.nxc', 'meta.preprocessor.nxc']
          expect(lines[2][3]).toEqual value: '/*', scopes: ['source.nxc', 'comment.block.nxc', 'punctuation.definition.comment.begin.nxc']
          expect(lines[2][4]).toEqual value: ' is defined by compilers targeting Windows systems ', scopes: ['source.nxc', 'comment.block.nxc']
          expect(lines[2][5]).toEqual value: '*/', scopes: ['source.nxc', 'comment.block.nxc', 'punctuation.definition.comment.end.nxc']
          expect(lines[3][1]).toEqual value: '#', scopes: ['source.nxc', 'meta.preprocessor.include.nxc', 'keyword.control.directive.include.nxc', 'punctuation.definition.directive.nxc']
          expect(lines[3][2]).toEqual value: ' include', scopes: ['source.nxc', 'meta.preprocessor.include.nxc', 'keyword.control.directive.include.nxc']
          expect(lines[3][4]).toEqual value: '<', scopes: ['source.nxc', 'meta.preprocessor.include.nxc', 'string.quoted.other.lt-gt.include.nxc', 'punctuation.definition.string.begin.nxc']
          expect(lines[3][5]).toEqual value: 'windows.h', scopes: ['source.nxc', 'meta.preprocessor.include.nxc', 'string.quoted.other.lt-gt.include.nxc']
          expect(lines[3][6]).toEqual value: '>', scopes: ['source.nxc', 'meta.preprocessor.include.nxc', 'string.quoted.other.lt-gt.include.nxc', 'punctuation.definition.string.end.nxc']
          expect(lines[4][0]).toEqual value: '#', scopes: ['source.nxc', 'meta.preprocessor.nxc', 'keyword.control.directive.conditional.nxc', 'punctuation.definition.directive.nxc']
          expect(lines[4][1]).toEqual value: 'endif', scopes: ['source.nxc', 'meta.preprocessor.nxc', 'keyword.control.directive.conditional.nxc']

        it "tokenizes ifndef blocks", ->
          lines = grammar.tokenizeLines '''
            #ifndef _INCL_GUARD
              #define _INCL_GUARD
            #endif
          '''
          expect(lines[0][0]).toEqual value: '#', scopes: ['source.nxc', 'meta.preprocessor.nxc', 'keyword.control.directive.conditional.nxc', 'punctuation.definition.directive.nxc']
          expect(lines[0][1]).toEqual value: 'ifndef', scopes: ['source.nxc', 'meta.preprocessor.nxc', 'keyword.control.directive.conditional.nxc']
          expect(lines[0][2]).toEqual value: ' _INCL_GUARD', scopes: ['source.nxc', 'meta.preprocessor.nxc']
          expect(lines[1][1]).toEqual value: '#', scopes: ['source.nxc', 'meta.preprocessor.macro.nxc', 'keyword.control.directive.define.nxc', 'punctuation.definition.directive.nxc']
          expect(lines[1][2]).toEqual value: 'define', scopes: ['source.nxc', 'meta.preprocessor.macro.nxc', 'keyword.control.directive.define.nxc']
          expect(lines[1][4]).toEqual value: '_INCL_GUARD', scopes: ['source.nxc', 'meta.preprocessor.macro.nxc', 'entity.name.function.preprocessor.nxc']
          expect(lines[2][0]).toEqual value: '#', scopes: ['source.nxc', 'meta.preprocessor.nxc', 'keyword.control.directive.conditional.nxc', 'punctuation.definition.directive.nxc']
          expect(lines[2][1]).toEqual value: 'endif', scopes: ['source.nxc', 'meta.preprocessor.nxc', 'keyword.control.directive.conditional.nxc']

    describe "indentation", ->
      editor = null

      beforeEach ->
        editor = buildTextEditor()
        editor.setGrammar(grammar)

      expectPreservedIndentation = (text) ->
        editor.setText(text)
        editor.autoIndentBufferRows(0, editor.getLineCount() - 1)

        expectedLines = text.split('\n')
        actualLines = editor.getText().split('\n')
        for actualLine, i in actualLines
          expect([
            actualLine,
            editor.indentLevelForLine(actualLine)
          ]).toEqual([
            expectedLines[i],
            editor.indentLevelForLine(expectedLines[i])
          ])

      it "indents allman-style curly braces", ->
        expectPreservedIndentation '''
          if (a)
          {
            for (;;)
            {
              do
              {
                while (b)
                {
                  c();
                }
              }
              while (d)
            }
          }
        '''

      it "indents non-allman-style curly braces", ->
        expectPreservedIndentation '''
          if (a) {
            for (;;) {
              do {
                while (b) {
                  c();
                }
              } while (d)
            }
          }
        '''

      it "indents function arguments", ->
        expectPreservedIndentation '''
          a(
            b,
            c(
              d
            )
          );
        '''

      it "indents array and struct literals", ->
        expectPreservedIndentation '''
          some_t a[3] = {
            { .b = c },
            { .b = c, .d = {1, 2} },
          };
        '''

  describe "NXC", ->
    beforeEach ->
      grammar = atom.grammars.grammarForScopeName('source.nxc')

    it "parses the grammar", ->
      expect(grammar).toBeTruthy()
      expect(grammar.scopeName).toBe 'source.nxc'

    it "tokenizes this with `.this` class", ->
      {tokens} = grammar.tokenizeLine 'this.x'
      expect(tokens[0]).toEqual value: 'this', scopes: ['source.nxc', 'variable.language.this.nxc']

    it "tokenizes classes", ->
      lines = grammar.tokenizeLines '''
        class Thing {
          int x;
        }
      '''
      expect(lines[0][0]).toEqual value: 'class', scopes: ['source.nxc', 'meta.class-struct-block.nxc', 'storage.type.nxc']
      expect(lines[0][2]).toEqual value: 'Thing', scopes: ['source.nxc', 'meta.class-struct-block.nxc', 'entity.name.type.nxc']

    it "tokenizes 'extern NXC'", ->
      lines = grammar.tokenizeLines '''
        extern "NXC" {
        #include "legacy_NXC_header.h"
        }
      '''
      expect(lines[0][0]).toEqual value: 'extern', scopes: ['source.nxc', 'meta.extern-block.nxc', 'storage.modifier.nxc']
      expect(lines[0][2]).toEqual value: '"', scopes: ['source.nxc', 'meta.extern-block.nxc', 'string.quoted.double.nxc', 'punctuation.definition.string.begin.nxc']
      expect(lines[0][3]).toEqual value: 'C', scopes: ['source.nxc', 'meta.extern-block.nxc', 'string.quoted.double.nxc']
      expect(lines[0][4]).toEqual value: '"', scopes: ['source.nxc', 'meta.extern-block.nxc', 'string.quoted.double.nxc', 'punctuation.definition.string.end.nxc']
      expect(lines[0][6]).toEqual value: '{', scopes: ['source.nxc', 'meta.extern-block.nxc', 'punctuation.section.block.begin.nxc']
      expect(lines[1][0]).toEqual value: '#', scopes: ['source.nxc', 'meta.extern-block.nxc', 'meta.preprocessor.include.nxc', 'keyword.control.directive.include.nxc', 'punctuation.definition.directive.nxc']
      expect(lines[1][1]).toEqual value: 'include', scopes: ['source.nxc', 'meta.extern-block.nxc', 'meta.preprocessor.include.nxc', 'keyword.control.directive.include.nxc']
      expect(lines[1][3]).toEqual value: '"', scopes: ['source.nxc', 'meta.extern-block.nxc', 'meta.preprocessor.include.nxc', 'string.quoted.double.include.nxc', 'punctuation.definition.string.begin.nxc']
      expect(lines[1][4]).toEqual value: 'legacy_C_header.h', scopes: ['source.nxc', 'meta.extern-block.nxc', 'meta.preprocessor.include.nxc', 'string.quoted.double.include.nxc']
      expect(lines[1][5]).toEqual value: '"', scopes: ['source.nxc', 'meta.extern-block.nxc', 'meta.preprocessor.include.nxc', 'string.quoted.double.include.nxc', 'punctuation.definition.string.end.nxc']
      expect(lines[2][0]).toEqual value: '}', scopes: ['source.nxc', 'meta.extern-block.nxc', 'punctuation.section.block.end.nxc']

      lines = grammar.tokenizeLines '''
        #ifdef __cplusplus
        extern "NXC" {
        #endif
          // legacy NXC code here
        #ifdef __cplusplus
        }
        #endif
      '''
      expect(lines[0][0]).toEqual value: '#', scopes: ['source.nxc', 'meta.preprocessor.nxc', 'keyword.control.directive.conditional.nxc', 'punctuation.definition.directive.nxc']
      expect(lines[0][1]).toEqual value: 'ifdef', scopes: ['source.nxc', 'meta.preprocessor.nxc', 'keyword.control.directive.conditional.nxc']
      expect(lines[0][2]).toEqual value: ' __cplusplus', scopes: ['source.nxc', 'meta.preprocessor.nxc']
      expect(lines[1][0]).toEqual value: 'extern', scopes: ['source.nxc', 'meta.extern-block.nxc', 'storage.modifier.nxc']
      expect(lines[1][2]).toEqual value: '"', scopes: ['source.nxc', 'meta.extern-block.nxc', 'string.quoted.double.nxc', 'punctuation.definition.string.begin.nxc']
      expect(lines[1][3]).toEqual value: 'C', scopes: ['source.nxc', 'meta.extern-block.nxc', 'string.quoted.double.nxc']
      expect(lines[1][4]).toEqual value: '"', scopes: ['source.nxc', 'meta.extern-block.nxc', 'string.quoted.double.nxc', 'punctuation.definition.string.end.nxc']
      expect(lines[1][6]).toEqual value: '{', scopes: ['source.nxc', 'meta.extern-block.nxc', 'punctuation.section.block.begin.nxc']
      expect(lines[2][0]).toEqual value: '#', scopes: ['source.nxc', 'meta.preprocessor.nxc', 'keyword.control.directive.conditional.nxc', 'punctuation.definition.directive.nxc']
      expect(lines[2][1]).toEqual value: 'endif', scopes: ['source.nxc', 'meta.preprocessor.nxc', 'keyword.control.directive.conditional.nxc']
      expect(lines[3][1]).toEqual value: '//', scopes: ['source.nxc', 'comment.line.double-slash.nxc', 'punctuation.definition.comment.nxc']
      expect(lines[3][2]).toEqual value: ' legacy NXC code here', scopes: ['source.nxc', 'comment.line.double-slash.nxc']
      expect(lines[4][0]).toEqual value: '#', scopes: ['source.nxc', 'meta.preprocessor.nxc', 'keyword.control.directive.conditional.nxc', 'punctuation.definition.directive.nxc']
      expect(lines[4][1]).toEqual value: 'ifdef', scopes: ['source.nxc', 'meta.preprocessor.nxc', 'keyword.control.directive.conditional.nxc']
      expect(lines[5][0]).toEqual value: '}', scopes: ['source.nxc']
      expect(lines[6][0]).toEqual value: '#', scopes: ['source.nxc', 'meta.preprocessor.nxc', 'keyword.control.directive.conditional.nxc', 'punctuation.definition.directive.nxc']
      expect(lines[6][1]).toEqual value: 'endif', scopes: ['source.nxc', 'meta.preprocessor.nxc', 'keyword.control.directive.conditional.nxc']

    describe "comments", ->
      it "tokenizes them", ->
        {tokens} = grammar.tokenizeLine '// comment'
        expect(tokens[0]).toEqual value: '//', scopes: ['source.nxc', 'comment.line.double-slash.nxc', 'punctuation.definition.comment.nxc']
        expect(tokens[1]).toEqual value: ' comment', scopes: ['source.nxc', 'comment.line.double-slash.nxc']

        lines = grammar.tokenizeLines '''
          // separated\\
          comment
        '''
        expect(lines[0][0]).toEqual value: '//', scopes: ['source.nxc', 'comment.line.double-slash.nxc', 'punctuation.definition.comment.nxc']
        expect(lines[0][1]).toEqual value: ' separated', scopes: ['source.nxc', 'comment.line.double-slash.nxc']
        expect(lines[0][2]).toEqual value: '\\', scopes: ['source.nxc', 'comment.line.double-slash.nxc', 'constant.character.escape.line-continuation.nxc']
        expect(lines[1][0]).toEqual value: 'comment', scopes: ['source.nxc', 'comment.line.double-slash.nxc']
