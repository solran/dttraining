class Stimulus
  constructor: (@type, key) ->
    @key = key.toUpperCase()

  clone: ->
    new Stimulus(@type, @key)

#blha blha blhah

class StimulusView
  constructor: (@stimulus) ->
    @elem = $('<div>').addClass('stimulus').addClass(@stimulus.type)

class Attempt
  constructor: (@trial) ->
    @stimulus = @trial.stimuli[Math.floor(Math.random() * @trial.stimuli.length)]
    @success  = null
    @response = null
    @time     = null

  completed: ->
    @response

  answer: (key) ->
    @response = key
    @success  = @stimulus.key == key

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
        console.log attempt.response
        return false unless attempt.response != null 

    true

class BlockView
  @loadingTime = 200
  @loadingIcon = '*'

  constructor: (@block) ->
    @elem = $('<div>').addClass('block')
    @curr = 0
    @next()
    
 
    $(window).on 'click', (event) =>
      console.log @block.completed()
      if @block.completed()

        @next()
     # @next()

  next: ->
    if @curr < @block.n
      @elem.html(BlockView.loadingIcon)

      $(window).off 'keydown'
      
      setTimeout => 
        @elem.html('')
        @showTrial()
      , BlockView.loadingTime

    else
      console.log 'End!'

  showTrial: ->
    for attempt in @block.collection[@curr]
      view = new AttemptView(attempt)
      @elem.append(view.elem)

    @curr++

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

new BlockView(block).elem.appendTo($('body'))