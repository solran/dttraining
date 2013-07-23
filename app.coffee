class Instruction
  constructor: (@text, @timeout = 1000) ->

class Button
  constructor:(@type, @text) ->

class ButtonView
  constructor: (@buttons) ->
    @elem = $('<div>').addClass('button')
    for button, i in @buttons
      @elem.append($('<div>').addClass('button').addClass(button.type).html(button.text).css('width', 100 / @buttons.length + '%').css('left', (100/@buttons.length)*i + '%'))

class InstructionView
  constructor: (@instruction) ->
    @elem = $('<div>').addClass('instruction').html(@instruction.text)
    if @instruction.timeout =='click'
      $(window).off('click').on 'click', (event) =>
        $(@).trigger "instruction.completed"
    else if @instruction.timeout >0
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
  constructor: (@trial) ->
    @stimulus   = @trial.stimuli[Math.floor(Math.random() * @trial.stimuli.length)]
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

class AttemptView
  constructor: (@attempt) ->
    @elem = $('<div>').addClass('attempt').css('width', 100 / @attempt.trial.stimuli.length + '%')
    view = new StimulusView(@attempt.stimulus)
    @elem.html(view.elem)
    @attempt.startedOn = Date.now()

    $(window).on 'keydown', (event) =>
      key = String.fromCharCode(event.which)
      
      if key in @attempt.trial.keys
        if !@attempt.completed()
          @attempt.answer(key)
          if @attempt.success
            @elem.html('Success')
          else
            @elem.html('BOOOHHH!')

class Trial
  constructor: (@stimuli...) ->
    @keys = @stimuli.map (stimulus) -> stimulus.key

class Block
  constructor: (@id, @instructions, @n, @timeLimit, @trials...) ->
    @collection = []
    @buttons = []
    keys = []

    for n in [0...@n]
      @collection[n] = []

      for trial in @trials
        @collection[n].push(new Attempt(trial))
        for key in trial.keys
          keys.push(key) if $.inArray(key, keys) == -1

    @buttons = (new Button("buttonA", key, keys[key]) for key in keys)

#unused
  completed: ->
    for attempts in @collection
      for attempt in attempts
        return false unless attempt.completed()

    true

class BlockView
  @loadingIcon = new Instruction("*", 200)
  @lateMessage = new Instruction("Too late!", 1000)
  @inTimeMessage = new Instruction("In Time!", 1000)
  
  constructor: (@block) ->
    @elem = $('<div>').addClass('block')
    @curr = 0
    @currInst = 0
    @start()     
  
  completed: ->
    for attempt in @block.collection[@curr]
      return false unless attempt.completed()

    true

  start: =>    
    if @currInst<@block.instructions.length
      view = new InstructionView(@block.instructions[@currInst])
      @elem.html(view.elem)
      @currInst++
      $(view).on "instruction.completed", @start
    else
      @next()


  next: =>
    $(window).off 'keydown'
    if @curr < @block.n
      view = new InstructionView(BlockView.loadingIcon)
      $(view).on 'instruction.completed', (event) =>
        view2 = new ButtonView(@block.buttons)
        $("body").append(view2.elem) 
        @show()
      @elem.html(view.elem)
    else
      $(window).off 'click'
      $(@).trigger "block.completed"

  show: =>
    $(window).off 'click'
    if @block.timeLimit == 'unlimited'
      @clickOn()
    else if @block.timeLimit>0
      @timerOn()
    @elem.html('')
    for attempt in @block.collection[@curr]
      view = new AttemptView(attempt)
      @elem.append(view.elem)

  clickOn:=>
    $(window).on 'click', (event) =>
      if @completed()
        @curr++
        @next()

  timerOn:=> 
    setTimeout =>
      if !@completed()
        view = new InstructionView(BlockView.lateMessage)
      else 
        view = new InstructionView(BlockView.inTimeMessage)
      @elem.html(view.elem)
      $(view).on 'instruction.completed', (event) =>
        @curr++
        @next()
    , @block.timeLimit    

class App
  constructor: (@blocks...) ->
    @curr = 0

  next: ->
    if block = @blocks[@curr]
      view = new BlockView(block)
      $("body").html(view.elem)
      $(view).on "block.completed", @switch
    else
      console.log "app.completed"

  switch: =>
    @curr++
    @next()



# program configuration

block1 = new Block(
  "Block1",
  [
    new Instruction("Welcome to the block 1", 2000),
    new Instruction("Explication 1", 'click'),
    new Instruction("Explication 2", 'click')
  ],
  2,
  3000,
  new Trial(
    new Stimulus('square', 'j'),
    new Stimulus('circle', 'k')
  ),
  new Trial(
    new Stimulus('sun', 'j'),
    new Stimulus('moon', 'd')
  )
)

block2 = new Block(
  "Block2",
  [
    new Instruction("Welcome to the block 2", 2000),
    new Instruction("Explication 3", 'click'),
    new Instruction("Explication 4", 'click')
  ],
  2,
  'unlimited',
  new Trial(
    new Stimulus('square', 'j'),
    new Stimulus('circle', 'k')
  ),
  new Trial(
    new Stimulus('sun', 's'),
    new Stimulus('moon', 'd')
  )
)

new App(block1, block2).next()
