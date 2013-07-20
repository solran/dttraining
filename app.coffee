class Instruction
  constructor: (@text, @timeout = 1000) ->

class InstructionView
  constructor: (@instruction) ->
    @elem = $('<div>').addClass('instruction').html(@instruction.text)

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
        @attempt.answer(key)

        if @attempt.success
          @elem.html('Success')
        else
          @elem.html('BOOOHHH!')

class Trial
  constructor: (@stimuli...) ->
    @keys = @stimuli.map (stimulus) -> stimulus.key

class Block
  constructor: (@id, @n, @trials...) ->
    @collection = []

    for n in [0...@n]
      @collection[n] = []

      for trial in @trials
        @collection[n].push(new Attempt(trial))

  completed: ->
    for attempts in @collection
      for attempt in attempts
        return false unless attempt.completed()

    true

class BlockView
  @loadingIcon = new Instruction("*", 200)
  
  constructor: (@block) ->
    @elem = $('<div>').addClass('block')
    @inst = new Instruction("Welcome to #{@block.id}!")
    @curr = 0
    
    @start()

    $(window).on 'click', (event) =>
      if @completed()
        @curr++
        @next()
  
  completed: ->
    for attempt in @block.collection[@curr]
      return false unless attempt.completed()

    true

  start: =>
    view = new InstructionView(@inst)
    $(view).on "instruction.completed", @next
    @elem.html(view.elem)

  next: =>
    $(window).off 'keydown'

    if @curr < @block.n
      view = new InstructionView(BlockView.loadingIcon)
      $(view).on 'instruction.completed', @show
      @elem.html(view.elem)

    else
      $(window).off 'click'
      $(@).trigger "block.completed"

  show: =>
    @elem.html('')
    for attempt in @block.collection[@curr]
      view = new AttemptView(attempt)
      @elem.append(view.elem)

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
  2,
  new Trial(
    new Stimulus('square', 'j'),
    new Stimulus('circle', 'k')
  ),
  new Trial(
    new Stimulus('sun', 's'),
    new Stimulus('moon', 'd')
  )
)

block2 = new Block(
  "Block2",
  2,
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
