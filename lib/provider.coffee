docs = require('../docs').docs
docsURL = 'http://bricxcc.sourceforge.net/nbc/nxcdoc/nxcapi/'

module.exports =
  # This will work on JavaScript and CoffeeScript files, but not in js comments.
  selector: '.source.nxc'
  disableForSelector: '.source.nxc .comment'

  # This will take priority over the default provider, which has a priority of 0.
  # `excludeLowerPriority` will suppress any providers with a lower priority
  # i.e. The default provider will be suppressed
  inclusionPriority: 1
  excludeLowerPriority: false

  # Required: Return a promise, an array of suggestions, or null.
  getSuggestions: (request) ->
    suggestions = []

    # we aren't case sensetive
    request.prefix = request.prefix.toLowerCase()

    # grab the item in the docs that match
    for item in docs
      text = item.text.toLowerCase()
      if text.indexOf(request.prefix) > -1
        suggestions.push
          text: item.text
          description: item.info
          descriptionMoreURL: docsURL+item.url
          type: 'function'
          _rank: item.text.length-request.prefix.length

    # sort them so that OnFwd comes before OnFwdReg
    suggestions.sort (a, b) ->
      if a._rank < b._rank
        return -1
      else if a._rank > b._rank
        return 1
      else return 0

    # return the suggestions
    return suggestions
