describe "C++", ->
  grammar = null
  
  beforeEach ->
    waitsForPromise ->
      atom.packages.activatePackage('language-c')
    runs ->
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
    expect(lines[0][0]).toEqual value: 'string str = ', scopes: ['source.cpp']
    expect(lines[0][1]).toEqual value: 'U', scopes: ['source.cpp', 'string.quoted.double.cpp', 'punctuation.definition.string.begin.cpp', 'meta.encoding.cpp']
    expect(lines[0][2]).toEqual value: '"', scopes: ['source.cpp', 'string.quoted.double.cpp', 'punctuation.definition.string.begin.cpp']
    expect(lines[0][3]).toEqual value: '\\U01234567', scopes: ['source.cpp', 'string.quoted.double.cpp', 'constant.character.escape.cpp']
    expect(lines[0][4]).toEqual value: '\\u0123', scopes: ['source.cpp', 'string.quoted.double.cpp', 'constant.character.escape.cpp']
    expect(lines[0][5]).toEqual value: '\\"', scopes: ['source.cpp', 'string.quoted.double.cpp', 'constant.character.escape.cpp']
    expect(lines[0][6]).toEqual value: '\\012', scopes: ['source.cpp', 'string.quoted.double.cpp', 'constant.character.escape.cpp']
    expect(lines[0][7]).toEqual value: '3', scopes: ['source.cpp', 'string.quoted.double.cpp']
    expect(lines[0][8]).toEqual value: '\\x123', scopes: ['source.cpp', 'string.quoted.double.cpp', 'constant.character.escape.cpp']
    expect(lines[0][9]).toEqual value: '"', scopes: ['source.cpp', 'string.quoted.double.cpp', 'punctuation.definition.string.end.cpp']
    expect(lines[0][10]).toEqual value: ';', scopes: ['source.cpp']

  it "tokenizes raw string literals", ->
    lines = grammar.tokenizeLines '''
      string str = R"test(
        this is \"a\" test 'string'
      )test";
    '''
    expect(lines[0][0]).toEqual value: 'string str = ', scopes: ['source.cpp']
    expect(lines[0][1]).toEqual value: 'R"test(', scopes: ['source.cpp', 'string.quoted.double.raw.cpp', 'punctuation.definition.string.begin.cpp']
    expect(lines[1][0]).toEqual value: '  this is "a" test \'string\'', scopes: ['source.cpp', 'string.quoted.double.raw.cpp']
    expect(lines[2][0]).toEqual value: ')test"', scopes: ['source.cpp', 'string.quoted.double.raw.cpp', 'punctuation.definition.string.end.cpp']
    expect(lines[2][1]).toEqual value: ';', scopes: ['source.cpp']

  it "errors on long raw string delimiters", ->
    lines = grammar.tokenizeLines '''
      string str = R"01234567890123456()01234567890123456";
    '''
    expect(lines[0][0]).toEqual value: 'string str = ', scopes: ['source.cpp']
    expect(lines[0][1]).toEqual value: 'R"', scopes: ['source.cpp', 'string.quoted.double.raw.cpp', 'punctuation.definition.string.begin.cpp']
    expect(lines[0][2]).toEqual value: '01234567890123456', scopes: ['source.cpp', 'string.quoted.double.raw.cpp', 'punctuation.definition.string.begin.cpp', 'invalid.illegal.delimiter-too-long.cpp']
    expect(lines[0][3]).toEqual value: '(', scopes: ['source.cpp', 'string.quoted.double.raw.cpp', 'punctuation.definition.string.begin.cpp']
    expect(lines[0][4]).toEqual value: ')', scopes: ['source.cpp', 'string.quoted.double.raw.cpp', 'punctuation.definition.string.end.cpp']
    expect(lines[0][5]).toEqual value: '01234567890123456', scopes: ['source.cpp', 'string.quoted.double.raw.cpp', 'punctuation.definition.string.end.cpp', 'invalid.illegal.delimiter-too-long.cpp']
    expect(lines[0][6]).toEqual value: '"', scopes: ['source.cpp', 'string.quoted.double.raw.cpp', 'punctuation.definition.string.end.cpp']
    expect(lines[0][7]).toEqual value: ';', scopes: ['source.cpp']

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
      """
      for line in invalid.split /\n/
        expect(grammar.firstLineRegex.scanner.findNextMatchSync(line)).toBeNull()

      # -*- coffee -*- # See atom/language-html#138
