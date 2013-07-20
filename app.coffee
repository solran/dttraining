class EventManager
  @events = {}

  @trigger: (instance, event) ->
    if @events[instance]
      if @events[instance][event]
        for callback in @events[instance][event]
          callback()

  @on: (instance, event, callback) ->
    @events[instance] ?= {}
    @events[instance][event] ?= []
    @events[instance][event].push callback

class Instruction
  constructor: (@text) ->

class InstructionView
  constructor: (@instruction) ->
    @elem = $('<div>').addClass('instruction').html(@instruction.text)

    $(window).on 'click', (event) =>
      console.log "Tata"
      $(window).off 'click'
      EventManager.trigger @, "completed"

class Stimulus
  constructor: (@type, key) ->
    @key = key.toUpperCase()

  # clone n'est pas utilisé
  clone: ->
    new Stimulus(@type, @key)

class StimulusView
  constructor: (@stimulus) ->
    @elem = $('<div>').addClass('stimulus').addClass(@stimulus.type)

class Attempt
  constructor: (@trial) ->
    @stimulus = @trial.stimuli[Math.floor(Math.random() * @trial.stimuli.length)]
    @success  = null
    @response = null
    @timeOn   = null
    @reactionTime = null

  completed: ->
    !!@response

  answer: (key) ->
    @response = key
    @success  = @stimulus.key == key
    @reactionTime = Date.now()-@timeOn

class AttemptView
  constructor: (@attempt) ->
    @elem = $('<div>').addClass('attempt')
    view = new StimulusView(@attempt.stimulus)
    @elem.html(view.elem)

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
  constructor: (@n, @trials...) ->
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
  @loadingTime = 200
  @loadingIcon = '*'
  
  constructor: (@block) ->
    @elem = $('<div>').addClass('block')
    @curr = -1
    @next()

    $(window).on 'click', (event) =>
      if @completed()
        @next()
  
  completed: ->
    for attempt in @block.collection[@curr]
      return false unless attempt.completed()

    true
  #start: ->
    #debugger
    #@elem.html(BlockView.welcome.text)
    #@next()

  next: ->
    $(window).off 'keydown'

    if ++@curr < @block.n
      @elem.html(BlockView.loadingIcon)

      setTimeout => 
        @elem.html('')
        @showTrial()
      , BlockView.loadingTime

    else
      $(window).off 'click'
      EventManager.trigger @, "completed"

  showTrial: ->
    for attempt in @block.collection[@curr]
      view = new AttemptView(attempt)
      @elem.append(view.elem)
      attempt.timeOn = Date.now()


class App
  constructor: (@actions...) ->
    @curr = 0

  next: ->
    action = @actions[@curr]

    EventManager.on action, "completed", @switch
    
    if action instanceof Instruction
      view = new InstructionView(action)
      $("body").html(view.elem)

    else if action instanceof Block
      view = new BlockView(action)
      $("body").html(view.elem)

  switch: =>
    @curr++
    @next()

block = new Block(
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

@sessionStart     = new Instruction("Bienvenue dans le programme!")
@blockEnd         = new Instruction("Fin de bloc")
@sessionEnd         = new Instruction("Fin de Session")

new App(sessionStart, block, blockEnd, block).next()