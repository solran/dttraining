window.Button = class Button
  constructor:(@key) ->

window.ButtonView = class ButtonView
  constructor: (@button, @options) ->
    @elem = $('<div>').addClass('button').addClass(button.key).html(button.key).css(@options)

window.Instruction = class Instruction
  constructor: (@text, @timeout = 1000) ->

window.InstructionView = class InstructionView
  constructor: (@instruction) ->
    @elem = $('<div>').addClass('instruction').html(@instruction.text)
    
    if @instruction.timeout == 'click'
      $(window).off('click').on 'click', (event) =>
        $(@).trigger "instruction.completed"
    
    if @instruction.timeout > 0
      setTimeout =>
        $(@).trigger "instruction.completed"
      , @instruction.timeout       

window.Stimulus = class Stimulus
  constructor: (@type, key) ->
    @key = key.toUpperCase()

window.StimulusView = class StimulusView
  constructor: (@stimulus) ->
    @elem = $('<div>').addClass('stimulus').addClass(@stimulus.type)

window.Attempt = class Attempt
  constructor: (@stimulus, @trial, options = {}) ->
    @success    = null
    @response   = null
    @startedOn  = null
    @answeredOn = null

  completed: ->
    !!@response

  reactionTime: ->
    @answeredOn - @startedOn

  answer: (key) ->
    @response   = key
    @success    = @stimulus.key == key
    @answeredOn = Date.now()

window.AttemptView = class AttemptView
  constructor: (@attempt) ->
    @elem = $('<div>').addClass('attempt').css('width', 100 / @attempt.trial.stimuli.length + '%')
    attempt_view = new StimulusView(@attempt.stimulus)
    @elem.html(attempt_view.elem)
    @attempt.startedOn = Date.now()

    $(window).on 'keydown', (event) =>
      key = String.fromCharCode(event.which)
      
      if key in @attempt.trial.keys
        unless @attempt.completed()
          @attempt.answer(key)
          
          if @attempt.success
            @elem.html('Success')
          else
            @elem.html('BOOOHHH!')

window.Trial = class Trial
  constructor: (@stimuli...) ->
    @keys = @stimuli.map (stimulus) -> stimulus.key

window.Block = class Block

  constructor: (@instructions, @trials, options = {}) ->
    @id = options['id'] || 'Block'
    @time_limit = options['time_limit'] || 'unlimited'
    @number_of_attempts = options['number_of_attempts'] || 30
    @pourcentageSingleMixedTrial = (options['pourcentageSingleMixedTrial'] || 50) / 100
    @attempt_collection = []
    @buttons = []

    @build_attempt_collection()
    @consoleAllStimulus()

  build_attempt_collection: ->
    uniq_attempts = @number_of_attempts * @pourcentageSingleMixedTrial
    raw_attempts_per_trial = uniq_attempts / @trials.length
    attempts_per_trial = Math.round(raw_attempts_per_trial)
    number_of_MM_attempts = @number_of_attempts - (attempts_per_trial * @trials.length)

    for trial, h in @trials
      attempts_per_MM_stimulus = Math.round(number_of_MM_attempts / trial.stimuli.length)
      attempts_per_SM_stimulus = Math.round(attempts_per_trial / trial.stimuli.length)
      for stimulus, i in trial.stimuli
        @pushAttempts(stimulus, trial, attempts_per_MM_stimulus, i * attempts_per_MM_stimulus, number_of_MM_attempts)
        @pushAttempts(stimulus, trial, attempts_per_SM_stimulus, number_of_MM_attempts + (i * attempts_per_SM_stimulus) + (h * attempts_per_trial), @number_of_attempts)    
      for key in trial.keys
        unless (@buttons.some (button) -> button.key == key)
          @buttons.push(new Button(key))

  pushAttempts: (stimulus, trial, attemps_per_stimulus, minimum, maximum)->
    for j in [minimum...minimum + attemps_per_stimulus]
      break if j >= maximum
      @attempt_collection[j] ?= []
      @attempt_collection[j].push(new Attempt(stimulus, trial))

  consoleAllStimulus: ->
    for attempt, i in @attempt_collection
      for trial, j in attempt 
        console.log i, j, trial.stimulus.type
    
window.BlockView = class BlockView
  @loadingIcon = new Instruction("*", 200)
  @lateMessage = new Instruction("Too late!")
  @inTimeMessage = new Instruction("In Time!")
  
  constructor: (@block) ->
    @elem = $('<div>').addClass('block')
    @current_block = 0
    @current_instruction = 0
    
    @start()

  completed: ->
    #console.log @block.attempt_collection[@current_block]
    for attempt in @block.attempt_collection[@current_block]
      return false unless attempt.completed()

    true

  start: =>    
    if @current_instruction < @block.instructions.length
      view = new InstructionView(@block.instructions[@current_instruction])
      $(view).on "instruction.completed", @start
      @current_instruction++
      @elem.html(view.elem)
    else
      @next()

  next: =>
    $(window).off 'keydown'
    
    if @current_block < @block.number_of_attempts
      view = new InstructionView(BlockView.loadingIcon)
      $(view).on 'instruction.completed', (event) =>
        @addButtons()
        @show()
      @elem.html(view.elem)
    else
      $(window).off 'click'
      $(@).trigger "block.completed"

  show: =>
    $(window).off 'click'
    
    if @block.time_limit == 'unlimited'
      @clickOn()
    else if @block.time_limit > 0
      @timerOn()
    
    @elem.html('')
    
    for attempt in @block.attempt_collection[@current_block]
      view = new AttemptView(attempt)
      @elem.append(view.elem)

  addButtons: => 
    view = $('<div>').addClass('buttons')
    for button, i in @block.buttons
      view.append(new ButtonView(button, {width: 100 / @block.buttons.length + "%", left: 100 / @block.buttons.length * i + "%"}).elem)
    $("body").append(view) 

  clickOn: =>
    $(window).on 'click', (event) =>
      if @completed()
        @current_block++
        @next()

  timerOn: => 
    setTimeout =>
      view = if @completed()
        new InstructionView(BlockView.inTimeMessage)
      else
        new InstructionView(BlockView.lateMessage)

      @elem.html(view.elem)
      
      $(view).on 'instruction.completed', (event) =>
        @current_block++
        @next()
    , @block.time_limit    

window.App = class App
  constructor: (@blocks...) ->
    @current_block = 0

  next: ->
    if block = @blocks[@current_block]
      block_view = new BlockView(block)
      $("body").html(block_view.elem)
      $(block_view).on "block.completed", @switch
    else
      console.log "app.completed"

  switch: =>
    @current_block++
    @next()
