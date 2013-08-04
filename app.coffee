class Button
  constructor:(@key) ->

class ButtonView
  constructor: (@button, @options) ->
    @elem = $('<div>').addClass('button').addClass(button.key).html(button.key).css(@options)

class Instruction
  constructor: (@text, @timeout = 1000) ->

class InstructionView
  constructor: (@instruction) ->
    @elem = $('<div>').addClass('instruction').html(@instruction.text)
    
    if @instruction.timeout == 'click'
      $(window).off('click').on 'click', (event) =>
        $(@).trigger "instruction.completed"
    
    if @instruction.timeout > 0
      setTimeout =>
        $(@).trigger "instruction.completed"
      , @instruction.timeout       

class Stimulus
  constructor: (@type, key) ->
    @key = key.toUpperCase()

class StimulusView
  constructor: (@stimulus) ->
    @elem = $('<div>').addClass('stimulus').addClass(@stimulus.type)

class Attempt
  constructor: (@stimulus, @trial, @trialPlace, @numberOfTrial) ->
    @success    = null
    @response   = null
    @startedOn  = null
    @answeredOn = null

  assignKey : (key) ->
    if key?
      @key = key.toUpperCase()
    else
      @key = ' '
      @response = ' '

  completed: ->
    !!@response 

  reactionTime: ->
    @answeredOn - @startedOn

  answer: (key) ->
    @response   = key
    @success    = @key == key
    @answeredOn = Date.now()

class AttemptView
  constructor: (@attempt) ->  
    @elem = $('<div>').addClass('attempt').css({left : @attempt.trialPlace/ @attempt.numberOfTrial * 100 + '%', width : 100 / @attempt.numberOfTrial + '%'})
    attemptView = new StimulusView(@attempt.stimulus)
    @elem.html(attemptView.elem)
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

class Trial
  constructor: (@stimuli...) ->
    @keys = @stimuli.map (stimulus) -> stimulus.key

class Block
  constructor: (@instructions, @trials, options = {}) ->
    @id = options['id'] || 'Block'
    @timeLimit = options['timeLimit'] || 'unlimited'
    @numberOfAttempts = options['numberOfAttempts'] || 16
    @pourcentageSingleMixedTrial = (options['pourcentageSingleMixedTrial'] || 0) / 100
    @nBack = (options['nBack'] || -1) 
    @attemptCollection = []
    @buttons = []

    @buildAttemptCollection()
    @doNBack(@nBack)
    @consoleAllStimulus()

  buildAttemptCollection: ->
    uniqAttempts = @numberOfAttempts * @pourcentageSingleMixedTrial
    rawAttemptsPerTrial = uniqAttempts / @trials.length
    attemptsPerTrial = Math.round(rawAttemptsPerTrial)
    numberOfMMattempts = @numberOfAttempts - (attemptsPerTrial * @trials.length)

    for trial, h in @trials
      attemptsPerMMstimulus = Math.round(numberOfMMattempts / trial.stimuli.length)
      attemptsPerSMstimulus = Math.round(attemptsPerTrial / trial.stimuli.length)
      for stimulus, i in trial.stimuli
        @pushAttempts(stimulus, trial, h, attemptsPerMMstimulus, i * attemptsPerMMstimulus, numberOfMMattempts)
        @pushAttempts(stimulus, trial, h, attemptsPerSMstimulus, numberOfMMattempts + (i * attemptsPerSMstimulus) + (h * attemptsPerTrial), numberOfMMattempts + ((h+1) * attemptsPerTrial))    
      for key in trial.keys
        unless (@buttons.some (button) -> button.key == key)
          @buttons.push(new Button(key))

  pushAttempts: (stimulus, trial, trialPlace, attempsPerStimulus, minimum, maximum)->
    for j in [minimum...minimum + attempsPerStimulus]
      break if j >= maximum
      @attemptCollection[j] ?= []
      @attemptCollection[j].push(new Attempt(stimulus, trial, trialPlace, @trials.length))

  doNBack: (nBack)->
    for attempt, i in @attemptCollection
      for trial, j in attempt 
        trial.assignKey(@attemptCollection[i+nBack]?[j].stimulus.key)

  consoleAllStimulus: ->
    for attempt, i in @attemptCollection
      for trial, j in attempt 
        console.log i, j, trial.stimulus.type, trial.stimulus.key, trial.key
    
class BlockView
  @loadingIcon = new Instruction("*", 200)
  @lateMessage = new Instruction("Too late!")
  @inTimeMessage = new Instruction("In Time!")
  @nBackIntro = new Instruction("Remember!")

  
  constructor: (@block) ->
    @elem = $('<div>').addClass('block')
    @currentBlock = 0
    @currentInstruction = 0
    
    @start()

  completed: ->
    #console.log @block.attemptCollection[@currentBlock]
    for attempt in @block.attemptCollection[@currentBlock]
      return false unless attempt.completed()
    if attempt.key == ' '
      return 'nbackIntro'
    true

  start: =>    
    if @currentInstruction < @block.instructions.length
      view = new InstructionView(@block.instructions[@currentInstruction])
      $(view).on "instruction.completed", @start
      @currentInstruction++
      @elem.html(view.elem)
    else
      @next()


  next: =>
    $(window).off 'keydown'
    
    if @currentBlock < @block.numberOfAttempts
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
    
    if @block.timeLimit == 'unlimited'
      @clickOn()
    else if @block.timeLimit > 0
      @timerOn()
    
    @elem.html('')
    
    for attempt in @block.attemptCollection[@currentBlock]
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
        @currentBlock++
        @next()

  timerOn: => 
    setTimeout =>
      view = if @completed() == 'nbackIntro'
        new InstructionView(BlockView.nBackIntro)
      else if @completed()
        new InstructionView(BlockView.inTimeMessage)
      else
        new InstructionView(BlockView.lateMessage)

      @elem.html(view.elem)
      
      $(view).on 'instruction.completed', (event) =>
        @currentBlock++
        @next()
    , @block.timeLimit    

class App
  constructor: (@blocks...) ->
    @currentBlock = 0

  next: ->
    if block = @blocks[@currentBlock]
      blockView = new BlockView(block)
      $("body").html(blockView.elem)
      $(blockView).on "block.completed", @switch
    else
      console.log "app.completed"

  switch: =>
    @currentBlock++
    @next()



# program configuration

block1 = new Block(
  [
    new Instruction("Welcome to the block 1", 2000)
    # new Instruction("Explication 1", 'click'),
    # new Instruction("Explication 2", 'click')
  ],
  [
    new Trial(
      new Stimulus('square', 's'),
      new Stimulus('circle', 'd'),
      #new Stimulus('triangle', 'f'),
      #new Stimulus('rectangle', 'e')
    ),
    new Trial(
      new Stimulus('sun', 'j'),
      new Stimulus('moon', 'k'),
      #new Stimulus('star', 'p'),
      #new Stimulus('galaxy', 'l')
    )
  ]
   {timeLimit : 500}
)

# block2 = new Block(
#   [
#     new Instruction("Welcome to the block 2", 2000)
#     # new Instruction("Explication 3", 'click'),
#     # new Instruction("Explication 4", 'click')
#   ],
#   [
#     new Trial(
#       new Stimulus('square', 'j'),
#       new Stimulus('circle', 'k')
#     ),
#     new Trial(
#       new Stimulus('sun', 's'),
#       new Stimulus('moon', 'd')
#     )
#   ]
# )

new App(block1).next()
