TextEditor = null
buildTextEditor = (params) ->
  if atom.workspace.buildTextEditor?
    atom.workspace.buildTextEditor(params)
  else
    TextEditor ?= require('atom').TextEditor
    new TextEditor(params)

describe "Language-C", ->
  grammar = null

  beforeEach ->
    waitsForPromise ->
      atom.packages.activatePackage('language-c')

  describe "C", ->
    beforeEach ->
      grammar = atom.grammars.grammarForScopeName('source.c')

    it "parses the grammar", ->
      expect(grammar).toBeTruthy()
      expect(grammar.scopeName).toBe 'source.c'

    it "tokenizes functions", ->
      lines = grammar.tokenizeLines '''
        int something(int param) {
          return 0;
        }
      '''
      expect(lines[0][0]).toEqual value: 'int', scopes: ['source.c', 'storage.type.c']
      expect(lines[0][2]).toEqual value: 'something', scopes: ['source.c', 'meta.function.c', 'entity.name.function.c']
      expect(lines[0][3]).toEqual value: '(', scopes: ['source.c', 'meta.function.c', 'meta.parens.c', 'punctuation.section.parens.begin.c']
      expect(lines[0][4]).toEqual value: 'int', scopes: ['source.c', 'meta.function.c', 'meta.parens.c', 'storage.type.c']
      expect(lines[0][6]).toEqual value: ')', scopes: ['source.c', 'meta.function.c', 'meta.parens.c', 'punctuation.section.parens.end.c']
      expect(lines[0][8]).toEqual value: '{', scopes: ['source.c', 'meta.function.c', 'meta.block.c', 'punctuation.section.block.begin.c']
      expect(lines[1][1]).toEqual value: 'return', scopes: ['source.c', 'meta.function.c', 'meta.block.c', 'keyword.control.c']
      expect(lines[1][3]).toEqual value: '0', scopes: ['source.c', 'meta.function.c', 'meta.block.c', 'constant.numeric.c']
      expect(lines[2][0]).toEqual value: '}', scopes: ['source.c', 'meta.function.c', 'meta.block.c', 'punctuation.section.block.end.c']

    it "tokenizes various _t types", ->
      {tokens} = grammar.tokenizeLine 'size_t var;'
      expect(tokens[0]).toEqual value: 'size_t', scopes: ['source.c', 'support.type.sys-types.c']

      {tokens} = grammar.tokenizeLine 'pthread_t var;'
      expect(tokens[0]).toEqual value: 'pthread_t', scopes: ['source.c', 'support.type.pthread.c']

      {tokens} = grammar.tokenizeLine 'int32_t var;'
      expect(tokens[0]).toEqual value: 'int32_t', scopes: ['source.c', 'support.type.stdint.c']

      {tokens} = grammar.tokenizeLine 'myType_t var;'
      expect(tokens[0]).toEqual value: 'myType_t', scopes: ['source.c', 'support.type.posix-reserved.c']

    it "tokenizes 'line continuation' character", ->
      {tokens} = grammar.tokenizeLine 'ma' + '\\' + '\n' + 'in(){};'
      expect(tokens[0]).toEqual value: 'ma', scopes: ['source.c']
      expect(tokens[1]).toEqual value: '\\', scopes: ['source.c', 'constant.character.escape.line-continuation.c']
      expect(tokens[3]).toEqual value: 'in', scopes: ['source.c', 'meta.function.c', 'entity.name.function.c']

    describe "strings", ->
      it "tokenizes them", ->
        delimsByScope =
          'string.quoted.double.c': '"'
          'string.quoted.single.c': '\''

        for scope, delim of delimsByScope
          {tokens} = grammar.tokenizeLine delim + 'a' + delim
          expect(tokens[0]).toEqual value: delim, scopes: ['source.c', scope, 'punctuation.definition.string.begin.c']
          expect(tokens[1]).toEqual value: 'a', scopes: ['source.c', scope]
          expect(tokens[2]).toEqual value: delim, scopes: ['source.c', scope, 'punctuation.definition.string.end.c']

          {tokens} = grammar.tokenizeLine delim + 'a' + '\\' + '\n' + 'b' + delim
          expect(tokens[0]).toEqual value: delim, scopes: ['source.c', scope, 'punctuation.definition.string.begin.c']
          expect(tokens[1]).toEqual value: 'a', scopes: ['source.c', scope]
          expect(tokens[2]).toEqual value: '\\', scopes: ['source.c', scope, 'constant.character.escape.line-continuation.c']
          expect(tokens[4]).toEqual value: 'b', scopes: ['source.c', scope]
          expect(tokens[5]).toEqual value: delim, scopes: ['source.c', scope, 'punctuation.definition.string.end.c']

    describe "comments", ->
      it "tokenizes them", ->
        {tokens} = grammar.tokenizeLine '/**/'
        expect(tokens[0]).toEqual value: '/*', scopes: ['source.c', 'comment.block.c', 'punctuation.definition.comment.begin.c']
        expect(tokens[1]).toEqual value: '*/', scopes: ['source.c', 'comment.block.c', 'punctuation.definition.comment.end.c']

        {tokens} = grammar.tokenizeLine '/* foo */'
        expect(tokens[0]).toEqual value: '/*', scopes: ['source.c', 'comment.block.c', 'punctuation.definition.comment.begin.c']
        expect(tokens[1]).toEqual value: ' foo ', scopes: ['source.c', 'comment.block.c']
        expect(tokens[2]).toEqual value: '*/', scopes: ['source.c', 'comment.block.c', 'punctuation.definition.comment.end.c']

        {tokens} = grammar.tokenizeLine '*/*'
        expect(tokens[0]).toEqual value: '*/*', scopes: ['source.c', 'invalid.illegal.stray-comment-end.c']

    describe "preprocessor directives", ->
      it "tokenizes '#line'", ->
        {tokens} = grammar.tokenizeLine '#line 151 "copy.c"'
        expect(tokens[0]).toEqual value: '#', scopes: ['source.c', 'meta.preprocessor.c', 'keyword.control.directive.line.c', 'punctuation.definition.directive.c']
        expect(tokens[1]).toEqual value: 'line', scopes: ['source.c', 'meta.preprocessor.c', 'keyword.control.directive.line.c']
        expect(tokens[3]).toEqual value: '151', scopes: ['source.c', 'meta.preprocessor.c', 'constant.numeric.c']
        expect(tokens[5]).toEqual value: '"', scopes: ['source.c', 'meta.preprocessor.c', 'string.quoted.double.c', 'punctuation.definition.string.begin.c']
        expect(tokens[6]).toEqual value: 'copy.c', scopes: ['source.c', 'meta.preprocessor.c', 'string.quoted.double.c']
        expect(tokens[7]).toEqual value: '"', scopes: ['source.c', 'meta.preprocessor.c', 'string.quoted.double.c', 'punctuation.definition.string.end.c']

      it "tokenizes '#undef'", ->
        {tokens} = grammar.tokenizeLine '#undef FOO'
        expect(tokens[0]).toEqual value: '#', scopes: ['source.c', 'meta.preprocessor.c', 'keyword.control.directive.undef.c', 'punctuation.definition.directive.c']
        expect(tokens[1]).toEqual value: 'undef', scopes: ['source.c', 'meta.preprocessor.c', 'keyword.control.directive.undef.c']
        expect(tokens[2]).toEqual value: ' FOO', scopes: ['source.c', 'meta.preprocessor.c']

      it "tokenizes '#pragma'", ->
        {tokens} = grammar.tokenizeLine '#pragma once'
        expect(tokens[0]).toEqual value: '#', scopes: ['source.c', 'meta.preprocessor.c', 'keyword.control.directive.pragma.c', 'punctuation.definition.directive.c']
        expect(tokens[1]).toEqual value: 'pragma', scopes: ['source.c', 'meta.preprocessor.c', 'keyword.control.directive.pragma.c']
        expect(tokens[2]).toEqual value: ' once', scopes: ['source.c', 'meta.preprocessor.c']

        {tokens} = grammar.tokenizeLine '#pragma clang diagnostic push'
        expect(tokens[0]).toEqual value: '#', scopes: ['source.c', 'meta.preprocessor.c', 'keyword.control.directive.pragma.c', 'punctuation.definition.directive.c']
        expect(tokens[1]).toEqual value: 'pragma', scopes: ['source.c', 'meta.preprocessor.c', 'keyword.control.directive.pragma.c']
        expect(tokens[2]).toEqual value: ' clang diagnostic push', scopes: ['source.c', 'meta.preprocessor.c']

        {tokens} = grammar.tokenizeLine '#pragma mark – Initialization'
        expect(tokens[0]).toEqual value: '#', scopes: ['source.c', 'meta.section', 'meta.preprocessor.c', 'keyword.control.directive.pragma.pragma-mark.c',  'punctuation.definition.directive.c']
        expect(tokens[1]).toEqual value: 'pragma mark', scopes: ['source.c', 'meta.section',  'meta.preprocessor.c', 'keyword.control.directive.pragma.pragma-mark.c']
        expect(tokens[3]).toEqual value: '– Initialization', scopes: ['source.c', 'meta.section',  'meta.preprocessor.c', 'meta.toc-list.pragma-mark.c']

      describe "define", ->
        it "tokenizes '#define [identifier name]'", ->
          {tokens} = grammar.tokenizeLine '#define _FILE_NAME_H_'
          expect(tokens[0]).toEqual value: '#', scopes: ['source.c', 'meta.preprocessor.macro.c', 'keyword.control.directive.define.c', 'punctuation.definition.directive.c']
          expect(tokens[1]).toEqual value: 'define', scopes: ['source.c', 'meta.preprocessor.macro.c', 'keyword.control.directive.define.c']
          expect(tokens[3]).toEqual value: '_FILE_NAME_H_', scopes: ['source.c', 'meta.preprocessor.macro.c', 'entity.name.function.preprocessor.c']

        it "tokenizes '#define [identifier name] [value]'", ->
          {tokens} = grammar.tokenizeLine '#define WIDTH 80'
          expect(tokens[0]).toEqual value: '#', scopes: ['source.c', 'meta.preprocessor.macro.c', 'keyword.control.directive.define.c', 'punctuation.definition.directive.c']
          expect(tokens[1]).toEqual value: 'define', scopes: ['source.c', 'meta.preprocessor.macro.c', 'keyword.control.directive.define.c']
          expect(tokens[3]).toEqual value: 'WIDTH', scopes: ['source.c', 'meta.preprocessor.macro.c', 'entity.name.function.preprocessor.c']
          expect(tokens[5]).toEqual value: '80', scopes: ['source.c', 'meta.preprocessor.macro.c', 'constant.numeric.c']

          {tokens} = grammar.tokenizeLine '#define ABC XYZ(1)'
          expect(tokens[0]).toEqual value: '#', scopes: ['source.c', 'meta.preprocessor.macro.c', 'keyword.control.directive.define.c', 'punctuation.definition.directive.c']
          expect(tokens[1]).toEqual value: 'define', scopes: ['source.c', 'meta.preprocessor.macro.c', 'keyword.control.directive.define.c']
          expect(tokens[3]).toEqual value: 'ABC', scopes: ['source.c', 'meta.preprocessor.macro.c', 'entity.name.function.preprocessor.c']
          expect(tokens[4]).toEqual value: ' ', scopes: ['source.c', 'meta.preprocessor.macro.c', 'meta.function.c', 'punctuation.whitespace.function.leading.c']
          expect(tokens[5]).toEqual value: 'XYZ', scopes: ['source.c', 'meta.preprocessor.macro.c', 'meta.function.c', 'entity.name.function.c']
          expect(tokens[6]).toEqual value: '(', scopes: ['source.c', 'meta.preprocessor.macro.c', 'meta.function.c', 'meta.parens.c', 'punctuation.section.parens.begin.c']
          expect(tokens[7]).toEqual value: '1', scopes: ['source.c', 'meta.preprocessor.macro.c', 'meta.function.c', 'meta.parens.c', 'constant.numeric.c']
          expect(tokens[8]).toEqual value: ')', scopes: ['source.c', 'meta.preprocessor.macro.c', 'meta.function.c', 'meta.parens.c', 'punctuation.section.parens.end.c']

          {tokens} = grammar.tokenizeLine '#define PI_PLUS_ONE (3.14 + 1)'
          expect(tokens[0]).toEqual value: '#', scopes: ['source.c', 'meta.preprocessor.macro.c', 'keyword.control.directive.define.c', 'punctuation.definition.directive.c']
          expect(tokens[1]).toEqual value: 'define', scopes: ['source.c', 'meta.preprocessor.macro.c', 'keyword.control.directive.define.c']
          expect(tokens[3]).toEqual value: 'PI_PLUS_ONE', scopes: ['source.c', 'meta.preprocessor.macro.c', 'entity.name.function.preprocessor.c']
          expect(tokens[4]).toEqual value: ' (', scopes: ['source.c', 'meta.preprocessor.macro.c']
          expect(tokens[5]).toEqual value: '3.14', scopes: ['source.c', 'meta.preprocessor.macro.c', 'constant.numeric.c']
          expect(tokens[7]).toEqual value: '+', scopes: ['source.c', 'meta.preprocessor.macro.c', 'keyword.operator.c']
          expect(tokens[9]).toEqual value: '1', scopes: ['source.c', 'meta.preprocessor.macro.c', 'constant.numeric.c']
          expect(tokens[10]).toEqual value: ')', scopes: ['source.c', 'meta.preprocessor.macro.c']

        describe "macros", ->
          it "tokenizes them", ->
            {tokens} = grammar.tokenizeLine '#define INCREMENT(x) x++'
            expect(tokens[0]).toEqual value: '#', scopes: ['source.c', 'meta.preprocessor.macro.c', 'keyword.control.directive.define.c', 'punctuation.definition.directive.c']
            expect(tokens[1]).toEqual value: 'define', scopes: ['source.c', 'meta.preprocessor.macro.c', 'keyword.control.directive.define.c']
            expect(tokens[3]).toEqual value: 'INCREMENT', scopes: ['source.c', 'meta.preprocessor.macro.c', 'entity.name.function.preprocessor.c']
            expect(tokens[4]).toEqual value: '(', scopes: ['source.c', 'meta.preprocessor.macro.c', 'punctuation.definition.parameters.begin.c']
            expect(tokens[5]).toEqual value: 'x', scopes: ['source.c', 'meta.preprocessor.macro.c', 'variable.parameter.preprocessor.c']
            expect(tokens[6]).toEqual value: ')', scopes: ['source.c', 'meta.preprocessor.macro.c', 'punctuation.definition.parameters.end.c']
            expect(tokens[7]).toEqual value: ' x', scopes: ['source.c', 'meta.preprocessor.macro.c']
            expect(tokens[8]).toEqual value: '++', scopes: ['source.c', 'meta.preprocessor.macro.c', 'keyword.operator.increment.c']

            {tokens} = grammar.tokenizeLine '#define MULT(x, y) (x) * (y)'
            expect(tokens[0]).toEqual value: '#', scopes: ['source.c', 'meta.preprocessor.macro.c', 'keyword.control.directive.define.c', 'punctuation.definition.directive.c']
            expect(tokens[1]).toEqual value: 'define', scopes: ['source.c', 'meta.preprocessor.macro.c', 'keyword.control.directive.define.c']
            expect(tokens[3]).toEqual value: 'MULT', scopes: ['source.c', 'meta.preprocessor.macro.c', 'entity.name.function.preprocessor.c']
            expect(tokens[4]).toEqual value: '(', scopes: ['source.c', 'meta.preprocessor.macro.c', 'punctuation.definition.parameters.begin.c']
            expect(tokens[5]).toEqual value: 'x', scopes: ['source.c', 'meta.preprocessor.macro.c', 'variable.parameter.preprocessor.c']
            expect(tokens[6]).toEqual value: ',', scopes: ['source.c', 'meta.preprocessor.macro.c', 'variable.parameter.preprocessor.c', 'punctuation.separator.parameters.c']
            expect(tokens[7]).toEqual value: ' y', scopes: ['source.c', 'meta.preprocessor.macro.c', 'variable.parameter.preprocessor.c']
            expect(tokens[8]).toEqual value: ')', scopes: ['source.c', 'meta.preprocessor.macro.c', 'punctuation.definition.parameters.end.c']
            expect(tokens[9]).toEqual value: ' (x) ', scopes: ['source.c', 'meta.preprocessor.macro.c']
            expect(tokens[10]).toEqual value: '*', scopes: ['source.c', 'meta.preprocessor.macro.c', 'keyword.operator.c']
            expect(tokens[11]).toEqual value: ' (y)', scopes: ['source.c', 'meta.preprocessor.macro.c']

            {tokens} = grammar.tokenizeLine '#define SWAP(a, b)  do { a ^= b; b ^= a; a ^= b; } while ( 0 )'
            expect(tokens[0]).toEqual value: '#', scopes: ['source.c', 'meta.preprocessor.macro.c', 'keyword.control.directive.define.c', 'punctuation.definition.directive.c']
            expect(tokens[1]).toEqual value: 'define', scopes: ['source.c', 'meta.preprocessor.macro.c', 'keyword.control.directive.define.c']
            expect(tokens[3]).toEqual value: 'SWAP', scopes: ['source.c', 'meta.preprocessor.macro.c', 'entity.name.function.preprocessor.c']
            expect(tokens[4]).toEqual value: '(', scopes: ['source.c', 'meta.preprocessor.macro.c', 'punctuation.definition.parameters.begin.c']
            expect(tokens[5]).toEqual value: 'a', scopes: ['source.c', 'meta.preprocessor.macro.c', 'variable.parameter.preprocessor.c']
            expect(tokens[6]).toEqual value: ',', scopes: ['source.c', 'meta.preprocessor.macro.c', 'variable.parameter.preprocessor.c', 'punctuation.separator.parameters.c']
            expect(tokens[7]).toEqual value: ' b', scopes: ['source.c', 'meta.preprocessor.macro.c', 'variable.parameter.preprocessor.c']
            expect(tokens[8]).toEqual value: ')', scopes: ['source.c', 'meta.preprocessor.macro.c', 'punctuation.definition.parameters.end.c']
            expect(tokens[10]).toEqual value: 'do', scopes: ['source.c', 'meta.preprocessor.macro.c', 'keyword.control.c']
            expect(tokens[12]).toEqual value: '{', scopes: ['source.c', 'meta.preprocessor.macro.c', 'meta.block.c', 'punctuation.section.block.begin.c']
            expect(tokens[13]).toEqual value: ' a ', scopes: ['source.c', 'meta.preprocessor.macro.c', 'meta.block.c']
            expect(tokens[14]).toEqual value: '^=', scopes: ['source.c', 'meta.preprocessor.macro.c', 'meta.block.c', 'keyword.operator.assignment.compound.bitwise.c']
            expect(tokens[15]).toEqual value: ' b; b ', scopes: ['source.c', 'meta.preprocessor.macro.c', 'meta.block.c']
            expect(tokens[16]).toEqual value: '^=', scopes: ['source.c', 'meta.preprocessor.macro.c', 'meta.block.c', 'keyword.operator.assignment.compound.bitwise.c']
            expect(tokens[17]).toEqual value: ' a; a ', scopes: ['source.c', 'meta.preprocessor.macro.c', 'meta.block.c']
            expect(tokens[18]).toEqual value: '^=', scopes: ['source.c', 'meta.preprocessor.macro.c', 'meta.block.c', 'keyword.operator.assignment.compound.bitwise.c']
            expect(tokens[19]).toEqual value: ' b; ', scopes: ['source.c', 'meta.preprocessor.macro.c', 'meta.block.c']
            expect(tokens[20]).toEqual value: '}', scopes: ['source.c', 'meta.preprocessor.macro.c', 'meta.block.c', 'punctuation.section.block.end.c']
            expect(tokens[22]).toEqual value: 'while', scopes: ['source.c', 'meta.preprocessor.macro.c', 'keyword.control.c']
            expect(tokens[23]).toEqual value: ' ( ', scopes: ['source.c', 'meta.preprocessor.macro.c']
            expect(tokens[24]).toEqual value: '0', scopes: ['source.c', 'meta.preprocessor.macro.c', 'constant.numeric.c']
            expect(tokens[25]).toEqual value: ' )', scopes: ['source.c', 'meta.preprocessor.macro.c']

          it "tokenizes multiline macros", ->
            lines = grammar.tokenizeLines '''
              #define max(a,b) (a>b)? \\
                                a:b
            '''
            expect(lines[0][14]).toEqual value: '\\', scopes: ['source.c', 'meta.preprocessor.macro.c', 'constant.character.escape.line-continuation.c']

            lines = grammar.tokenizeLines '''
              #define SWAP(a, b)  { \\
                a ^= b; \\
                b ^= a; \\
                a ^= b; \\
              }
            '''
            expect(lines[0][0]).toEqual value: '#', scopes: ['source.c', 'meta.preprocessor.macro.c', 'keyword.control.directive.define.c', 'punctuation.definition.directive.c']
            expect(lines[0][1]).toEqual value: 'define', scopes: ['source.c', 'meta.preprocessor.macro.c', 'keyword.control.directive.define.c']
            expect(lines[0][3]).toEqual value: 'SWAP', scopes: ['source.c', 'meta.preprocessor.macro.c', 'entity.name.function.preprocessor.c']
            expect(lines[0][4]).toEqual value: '(', scopes: ['source.c', 'meta.preprocessor.macro.c', 'punctuation.definition.parameters.begin.c']
            expect(lines[0][5]).toEqual value: 'a', scopes: ['source.c', 'meta.preprocessor.macro.c', 'variable.parameter.preprocessor.c']
            expect(lines[0][6]).toEqual value: ',', scopes: ['source.c', 'meta.preprocessor.macro.c', 'variable.parameter.preprocessor.c', 'punctuation.separator.parameters.c']
            expect(lines[0][7]).toEqual value: ' b', scopes: ['source.c', 'meta.preprocessor.macro.c', 'variable.parameter.preprocessor.c']
            expect(lines[0][8]).toEqual value: ')', scopes: ['source.c', 'meta.preprocessor.macro.c', 'punctuation.definition.parameters.end.c']
            expect(lines[0][10]).toEqual value: '{', scopes: ['source.c', 'meta.preprocessor.macro.c', 'meta.block.c', 'punctuation.section.block.begin.c']
            expect(lines[0][12]).toEqual value: '\\', scopes: ['source.c', 'meta.preprocessor.macro.c', 'meta.block.c', 'constant.character.escape.line-continuation.c']
            expect(lines[1][1]).toEqual value: '^=', scopes: ['source.c', 'meta.preprocessor.macro.c', 'meta.block.c', 'keyword.operator.assignment.compound.bitwise.c']
            expect(lines[1][3]).toEqual value: '\\', scopes: ['source.c', 'meta.preprocessor.macro.c', 'meta.block.c', 'constant.character.escape.line-continuation.c']
            expect(lines[2][1]).toEqual value: '^=', scopes: ['source.c', 'meta.preprocessor.macro.c', 'meta.block.c', 'keyword.operator.assignment.compound.bitwise.c']
            expect(lines[2][3]).toEqual value: '\\', scopes: ['source.c', 'meta.preprocessor.macro.c', 'meta.block.c', 'constant.character.escape.line-continuation.c']
            expect(lines[3][1]).toEqual value: '^=', scopes: ['source.c', 'meta.preprocessor.macro.c', 'meta.block.c', 'keyword.operator.assignment.compound.bitwise.c']
            expect(lines[3][3]).toEqual value: '\\', scopes: ['source.c', 'meta.preprocessor.macro.c', 'meta.block.c', 'constant.character.escape.line-continuation.c']
            expect(lines[4][0]).toEqual value: '}', scopes: ['source.c', 'meta.preprocessor.macro.c', 'meta.block.c', 'punctuation.section.block.end.c']

      describe "includes", ->
        it "tokenizes '#include'", ->
          {tokens} = grammar.tokenizeLine '#include <stdio.h>'
          expect(tokens[0]).toEqual value: '#', scopes: ['source.c', 'meta.preprocessor.include.c', 'keyword.control.directive.include.c', 'punctuation.definition.directive.c']
          expect(tokens[1]).toEqual value: 'include', scopes: ['source.c', 'meta.preprocessor.include.c', 'keyword.control.directive.include.c']
          expect(tokens[3]).toEqual value: '<', scopes: ['source.c', 'meta.preprocessor.include.c', 'string.quoted.other.lt-gt.include.c', 'punctuation.definition.string.begin.c']
          expect(tokens[4]).toEqual value: 'stdio.h', scopes: ['source.c', 'meta.preprocessor.include.c', 'string.quoted.other.lt-gt.include.c']
          expect(tokens[5]).toEqual value: '>', scopes: ['source.c', 'meta.preprocessor.include.c', 'string.quoted.other.lt-gt.include.c', 'punctuation.definition.string.end.c']

          {tokens} = grammar.tokenizeLine '#include<stdio.h>'
          expect(tokens[0]).toEqual value: '#', scopes: ['source.c', 'meta.preprocessor.include.c', 'keyword.control.directive.include.c', 'punctuation.definition.directive.c']
          expect(tokens[1]).toEqual value: 'include', scopes: ['source.c', 'meta.preprocessor.include.c', 'keyword.control.directive.include.c']
          expect(tokens[2]).toEqual value: '<', scopes: ['source.c', 'meta.preprocessor.include.c', 'string.quoted.other.lt-gt.include.c', 'punctuation.definition.string.begin.c']
          expect(tokens[3]).toEqual value: 'stdio.h', scopes: ['source.c', 'meta.preprocessor.include.c', 'string.quoted.other.lt-gt.include.c']
          expect(tokens[4]).toEqual value: '>', scopes: ['source.c', 'meta.preprocessor.include.c', 'string.quoted.other.lt-gt.include.c', 'punctuation.definition.string.end.c']

          {tokens} = grammar.tokenizeLine '#include_<stdio.h>'
          expect(tokens[0]).toEqual value: '#include_', scopes: ['source.c']

          {tokens} = grammar.tokenizeLine '#include "file"'
          expect(tokens[0]).toEqual value: '#', scopes: ['source.c', 'meta.preprocessor.include.c', 'keyword.control.directive.include.c', 'punctuation.definition.directive.c']
          expect(tokens[1]).toEqual value: 'include', scopes: ['source.c', 'meta.preprocessor.include.c', 'keyword.control.directive.include.c']
          expect(tokens[3]).toEqual value: '"', scopes: ['source.c', 'meta.preprocessor.include.c', 'string.quoted.double.include.c', 'punctuation.definition.string.begin.c']
          expect(tokens[4]).toEqual value: 'file', scopes: ['source.c', 'meta.preprocessor.include.c', 'string.quoted.double.include.c']
          expect(tokens[5]).toEqual value: '"', scopes: ['source.c', 'meta.preprocessor.include.c', 'string.quoted.double.include.c', 'punctuation.definition.string.end.c']

        it "tokenizes '#import'", ->
          {tokens} = grammar.tokenizeLine '#import "file"'
          expect(tokens[0]).toEqual value: '#', scopes: ['source.c', 'meta.preprocessor.include.c', 'keyword.control.directive.import.c', 'punctuation.definition.directive.c']
          expect(tokens[1]).toEqual value: 'import', scopes: ['source.c', 'meta.preprocessor.include.c', 'keyword.control.directive.import.c']
          expect(tokens[3]).toEqual value: '"', scopes: ['source.c', 'meta.preprocessor.include.c', 'string.quoted.double.include.c', 'punctuation.definition.string.begin.c']
          expect(tokens[4]).toEqual value: 'file', scopes: ['source.c', 'meta.preprocessor.include.c', 'string.quoted.double.include.c']
          expect(tokens[5]).toEqual value: '"', scopes: ['source.c', 'meta.preprocessor.include.c', 'string.quoted.double.include.c', 'punctuation.definition.string.end.c']

      describe "diagnostics", ->
        it "tokenizes '#error'", ->
          {tokens} = grammar.tokenizeLine '#error C++ compiler required.'
          expect(tokens[0]).toEqual value: '#', scopes: ['source.c', 'meta.preprocessor.diagnostic.c', 'keyword.control.directive.diagnostic.error.c', 'punctuation.definition.directive.c']
          expect(tokens[1]).toEqual value: 'error', scopes: ['source.c', 'meta.preprocessor.diagnostic.c', 'keyword.control.directive.diagnostic.error.c']
          expect(tokens[2]).toEqual value: ' C++ compiler required.', scopes: ['source.c', 'meta.preprocessor.diagnostic.c']

        it "tokenizes '#warning'", ->
          {tokens} = grammar.tokenizeLine '#warning This is a warning.'
          expect(tokens[0]).toEqual value: '#', scopes: ['source.c', 'meta.preprocessor.diagnostic.c', 'keyword.control.directive.diagnostic.warning.c', 'punctuation.definition.directive.c']
          expect(tokens[1]).toEqual value: 'warning', scopes: ['source.c', 'meta.preprocessor.diagnostic.c', 'keyword.control.directive.diagnostic.warning.c']
          expect(tokens[2]).toEqual value: ' This is a warning.', scopes: ['source.c', 'meta.preprocessor.diagnostic.c']

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
          expect(lines[0][0]).toEqual value: '#', scopes: ['source.c', 'meta.preprocessor.c', 'keyword.control.directive.conditional.c', 'punctuation.definition.directive.c']
          expect(lines[0][1]).toEqual value: 'if', scopes: ['source.c', 'meta.preprocessor.c', 'keyword.control.directive.conditional.c']
          expect(lines[0][2]).toEqual value: ' defined(CREDIT)', scopes: ['source.c', 'meta.preprocessor.c']
          expect(lines[1][1]).toEqual value: 'credit', scopes: ['source.c', 'meta.function.c', 'entity.name.function.c']
          expect(lines[1][2]).toEqual value: '(', scopes: ['source.c', 'meta.function.c', 'meta.parens.c', 'punctuation.section.parens.begin.c']
          expect(lines[1][3]).toEqual value: ')', scopes: ['source.c', 'meta.function.c', 'meta.parens.c', 'punctuation.section.parens.end.c']
          expect(lines[2][0]).toEqual value: '#', scopes: ['source.c', 'meta.preprocessor.c', 'keyword.control.directive.conditional.c', 'punctuation.definition.directive.c']
          expect(lines[2][1]).toEqual value: 'elif', scopes: ['source.c', 'meta.preprocessor.c', 'keyword.control.directive.conditional.c']
          expect(lines[2][2]).toEqual value: ' defined(DEBIT)', scopes: ['source.c', 'meta.preprocessor.c']
          expect(lines[3][1]).toEqual value: 'debit', scopes: ['source.c', 'meta.function.c', 'entity.name.function.c']
          expect(lines[3][2]).toEqual value: '(', scopes: ['source.c', 'meta.function.c', 'meta.parens.c', 'punctuation.section.parens.begin.c']
          expect(lines[3][3]).toEqual value: ')', scopes: ['source.c', 'meta.function.c', 'meta.parens.c', 'punctuation.section.parens.end.c']
          expect(lines[4][0]).toEqual value: '#', scopes: ['source.c', 'meta.preprocessor.c', 'keyword.control.directive.conditional.c', 'punctuation.definition.directive.c']
          expect(lines[4][1]).toEqual value: 'else', scopes: ['source.c', 'meta.preprocessor.c', 'keyword.control.directive.conditional.c']
          expect(lines[5][1]).toEqual value: 'printerror', scopes: ['source.c', 'meta.function.c', 'entity.name.function.c']
          expect(lines[5][2]).toEqual value: '(', scopes: ['source.c', 'meta.function.c', 'meta.parens.c', 'punctuation.section.parens.begin.c']
          expect(lines[5][3]).toEqual value: ')', scopes: ['source.c', 'meta.function.c', 'meta.parens.c', 'punctuation.section.parens.end.c']
          expect(lines[6][0]).toEqual value: '#', scopes: ['source.c', 'meta.preprocessor.c', 'keyword.control.directive.conditional.c', 'punctuation.definition.directive.c']
          expect(lines[6][1]).toEqual value: 'endif', scopes: ['source.c', 'meta.preprocessor.c', 'keyword.control.directive.conditional.c']

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
          expect(lines[0][0]).toEqual value: '#', scopes: ['source.c', 'meta.preprocessor.c', 'keyword.control.directive.conditional.c', 'punctuation.definition.directive.c']
          expect(lines[0][1]).toEqual value: 'if', scopes: ['source.c', 'meta.preprocessor.c', 'keyword.control.directive.conditional.c']
          expect(lines[0][3]).toEqual value: '1', scopes: ['source.c', 'meta.preprocessor.c', 'constant.numeric.preprocessor.c']
          expect(lines[1][0]).toEqual value: 'int', scopes: ['source.c', 'storage.type.c']
          expect(lines[1][2]).toEqual value: 'something', scopes: ['source.c', 'meta.function.c', 'entity.name.function.c']
          expect(lines[2][1]).toEqual value: '#', scopes: ['source.c', 'meta.function.c', 'meta.block.c', 'meta.preprocessor.c', 'keyword.control.directive.conditional.c', 'punctuation.definition.directive.c']
          expect(lines[2][2]).toEqual value: 'if', scopes: ['source.c', 'meta.function.c', 'meta.block.c', 'meta.preprocessor.c', 'keyword.control.directive.conditional.c']
          expect(lines[2][4]).toEqual value: '1', scopes: ['source.c', 'meta.function.c', 'meta.block.c', 'meta.preprocessor.c', 'constant.numeric.preprocessor.c']
          expect(lines[3][1]).toEqual value: 'return', scopes: ['source.c', 'meta.function.c', 'meta.block.c', 'keyword.control.c']
          expect(lines[3][3]).toEqual value: '1', scopes: ['source.c', 'meta.function.c', 'meta.block.c', 'constant.numeric.c']
          expect(lines[4][1]).toEqual value: '#', scopes: ['source.c', 'meta.function.c', 'meta.block.c', 'meta.preprocessor.c', 'keyword.control.directive.conditional.c', 'punctuation.definition.directive.c']
          expect(lines[4][2]).toEqual value: 'else', scopes: ['source.c', 'meta.function.c', 'meta.block.c', 'meta.preprocessor.c', 'keyword.control.directive.conditional.c']
          expect(lines[5][0]).toEqual value: '    return 0;', scopes: ['source.c', 'meta.function.c', 'meta.block.c', 'comment.block.preprocessor.else-branch.in-block']
          expect(lines[6][1]).toEqual value: '#', scopes: ['source.c', 'meta.function.c', 'meta.block.c', 'meta.preprocessor.c', 'keyword.control.directive.conditional.c', 'punctuation.definition.directive.c']
          expect(lines[6][2]).toEqual value: 'endif', scopes: ['source.c', 'meta.function.c', 'meta.block.c', 'meta.preprocessor.c', 'keyword.control.directive.conditional.c']
          expect(lines[8][0]).toEqual value: '#', scopes: ['source.c', 'meta.preprocessor.c', 'keyword.control.directive.conditional.c', 'punctuation.definition.directive.c']
          expect(lines[8][1]).toEqual value: 'else', scopes: ['source.c', 'meta.preprocessor.c', 'keyword.control.directive.conditional.c']
          expect(lines[9][0]).toEqual value: 'int something() {', scopes: ['source.c', 'comment.block.preprocessor.else-branch']
          expect(lines[12][0]).toEqual value: '#', scopes: ['source.c', 'meta.preprocessor.c', 'keyword.control.directive.conditional.c', 'punctuation.definition.directive.c']
          expect(lines[12][1]).toEqual value: 'endif', scopes: ['source.c', 'meta.preprocessor.c', 'keyword.control.directive.conditional.c']

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
          expect(lines[0][0]).toEqual value: 'int', scopes: ['source.c', 'storage.type.c']
          expect(lines[0][2]).toEqual value: 'something', scopes: ['source.c', 'meta.function.c', 'entity.name.function.c']
          expect(lines[1][1]).toEqual value: '#', scopes: ['source.c', 'meta.function.c', 'meta.block.c', 'meta.preprocessor.c', 'keyword.control.directive.conditional.c', 'punctuation.definition.directive.c']
          expect(lines[1][2]).toEqual value: 'if', scopes: ['source.c', 'meta.function.c', 'meta.block.c', 'meta.preprocessor.c', 'keyword.control.directive.conditional.c']
          expect(lines[1][4]).toEqual value: '0', scopes: ['source.c', 'meta.function.c', 'meta.block.c', 'meta.preprocessor.c', 'constant.numeric.preprocessor.c']
          expect(lines[2][0]).toEqual value: '    return 1;', scopes: ['source.c', 'meta.function.c', 'meta.block.c', 'comment.block.preprocessor.if-branch.in-block']
          expect(lines[3][1]).toEqual value: '#', scopes: ['source.c', 'meta.function.c', 'meta.block.c', 'meta.preprocessor.c', 'keyword.control.directive.conditional.c', 'punctuation.definition.directive.c']
          expect(lines[3][2]).toEqual value: 'else', scopes: ['source.c', 'meta.function.c', 'meta.block.c', 'meta.preprocessor.c', 'keyword.control.directive.conditional.c']
          expect(lines[4][1]).toEqual value: 'return', scopes: ['source.c', 'meta.function.c', 'meta.block.c', 'keyword.control.c']
          expect(lines[4][3]).toEqual value: '0', scopes: ['source.c', 'meta.function.c', 'meta.block.c', 'constant.numeric.c']
          expect(lines[5][1]).toEqual value: '#', scopes: ['source.c', 'meta.function.c', 'meta.block.c', 'meta.preprocessor.c', 'keyword.control.directive.conditional.c', 'punctuation.definition.directive.c']
          expect(lines[5][2]).toEqual value: 'endif', scopes: ['source.c', 'meta.function.c', 'meta.block.c', 'meta.preprocessor.c', 'keyword.control.directive.conditional.c']

          lines = grammar.tokenizeLines '''
            #if 0
              something();
            #endif
          '''
          expect(lines[0][0]).toEqual value: '#', scopes: ['source.c', 'meta.preprocessor.c', 'keyword.control.directive.conditional.c', 'punctuation.definition.directive.c']
          expect(lines[0][1]).toEqual value: 'if', scopes: ['source.c', 'meta.preprocessor.c', 'keyword.control.directive.conditional.c']
          expect(lines[0][3]).toEqual value: '0', scopes: ['source.c', 'meta.preprocessor.c', 'constant.numeric.preprocessor.c']
          expect(lines[1][0]).toEqual value: '  something();', scopes: ['source.c', 'comment.block.preprocessor.if-branch']
          expect(lines[2][0]).toEqual value: '#', scopes: ['source.c', 'meta.preprocessor.c', 'keyword.control.directive.conditional.c', 'punctuation.definition.directive.c']
          expect(lines[2][1]).toEqual value: 'endif', scopes: ['source.c', 'meta.preprocessor.c', 'keyword.control.directive.conditional.c']

        it "tokenizes ifdef-elif blocks", ->
          lines = grammar.tokenizeLines '''
            #ifdef __unix__ /* is defined by compilers targeting Unix systems */
              # include <unistd.h>
            #elif defined _WIN32 /* is defined by compilers targeting Windows systems */
              # include <windows.h>
            #endif
          '''
          expect(lines[0][0]).toEqual value: '#', scopes: ['source.c', 'meta.preprocessor.c', 'keyword.control.directive.conditional.c', 'punctuation.definition.directive.c']
          expect(lines[0][1]).toEqual value: 'ifdef', scopes: ['source.c', 'meta.preprocessor.c', 'keyword.control.directive.conditional.c']
          expect(lines[0][2]).toEqual value: ' __unix__ ', scopes: ['source.c', 'meta.preprocessor.c']
          expect(lines[0][3]).toEqual value: '/*', scopes: ['source.c', 'comment.block.c', 'punctuation.definition.comment.begin.c']
          expect(lines[0][4]).toEqual value: ' is defined by compilers targeting Unix systems ', scopes: ['source.c', 'comment.block.c']
          expect(lines[0][5]).toEqual value: '*/', scopes: ['source.c', 'comment.block.c', 'punctuation.definition.comment.end.c']
          expect(lines[1][1]).toEqual value: '#', scopes: ['source.c', 'meta.preprocessor.include.c', 'keyword.control.directive.include.c', 'punctuation.definition.directive.c']
          expect(lines[1][2]).toEqual value: ' include', scopes: ['source.c', 'meta.preprocessor.include.c', 'keyword.control.directive.include.c']
          expect(lines[1][4]).toEqual value: '<', scopes: ['source.c', 'meta.preprocessor.include.c', 'string.quoted.other.lt-gt.include.c', 'punctuation.definition.string.begin.c']
          expect(lines[1][5]).toEqual value: 'unistd.h', scopes: ['source.c', 'meta.preprocessor.include.c', 'string.quoted.other.lt-gt.include.c']
          expect(lines[1][6]).toEqual value: '>', scopes: ['source.c', 'meta.preprocessor.include.c', 'string.quoted.other.lt-gt.include.c', 'punctuation.definition.string.end.c']
          expect(lines[2][0]).toEqual value: '#', scopes: ['source.c', 'meta.preprocessor.c', 'keyword.control.directive.conditional.c', 'punctuation.definition.directive.c']
          expect(lines[2][1]).toEqual value: 'elif', scopes: ['source.c', 'meta.preprocessor.c', 'keyword.control.directive.conditional.c']
          expect(lines[2][2]).toEqual value: ' defined _WIN32 ', scopes: ['source.c', 'meta.preprocessor.c']
          expect(lines[2][3]).toEqual value: '/*', scopes: ['source.c', 'comment.block.c', 'punctuation.definition.comment.begin.c']
          expect(lines[2][4]).toEqual value: ' is defined by compilers targeting Windows systems ', scopes: ['source.c', 'comment.block.c']
          expect(lines[2][5]).toEqual value: '*/', scopes: ['source.c', 'comment.block.c', 'punctuation.definition.comment.end.c']
          expect(lines[3][1]).toEqual value: '#', scopes: ['source.c', 'meta.preprocessor.include.c', 'keyword.control.directive.include.c', 'punctuation.definition.directive.c']
          expect(lines[3][2]).toEqual value: ' include', scopes: ['source.c', 'meta.preprocessor.include.c', 'keyword.control.directive.include.c']
          expect(lines[3][4]).toEqual value: '<', scopes: ['source.c', 'meta.preprocessor.include.c', 'string.quoted.other.lt-gt.include.c', 'punctuation.definition.string.begin.c']
          expect(lines[3][5]).toEqual value: 'windows.h', scopes: ['source.c', 'meta.preprocessor.include.c', 'string.quoted.other.lt-gt.include.c']
          expect(lines[3][6]).toEqual value: '>', scopes: ['source.c', 'meta.preprocessor.include.c', 'string.quoted.other.lt-gt.include.c', 'punctuation.definition.string.end.c']
          expect(lines[4][0]).toEqual value: '#', scopes: ['source.c', 'meta.preprocessor.c', 'keyword.control.directive.conditional.c', 'punctuation.definition.directive.c']
          expect(lines[4][1]).toEqual value: 'endif', scopes: ['source.c', 'meta.preprocessor.c', 'keyword.control.directive.conditional.c']

        it "tokenizes ifndef blocks", ->
          lines = grammar.tokenizeLines '''
            #ifndef _INCL_GUARD
              #define _INCL_GUARD
            #endif
          '''
          expect(lines[0][0]).toEqual value: '#', scopes: ['source.c', 'meta.preprocessor.c', 'keyword.control.directive.conditional.c', 'punctuation.definition.directive.c']
          expect(lines[0][1]).toEqual value: 'ifndef', scopes: ['source.c', 'meta.preprocessor.c', 'keyword.control.directive.conditional.c']
          expect(lines[0][2]).toEqual value: ' _INCL_GUARD', scopes: ['source.c', 'meta.preprocessor.c']
          expect(lines[1][1]).toEqual value: '#', scopes: ['source.c', 'meta.preprocessor.macro.c', 'keyword.control.directive.define.c', 'punctuation.definition.directive.c']
          expect(lines[1][2]).toEqual value: 'define', scopes: ['source.c', 'meta.preprocessor.macro.c', 'keyword.control.directive.define.c']
          expect(lines[1][4]).toEqual value: '_INCL_GUARD', scopes: ['source.c', 'meta.preprocessor.macro.c', 'entity.name.function.preprocessor.c']
          expect(lines[2][0]).toEqual value: '#', scopes: ['source.c', 'meta.preprocessor.c', 'keyword.control.directive.conditional.c', 'punctuation.definition.directive.c']
          expect(lines[2][1]).toEqual value: 'endif', scopes: ['source.c', 'meta.preprocessor.c', 'keyword.control.directive.conditional.c']

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

      it "tokenizes binary literal", ->
        {tokens} = grammar.tokenizeLine '0b101010'
        expect(tokens[0]).toEqual value: '0b101010', scopes: ['source.c', 'constant.numeric.c']

    describe "access", ->
      it "should tokenizes dot access", ->
        lines = grammar.tokenizeLines '''
          int main() {
            A a;
            a.b = NULL;
            return 0;
          }
        '''

        expect(lines[2][0]).toEqual value: '  a', scopes: ['source.c', 'meta.function.c', 'meta.block.c']
        expect(lines[2][1]).toEqual value: '.', scopes: ['source.c', 'meta.function.c', 'meta.block.c', 'punctuation.separator.dot-access.c']
        expect(lines[2][2]).toEqual value: 'b', scopes: ['source.c', 'meta.function.c', 'meta.block.c', 'variable.other.member.c']

      it "should tokenizes pointer access", ->
        lines = grammar.tokenizeLines '''
          int main() {
            A *a;
            a->b = NULL;
            return 0;
          }
        '''

        expect(lines[2][0]).toEqual value: '  a', scopes: ['source.c', 'meta.function.c', 'meta.block.c']
        expect(lines[2][1]).toEqual value: '->', scopes: ['source.c', 'meta.function.c', 'meta.block.c', 'punctuation.separator.pointer-access.c']
        expect(lines[2][2]).toEqual value: 'b', scopes: ['source.c', 'meta.function.c', 'meta.block.c', 'variable.other.member.c']

    describe "operators", ->
      it "tokenizes the sizeof operator", ->
        {tokens} = grammar.tokenizeLine('sizeof unary_expression')
        expect(tokens[0]).toEqual value: 'sizeof', scopes: ['source.c', 'keyword.operator.sizeof.c']
        expect(tokens[1]).toEqual value: ' unary_expression', scopes: ['source.c']

        {tokens} = grammar.tokenizeLine('sizeof (int)')
        expect(tokens[0]).toEqual value: 'sizeof', scopes: ['source.c', 'keyword.operator.sizeof.c']
        expect(tokens[1]).toEqual value: ' (', scopes: ['source.c']
        expect(tokens[2]).toEqual value: 'int', scopes: ['source.c', 'storage.type.c']
        expect(tokens[3]).toEqual value: ')', scopes: ['source.c']

        {tokens} = grammar.tokenizeLine('$sizeof')
        expect(tokens[1]).not.toEqual value: 'sizeof', scopes: ['source.c', 'keyword.operator.sizeof.c']

        {tokens} = grammar.tokenizeLine('sizeof$')
        expect(tokens[0]).not.toEqual value: 'sizeof', scopes: ['source.c', 'keyword.operator.sizeof.c']

        {tokens} = grammar.tokenizeLine('sizeof_')
        expect(tokens[0]).not.toEqual value: 'sizeof', scopes: ['source.c', 'keyword.operator.sizeof.c']

      it "tokenizes the increment operator", ->
        {tokens} = grammar.tokenizeLine('i++')
        expect(tokens[0]).toEqual value: 'i', scopes: ['source.c']
        expect(tokens[1]).toEqual value: '++', scopes: ['source.c', 'keyword.operator.increment.c']

        {tokens} = grammar.tokenizeLine('++i')
        expect(tokens[0]).toEqual value: '++', scopes: ['source.c', 'keyword.operator.increment.c']
        expect(tokens[1]).toEqual value: 'i', scopes: ['source.c']

      it "tokenizes the decrement operator", ->
        {tokens} = grammar.tokenizeLine('i--')
        expect(tokens[0]).toEqual value: 'i', scopes: ['source.c']
        expect(tokens[1]).toEqual value: '--', scopes: ['source.c', 'keyword.operator.decrement.c']

        {tokens} = grammar.tokenizeLine('--i')
        expect(tokens[0]).toEqual value: '--', scopes: ['source.c', 'keyword.operator.decrement.c']
        expect(tokens[1]).toEqual value: 'i', scopes: ['source.c']

      it "tokenizes logical operators", ->
        {tokens} = grammar.tokenizeLine('!a')
        expect(tokens[0]).toEqual value: '!', scopes: ['source.c', 'keyword.operator.logical.c']
        expect(tokens[1]).toEqual value: 'a', scopes: ['source.c']

        operators = ['&&', '||']
        for operator in operators
          {tokens} = grammar.tokenizeLine('a ' + operator + ' b')
          expect(tokens[0]).toEqual value: 'a ', scopes: ['source.c']
          expect(tokens[1]).toEqual value: operator, scopes: ['source.c', 'keyword.operator.logical.c']
          expect(tokens[2]).toEqual value: ' b', scopes: ['source.c']

      it "tokenizes comparison operators", ->
        operators = ['<=', '>=', '!=', '==', '<', '>' ]

        for operator in operators
          {tokens} = grammar.tokenizeLine('a ' + operator + ' b')
          expect(tokens[0]).toEqual value: 'a ', scopes: ['source.c']
          expect(tokens[1]).toEqual value: operator, scopes: ['source.c', 'keyword.operator.comparison.c']
          expect(tokens[2]).toEqual value: ' b', scopes: ['source.c']

      it "tokenizes arithmetic operators", ->
        operators = ['+', '-', '*', '/', '%']

        for operator in operators
          {tokens} = grammar.tokenizeLine('a ' + operator + ' b')
          expect(tokens[0]).toEqual value: 'a ', scopes: ['source.c']
          expect(tokens[1]).toEqual value: operator, scopes: ['source.c', 'keyword.operator.c']
          expect(tokens[2]).toEqual value: ' b', scopes: ['source.c']

      it "tokenizes ternary operators", ->
        {tokens} = grammar.tokenizeLine('a ? b : c')
        expect(tokens[0]).toEqual value: 'a ', scopes: ['source.c']
        expect(tokens[1]).toEqual value: '?', scopes: ['source.c', 'keyword.operator.ternary.c']
        expect(tokens[2]).toEqual value: ' b ', scopes: ['source.c']
        expect(tokens[3]).toEqual value: ':', scopes: ['source.c', 'keyword.operator.ternary.c']
        expect(tokens[4]).toEqual value: ' c', scopes: ['source.c']

      describe "bitwise", ->
        it "tokenizes bitwise 'not'", ->
          {tokens} = grammar.tokenizeLine('~a')
          expect(tokens[0]).toEqual value: '~', scopes: ['source.c', 'keyword.operator.c']
          expect(tokens[1]).toEqual value: 'a', scopes: ['source.c']

        it "tokenizes shift operators", ->
          {tokens} = grammar.tokenizeLine('>>')
          expect(tokens[0]).toEqual value: '>>', scopes: ['source.c', 'keyword.operator.bitwise.shift.c']

          {tokens} = grammar.tokenizeLine('<<')
          expect(tokens[0]).toEqual value: '<<', scopes: ['source.c', 'keyword.operator.bitwise.shift.c']

        it "tokenizes them", ->
          operators = ['|', '^', '&']

          for operator in operators
            {tokens} = grammar.tokenizeLine('a ' + operator + ' b')
            expect(tokens[0]).toEqual value: 'a ', scopes: ['source.c']
            expect(tokens[1]).toEqual value: operator, scopes: ['source.c', 'keyword.operator.c']
            expect(tokens[2]).toEqual value: ' b', scopes: ['source.c']

      describe "assignment", ->
        it "tokenizes the assignment operator", ->
          {tokens} = grammar.tokenizeLine('a = b')
          expect(tokens[0]).toEqual value: 'a ', scopes: ['source.c']
          expect(tokens[1]).toEqual value: '=', scopes: ['source.c', 'keyword.operator.assignment.c']
          expect(tokens[2]).toEqual value: ' b', scopes: ['source.c']

        it "tokenizes compound assignment operators", ->
          operators = ['+=', '-=', '*=', '/=', '%=']
          for operator in operators
            {tokens} = grammar.tokenizeLine('a ' + operator + ' b')
            expect(tokens[0]).toEqual value: 'a ', scopes: ['source.c']
            expect(tokens[1]).toEqual value: operator, scopes: ['source.c', 'keyword.operator.assignment.compound.c']
            expect(tokens[2]).toEqual value: ' b', scopes: ['source.c']

        it "tokenizes bitwise compound operators", ->
          operators = ['<<=', '>>=', '&=', '^=', '|=']
          for operator in operators
            {tokens} = grammar.tokenizeLine('a ' + operator + ' b')
            expect(tokens[0]).toEqual value: 'a ', scopes: ['source.c']
            expect(tokens[1]).toEqual value: operator, scopes: ['source.c', 'keyword.operator.assignment.compound.bitwise.c']
            expect(tokens[2]).toEqual value: ' b', scopes: ['source.c']

    describe "firstLineMatch", ->
      it "recognises interpreter directives", ->
        valid = """
          #!/usr/sbin/tcc foo
          #!/usr/bin/tcc foo=bar/
          #!/usr/sbin/tcc
          #!/usr/sbin/tcc foo bar baz
          #!/usr/bin/tcc perl
          #!/usr/bin/tcc bin/perl
          #!/usr/bin/tcc
          #!/bin/tcc
          #!/usr/bin/tcc --script=usr/bin
          #! /usr/bin/env A=003 B=149 C=150 D=xzd E=base64 F=tar G=gz H=head I=tail tcc
          #!\t/usr/bin/env --foo=bar tcc --quu=quux
          #! /usr/bin/tcc
          #!/usr/bin/env tcc
        """
        for line in valid.split /\n/
          expect(grammar.firstLineRegex.scanner.findNextMatchSync(line)).not.toBeNull()

        invalid = """
          \x20#!/usr/sbin/tcc
          \t#!/usr/sbin/tcc
          #!/usr/bin/env-tcc/node-env/
          #!/usr/bin/env-tcc
          #! /usr/bintcc
          #!\t/usr/bin/env --tcc=bar
        """
        for line in invalid.split /\n/
          expect(grammar.firstLineRegex.scanner.findNextMatchSync(line)).toBeNull()

      it "recognises Emacs modelines", ->
        valid = """
          #-*- C -*-
          #-*- mode: C -*-
          /* -*-c-*- */
          // -*- C -*-
          /* -*- mode:C -*- */
          // -*- font:bar;mode:C -*-
          // -*- font:bar;mode:C;foo:bar; -*-
          // -*-font:mode;mode:C-*-
          // -*- foo:bar mode: c bar:baz -*-
          " -*-foo:bar;mode:c;bar:foo-*- ";
          " -*-font-mode:foo;mode:c;foo-bar:quux-*-"
          "-*-font:x;foo:bar; mode : c; bar:foo;foooooo:baaaaar;fo:ba;-*-";
          "-*- font:x;foo : bar ; mode : C ; bar : foo ; foooooo:baaaaar;fo:ba-*-";
        """
        for line in valid.split /\n/
          expect(grammar.firstLineRegex.scanner.findNextMatchSync(line)).not.toBeNull()

        invalid = """
          /* --*c-*- */
          /* -*-- c -*-
          /* -*- -- C -*-
          /* -*- CC -;- -*-
          // -*- iC -*-
          // -*- C; -*-
          // -*- c-stuff -*-
          /* -*- model:c -*-
          /* -*- indent-mode:c -*-
          // -*- font:mode;C -*-
          // -*- mode: -*- C
          // -*- mode: all-you-need-is-c -*-
          // -*-font:mode;mode:c--*-
        """
        for line in invalid.split /\n/
          expect(grammar.firstLineRegex.scanner.findNextMatchSync(line)).toBeNull()

      it "recognises Vim modelines", ->
        valid = """
          vim: se filetype=c:
          # vim: se ft=c:
          # vim: set ft=C:
          # vim: set filetype=C:
          # vim: ft=C
          # vim: syntax=C
          # vim: se syntax=C:
          # ex: syntax=C
          # vim:ft=c
          # vim600: ft=c
          # vim>600: set ft=c:
          # vi:noai:sw=3 ts=6 ft=c
          # vi::::::::::noai:::::::::::: ft=c
          # vim:ts=4:sts=4:sw=4:noexpandtab:ft=c
          # vi:: noai : : : : sw   =3 ts   =6 ft  =c
          # vim: ts=4: pi sts=4: ft=c: noexpandtab: sw=4:
          # vim: ts=4 sts=4: ft=c noexpandtab:
          # vim:noexpandtab sts=4 ft=c ts=4
          # vim:noexpandtab:ft=c
          # vim:ts=4:sts=4 ft=c:noexpandtab:\x20
          # vim:noexpandtab titlestring=hi\|there\\\\ ft=c ts=4
        """
        for line in valid.split /\n/
          expect(grammar.firstLineRegex.scanner.findNextMatchSync(line)).not.toBeNull()

        invalid = """
          ex: se filetype=c:
          _vi: se filetype=c:
           vi: se filetype=c
          # vim set ft=cpp
          # vim: soft=c
          # vim: clean-syntax=c:
          # vim set ft=c:
          # vim: setft=c:
          # vim: se ft=c backupdir=tmp
          # vim: set ft=c set cmdheight=1
          # vim:noexpandtab sts:4 ft:c ts:4
          # vim:noexpandtab titlestring=hi\\|there\\ ft=c ts=4
          # vim:noexpandtab titlestring=hi\\|there\\\\\\ ft=c ts=4
          # vim:ft=coffee ft2=c
        """
        for line in invalid.split /\n/
          expect(grammar.firstLineRegex.scanner.findNextMatchSync(line)).toBeNull()

  describe "C++", ->
    beforeEach ->
      grammar = atom.grammars.grammarForScopeName('source.cpp')

    it "parses the grammar", ->
      expect(grammar).toBeTruthy()
      expect(grammar.scopeName).toBe 'source.cpp'

    it "tokenizes this with `.this` class", ->
      {tokens} = grammar.tokenizeLine 'this.x'
      expect(tokens[0]).toEqual value: 'this', scopes: ['source.cpp', 'variable.language.this.cpp']

    it "tokenizes classes", ->
      lines = grammar.tokenizeLines '''
        class Thing {
          int x;
        }
      '''
      expect(lines[0][0]).toEqual value: 'class', scopes: ['source.cpp', 'meta.class-struct-block.cpp', 'storage.type.cpp']
      expect(lines[0][2]).toEqual value: 'Thing', scopes: ['source.cpp', 'meta.class-struct-block.cpp', 'entity.name.type.cpp']

    it "tokenizes 'extern C'", ->
      lines = grammar.tokenizeLines '''
        extern "C" {
        #include "legacy_C_header.h"
        }
      '''
      expect(lines[0][0]).toEqual value: 'extern', scopes: ['source.cpp', 'meta.extern-block.cpp', 'storage.modifier.cpp']
      expect(lines[0][2]).toEqual value: '"', scopes: ['source.cpp', 'meta.extern-block.cpp', 'string.quoted.double.cpp', 'punctuation.definition.string.begin.cpp']
      expect(lines[0][3]).toEqual value: 'C', scopes: ['source.cpp', 'meta.extern-block.cpp', 'string.quoted.double.cpp']
      expect(lines[0][4]).toEqual value: '"', scopes: ['source.cpp', 'meta.extern-block.cpp', 'string.quoted.double.cpp', 'punctuation.definition.string.end.cpp']
      expect(lines[0][6]).toEqual value: '{', scopes: ['source.cpp', 'meta.extern-block.cpp', 'punctuation.section.block.begin.c']
      expect(lines[1][0]).toEqual value: '#', scopes: ['source.cpp', 'meta.extern-block.cpp', 'meta.preprocessor.include.c', 'keyword.control.directive.include.c', 'punctuation.definition.directive.c']
      expect(lines[1][1]).toEqual value: 'include', scopes: ['source.cpp', 'meta.extern-block.cpp', 'meta.preprocessor.include.c', 'keyword.control.directive.include.c']
      expect(lines[1][3]).toEqual value: '"', scopes: ['source.cpp', 'meta.extern-block.cpp', 'meta.preprocessor.include.c', 'string.quoted.double.include.c', 'punctuation.definition.string.begin.c']
      expect(lines[1][4]).toEqual value: 'legacy_C_header.h', scopes: ['source.cpp', 'meta.extern-block.cpp', 'meta.preprocessor.include.c', 'string.quoted.double.include.c']
      expect(lines[1][5]).toEqual value: '"', scopes: ['source.cpp', 'meta.extern-block.cpp', 'meta.preprocessor.include.c', 'string.quoted.double.include.c', 'punctuation.definition.string.end.c']
      expect(lines[2][0]).toEqual value: '}', scopes: ['source.cpp', 'meta.extern-block.cpp', 'punctuation.section.block.end.c']

      lines = grammar.tokenizeLines '''
        #ifdef __cplusplus
        extern "C" {
        #endif
          // legacy C code here
        #ifdef __cplusplus
        }
        #endif
      '''
      expect(lines[0][0]).toEqual value: '#', scopes: ['source.cpp', 'meta.preprocessor.c', 'keyword.control.directive.conditional.c', 'punctuation.definition.directive.c']
      expect(lines[0][1]).toEqual value: 'ifdef', scopes: ['source.cpp', 'meta.preprocessor.c', 'keyword.control.directive.conditional.c']
      expect(lines[0][2]).toEqual value: ' __cplusplus', scopes: ['source.cpp', 'meta.preprocessor.c']
      expect(lines[1][0]).toEqual value: 'extern', scopes: ['source.cpp', 'meta.extern-block.cpp', 'storage.modifier.cpp']
      expect(lines[1][2]).toEqual value: '"', scopes: ['source.cpp', 'meta.extern-block.cpp', 'string.quoted.double.cpp', 'punctuation.definition.string.begin.cpp']
      expect(lines[1][3]).toEqual value: 'C', scopes: ['source.cpp', 'meta.extern-block.cpp', 'string.quoted.double.cpp']
      expect(lines[1][4]).toEqual value: '"', scopes: ['source.cpp', 'meta.extern-block.cpp', 'string.quoted.double.cpp', 'punctuation.definition.string.end.cpp']
      expect(lines[1][6]).toEqual value: '{', scopes: ['source.cpp', 'meta.extern-block.cpp', 'punctuation.section.block.begin.c']
      expect(lines[2][0]).toEqual value: '#', scopes: ['source.cpp', 'meta.preprocessor.c', 'keyword.control.directive.conditional.c', 'punctuation.definition.directive.c']
      expect(lines[2][1]).toEqual value: 'endif', scopes: ['source.cpp', 'meta.preprocessor.c', 'keyword.control.directive.conditional.c']
      expect(lines[3][1]).toEqual value: '//', scopes: ['source.cpp', 'comment.line.double-slash.cpp', 'punctuation.definition.comment.cpp']
      expect(lines[3][2]).toEqual value: ' legacy C code here', scopes: ['source.cpp', 'comment.line.double-slash.cpp']
      expect(lines[4][0]).toEqual value: '#', scopes: ['source.cpp', 'meta.preprocessor.c', 'keyword.control.directive.conditional.c', 'punctuation.definition.directive.c']
      expect(lines[4][1]).toEqual value: 'ifdef', scopes: ['source.cpp', 'meta.preprocessor.c', 'keyword.control.directive.conditional.c']
      expect(lines[5][0]).toEqual value: '}', scopes: ['source.cpp']
      expect(lines[6][0]).toEqual value: '#', scopes: ['source.cpp', 'meta.preprocessor.c', 'keyword.control.directive.conditional.c', 'punctuation.definition.directive.c']
      expect(lines[6][1]).toEqual value: 'endif', scopes: ['source.cpp', 'meta.preprocessor.c', 'keyword.control.directive.conditional.c']

    it "tokenizes UTF string escapes", ->
      lines = grammar.tokenizeLines '''
        string str = U"\\U01234567\\u0123\\"\\0123\\x123";
      '''
      expect(lines[0][0]).toEqual value: 'string str ', scopes: ['source.cpp']
      expect(lines[0][1]).toEqual value: '=', scopes: ['source.cpp', 'keyword.operator.assignment.c']
      expect(lines[0][3]).toEqual value: 'U', scopes: ['source.cpp', 'string.quoted.double.cpp', 'punctuation.definition.string.begin.cpp', 'meta.encoding.cpp']
      expect(lines[0][4]).toEqual value: '"', scopes: ['source.cpp', 'string.quoted.double.cpp', 'punctuation.definition.string.begin.cpp']
      expect(lines[0][5]).toEqual value: '\\U01234567', scopes: ['source.cpp', 'string.quoted.double.cpp', 'constant.character.escape.cpp']
      expect(lines[0][6]).toEqual value: '\\u0123', scopes: ['source.cpp', 'string.quoted.double.cpp', 'constant.character.escape.cpp']
      expect(lines[0][7]).toEqual value: '\\"', scopes: ['source.cpp', 'string.quoted.double.cpp', 'constant.character.escape.cpp']
      expect(lines[0][8]).toEqual value: '\\012', scopes: ['source.cpp', 'string.quoted.double.cpp', 'constant.character.escape.cpp']
      expect(lines[0][9]).toEqual value: '3', scopes: ['source.cpp', 'string.quoted.double.cpp']
      expect(lines[0][10]).toEqual value: '\\x123', scopes: ['source.cpp', 'string.quoted.double.cpp', 'constant.character.escape.cpp']
      expect(lines[0][11]).toEqual value: '"', scopes: ['source.cpp', 'string.quoted.double.cpp', 'punctuation.definition.string.end.cpp']
      expect(lines[0][12]).toEqual value: ';', scopes: ['source.cpp']

    it "tokenizes raw string literals", ->
      lines = grammar.tokenizeLines '''
        string str = R"test(
          this is \"a\" test 'string'
        )test";
      '''
      expect(lines[0][0]).toEqual value: 'string str ', scopes: ['source.cpp']
      expect(lines[0][3]).toEqual value: 'R"test(', scopes: ['source.cpp', 'string.quoted.double.raw.cpp', 'punctuation.definition.string.begin.cpp']
      expect(lines[1][0]).toEqual value: '  this is "a" test \'string\'', scopes: ['source.cpp', 'string.quoted.double.raw.cpp']
      expect(lines[2][0]).toEqual value: ')test"', scopes: ['source.cpp', 'string.quoted.double.raw.cpp', 'punctuation.definition.string.end.cpp']
      expect(lines[2][1]).toEqual value: ';', scopes: ['source.cpp']

    it "errors on long raw string delimiters", ->
      lines = grammar.tokenizeLines '''
        string str = R"01234567890123456()01234567890123456";
      '''
      expect(lines[0][0]).toEqual value: 'string str ', scopes: ['source.cpp']
      expect(lines[0][3]).toEqual value: 'R"', scopes: ['source.cpp', 'string.quoted.double.raw.cpp', 'punctuation.definition.string.begin.cpp']
      expect(lines[0][4]).toEqual value: '01234567890123456', scopes: ['source.cpp', 'string.quoted.double.raw.cpp', 'punctuation.definition.string.begin.cpp', 'invalid.illegal.delimiter-too-long.cpp']
      expect(lines[0][5]).toEqual value: '(', scopes: ['source.cpp', 'string.quoted.double.raw.cpp', 'punctuation.definition.string.begin.cpp']
      expect(lines[0][6]).toEqual value: ')', scopes: ['source.cpp', 'string.quoted.double.raw.cpp', 'punctuation.definition.string.end.cpp']
      expect(lines[0][7]).toEqual value: '01234567890123456', scopes: ['source.cpp', 'string.quoted.double.raw.cpp', 'punctuation.definition.string.end.cpp', 'invalid.illegal.delimiter-too-long.cpp']
      expect(lines[0][8]).toEqual value: '"', scopes: ['source.cpp', 'string.quoted.double.raw.cpp', 'punctuation.definition.string.end.cpp']
      expect(lines[0][9]).toEqual value: ';', scopes: ['source.cpp']

    it "tokenizes destructors", ->
      {tokens} = grammar.tokenizeLine('~Foo() {}')
      expect(tokens[0]).toEqual value: '~Foo', scopes: ['source.cpp', 'meta.function.destructor.cpp', 'entity.name.function.cpp']
      expect(tokens[1]).toEqual value: '(', scopes: ['source.cpp', 'meta.function.destructor.cpp', 'punctuation.definition.parameters.begin.c']
      expect(tokens[2]).toEqual value: ')', scopes: ['source.cpp', 'meta.function.destructor.cpp', 'punctuation.definition.parameters.end.c']
      expect(tokens[4]).toEqual value: '{', scopes: ['source.cpp', 'meta.block.c', 'punctuation.section.block.begin.c']
      expect(tokens[5]).toEqual value: '}', scopes: ['source.cpp', 'meta.block.c', 'punctuation.section.block.end.c']

      {tokens} = grammar.tokenizeLine('Foo::~Bar() {}')
      expect(tokens[0]).toEqual value: 'Foo::~Bar', scopes: ['source.cpp', 'meta.function.destructor.cpp', 'entity.name.function.cpp']
      expect(tokens[1]).toEqual value: '(', scopes: ['source.cpp', 'meta.function.destructor.cpp', 'punctuation.definition.parameters.begin.c']
      expect(tokens[2]).toEqual value: ')', scopes: ['source.cpp', 'meta.function.destructor.cpp', 'punctuation.definition.parameters.end.c']
      expect(tokens[4]).toEqual value: '{', scopes: ['source.cpp', 'meta.block.c', 'punctuation.section.block.begin.c']
      expect(tokens[5]).toEqual value: '}', scopes: ['source.cpp', 'meta.block.c', 'punctuation.section.block.end.c']

    describe "comments", ->
      it "tokenizes them", ->
        {tokens} = grammar.tokenizeLine '// comment'
        expect(tokens[0]).toEqual value: '//', scopes: ['source.cpp', 'comment.line.double-slash.cpp', 'punctuation.definition.comment.cpp']
        expect(tokens[1]).toEqual value: ' comment', scopes: ['source.cpp', 'comment.line.double-slash.cpp']

        lines = grammar.tokenizeLines '''
          // separated\\
          comment
        '''
        expect(lines[0][0]).toEqual value: '//', scopes: ['source.cpp', 'comment.line.double-slash.cpp', 'punctuation.definition.comment.cpp']
        expect(lines[0][1]).toEqual value: ' separated', scopes: ['source.cpp', 'comment.line.double-slash.cpp']
        expect(lines[0][2]).toEqual value: '\\', scopes: ['source.cpp', 'comment.line.double-slash.cpp', 'constant.character.escape.line-continuation.c']
        expect(lines[1][0]).toEqual value: 'comment', scopes: ['source.cpp', 'comment.line.double-slash.cpp']

    describe "firstLineMatch", ->
      it "recognises Emacs modelines", ->
        valid = """
          #-*- C++ -*-
          #-*- mode: C++ -*-
          /* -*-c++-*- */
          // -*- C++ -*-
          /* -*- mode:C++ -*- */
          // -*- font:bar;mode:C++ -*-
          // -*- font:bar;mode:C++;foo:bar; -*-
          // -*-font:mode;mode:C++-*-
          // -*- foo:bar mode: c++ bar:baz -*-
          " -*-foo:bar;mode:c++;bar:foo-*- ";
          " -*-font-mode:foo;mode:c++;foo-bar:quux-*-"
          "-*-font:x;foo:bar; mode : c++; bar:foo;foooooo:baaaaar;fo:ba;-*-";
          "-*- font:x;foo : bar ; mode : C++ ; bar : foo ; foooooo:baaaaar;fo:ba-*-";
        """
        for line in valid.split /\n/
          expect(grammar.firstLineRegex.scanner.findNextMatchSync(line)).not.toBeNull()

        invalid = """
          /* --*c++-*- */
          /* -*-- c++ -*-
          /* -*- -- C++ -*-
          /* -*- C++C -;- -*-
          // -*- iC++ -*-
          // -*- C++; -*-
          // -*- c++-stuff -*-
          /* -*- model:c++ -*-
          /* -*- indent-mode:c++ -*-
          // -*- font:mode;C++ -*-
          // -*- mode: -*- C++
          // -*- mode: complex-c++ -*-
          // -*-font:mode;mode:c++--*-
        """
        for line in invalid.split /\n/
          expect(grammar.firstLineRegex.scanner.findNextMatchSync(line)).toBeNull()

      it "recognises Vim modelines", ->
        valid = """
          vim: se filetype=cpp:
          # vim: se ft=cpp:
          # vim: set ft=Cpp:
          # vim: set filetype=CPP:
          # vim: ft=CPP
          # vim: syntax=Cpp
          # vim: se syntax=CPP:
          # ex: syntax=CPP
          # vim:ft=cpP
          # vim600: ft=cPp
          # vim>600: set ft=CpP:
          # vi:noai:sw=3 ts=6 ft=cPP
          # vi::::::::::noai:::::::::::: ft=cPp
          # vim:ts=4:sts=4:sw=4:noexpandtab:ft=cpp
          # vi:: noai : : : : sw   =3 ts   =6 ft  =cpp
          # vim: ts=4: pi sts=4: ft=cpp: noexpandtab: sw=4:
          # vim: ts=4 sts=4: ft=cpp noexpandtab:
          # vim:noexpandtab sts=4 ft=cpp ts=4
          # vim:noexpandtab:ft=cpp
          # vim:ts=4:sts=4 ft=cpp:noexpandtab:\x20
          # vim:noexpandtab titlestring=hi\|there\\\\ ft=cpp ts=4
        """
        for line in valid.split /\n/
          expect(grammar.firstLineRegex.scanner.findNextMatchSync(line)).not.toBeNull()

        invalid = """
          ex: se filetype=cpp:
          _vi: se filetype=cpp:
           vi: se filetype=cpp
          # vim set ft=c
          # vim: soft=cpp
          # vim: hairy-syntax=cpp:
          # vim set ft=cpp:
          # vim: setft=cpp:
          # vim: se ft=cpp backupdir=tmp
          # vim: set ft=cpp set cmdheight=1
          # vim:noexpandtab sts:4 ft:cpp ts:4
          # vim:noexpandtab titlestring=hi\\|there\\ ft=cpp ts=4
          # vim:noexpandtab titlestring=hi\\|there\\\\\\ ft=cpp ts=4
          # vim:ft=coffee ft2=cpp
        """
        for line in invalid.split /\n/
          expect(grammar.firstLineRegex.scanner.findNextMatchSync(line)).toBeNull()
