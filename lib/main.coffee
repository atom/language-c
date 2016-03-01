Provider = require './provider'

module.exports =

  config:
    useEnhancedFirmware:
      type: 'boolean'
      default: false

  getProvider: -> Provider

  activate: ->
    atom.commands.add 'atom-workspace',
      'nxc:compile': => @compile()
      'nxc:upload': => @upload()
      'nxc:run': => @run()

  compile: ->
    @nbc 'compile'
  upload: ->
    @nbc 'upload'
  run: ->
    @nbc 'run'

  nbc: (type) ->
    activeItem = atom.workspace.getActivePaneItem()

    # save current file
    activeItem.buffer.save()

    command = ''

    # generate the command to run
    switch process.platform
      when 'linux'
        command += '~/.atom/packages/language-nxc/nbc-linux '
      when 'osx'
        command += '~/.atom/packages/language-nxc/nbc-osx ' # TODO: test if this works
      when 'win32'
        command += '%HOMEPATH%\\.atom\\packages\\language-nxc\\nbc-windows.exe '
      when 'win64'
        command += '%HOMEPATH%\\.atom\\packages\\language-nxc\\nbc-windows.exe '

    command += '-T=NXT -S=usb '
    switch type
      when 'upload'
        command += '-d '
      when 'run'
        command += '-r '

    if atom.config.get 'language-nxc.useEnhancedFirmware'
      command += '-EF '

    command += activeItem.buffer.file.path
    console.debug 'language-nxc: executing command:', command

    filename = activeItem.buffer.file.path.split('.');
    if filename[filename.length-1] != 'nxc'
      atom.notifications.addWarning "not working on an nxc file!"
      return

    require('child_process').exec command, (error, stdcommand, stderr) ->
      # do we have an error?
      if error?
        if stderr != ""
          atom.notifications.addError "You got a bug!",
            icon: 'bug'
            detail: stderr
            dismissable: true
        else
          atom.notifications.addWarning "Robot not connected!",
            detail: "If the robot is connected, please view the trobble " +
                    "shooting tips at https://goo.gl/lWWy0s"
            dismissable: true
      else
          atom.notifications.addSuccess "Sucsesful!"
