Blaze.Template.prototype.createPolyModel = ( args ) ->
  template = @



  polymodel = new PolyModel template, args

  # _.forEach args, ( val, key) ->
  #   polymodel.setValue polymodel, key, val


  return polymodel

Blaze.Template.prototype.polymodel = ->
  # this: Blaze Template
  template  = @
  args      = arguments


  template.onCreated ->
    #this: Blaze Template Instance
    @polymodel = template.createPolyModel.apply( @, args )

  template.onRendered ->
    #this: Blaze Template Instance
    @polymodel.setWatch @

  template.onDestroyed ->
    #this: Blaze Template Instance
    console.log("TEMPLATE DESTROYED", this)
    @polymodel.destroy @

    # Blaze.Template.prototype.polymodel = ->
    #   # this: Blaze Template
    #   args      = arguments
    #   console.log("this 1", this)
    #   @onCreated ->
    #     #this: Blaze Template Instance

    #     console.log("this 2", this)
    #     this.polymodel = @createPolyModel.apply( this, args )

    #   @onRendered ->
    #     @polymodel.setWatch @

    #   @onDestroyed ->
    #     console.log("TEMPLATE DESTROYED")
    #     @polymodel.destroy @


