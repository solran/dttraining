class Stimulus
  constructor: (@type, key) ->
    @key = key.toUpperCase()

  clone: ->
    new Stimulus(@type, @key)

class StimulusView
  constructor: (@stimulus) ->
    @html = $('<div>').addClass('stimulus').addClass(@stimulus.type)

class Trial
  constructor: (@stimuli...) ->
    @keys = @stimuli.map (stimulus) -> stimulus.key

class TrialView
  constructor: (@trial) ->
    @html = $('<div>').addClass('trial')
    stim = @trial.stimuli[Math.floor(Math.random() * @trial.stimuli.length)].clone()
    view = new StimulusView(stim)
    @html.html(view.html)

    $(window).on 'keydown', (event) =>
      key = String.fromCharCode(event.which)
      
      if key in @trial.keys
        if key == stim.key
          @html.html('Success')
        else
          @html.html('BOOOHHH!')

class Block
  constructor: (@n, @trials...) ->

class BlockView
  @loadingTime = 200
  @loadingIcon = '*'

  constructor: (@block) ->
    @html = $('<div>').addClass('block')
    @curr = 0

    $(window).on 'click', (event) =>
      @next()

  next: ->
    if @curr++ < @block.n
      @html.html(BlockView.loadingIcon)

      $(window).off 'keydown'
      
      setTimeout =>
          @html.html('')
          @showTrial()
        , BlockView.loadingTime

    else
      console.log 'End!'

  showTrial: ->
    for t in @block.trials
      view = new TrialView(t)
      @html.append(view.html)

block = new Block(
  10,
  new Trial(
    new Stimulus('square', 'j'),
    new Stimulus('circle', 'k')
  ),
  new Trial(
    new Stimulus('sun', 's'),
    new Stimulus('moon', 'd')
  )
)

new BlockView(block).html.appendTo($('body'))