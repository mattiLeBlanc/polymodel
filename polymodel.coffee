class PolyModel

  elements: []
  listners: []

  constructor: ( template, args ) ->
    self = @


    _.forEach args, ( val, key) ->

      newKey  = Object.keys( val )[0]
      newVal  = val[ newKey ]
      temp    = {}
      # adding to temp.__proto__[ newKey ] = newVal is not allowed. Don't know why
      temp[ "__#{newKey}" ] = newVal

      self.setValue self, key, temp

      # self.setValue self, key, val

    # retrieve model attributes (data-model) from the Blaze template
    # self.elements =
    # debugger
    self.setRootProtoValue( 'elements', self.deepSearch( template.view.templateInstance().view._render() ) )



    # sort element so that we can group them
    self.elements.sort()


    # create reactive variables for model elements
    prevPath    = null
    prevPrimary = null
    varObject   = null

    self.elements.forEach ( el, x ) ->
      path      = el.split('.')
      primary   = path.shift()


      # if path is empty, create the single layer var
      if !path.length
        template[ primary ] = new ReactiveVar null
      else

        # we are in the same object
        if primary is prevPrimary

          self.setValue( varObject, path.join('.'), null )

          # last iteration, write result
          if x is self.elements.length-1

            self[ prevPrimary ]     = varObject
            template[ prevPrimary ] = new ReactiveVar varObject
        # we go t a new object
        else
          # if there was already an object (prev one), store it
          if varObject
            self[ prevPrimary ]     =  varObject
            template[ prevPrimary ] = new ReactiveVar varObject

          varObject   = {}
          prevPrimary = primary

          self.setValue( varObject, path.join('.'), null )

          # last iteration, write result
          if x is self.elements.length-1
            self[ primary ]     = varObject
            template[ primary ] = new ReactiveVar varObject

    if args and args.created and _.isFunction args.created
      args.created.apply( this )

  ###
    @description Set watch on all dom elements that have the data-model attribute
    @params templateInstance | template instance | required
  ###
  setWatch: ( templateInstance ) ->
    self = @

    if !(templateInstance instanceof Blaze.TemplateInstance)
      throw new Meteor.Error( 'Polymodel SetWatch requires the Blaze TemplateInstance it\'s related to, passed in as argument' )

    # create selector for dom elements
    domElements = _.map self.elements, ( val ) ->
      return "[data-model='#{val}']";

    # get all dom elements with newly created selector
    domElements = templateInstance.$( domElements.join(',') )

    # because Polymer offers it's own events, we will setup listners for the elements
    domElements.each ( index, el ) ->

      path        = this.dataset.model.split( '.')
      primary     = path.shift()
      tempObject  = templateInstance[ primary ].get()
      preset      = self.getValue( tempObject, path.join( '.' ) )

      # instead of checking for element type, we try to test based on Polymer value selectors

      # all Polymer radio or checkbox elements have a selected attribute
      if el.selected isnt undefined

        eventType = 'core-select'

        if preset
          this.selected = preset
          self.setValue self, "#{this.dataset.model}.value", preset

        listner = ( e ) ->

          temp = templateInstance[ primary ].get()
          # if temp is not an object (excluding null which is an object), we do not have to traverse it but set the value directly
          if _.isNull( temp ) or _.isString( temp )
            temp = this.value
          else
            # traverse set the value
            self.setValue temp, path.join( '.' ), this.selected

          # update the path in the Polymodel
          self.setValue self, "#{this.dataset.model}.value", this.selected

          # and update the path in the templateInstance
          templateInstance[ primary ].set( temp )

        el.addEventListener eventType, listner , false


      # regular input elements
      else if el.value isnt undefined

        # check if there is a custom trigger for this field
        trigger     = self.getValue self, "#{this.dataset.model}.__trigger"
        # set custom trigger, else revert to keyup as default
        eventType   = if trigger then trigger else 'keyup'

        if preset
          this.value = preset
          self.setValue self, "#{this.dataset.model}.value", preset

        listner = ( e ) ->

          temp = templateInstance[ primary ].get()
          # if temp is not an object (excluding null which is an object), we do not have to traverse it but set the value directly
          if _.isNull( temp ) or _.isString( temp )
            temp = this.value
          else
            # traverse set the value
            self.setValue temp, path.join( '.' ), this.value

          # update the path in the Polymodel
          self.setValue self, "#{this.dataset.model}.value", this.value

          # and update the path in the templateInstance
          templateInstance[ primary ].set( temp )

        el.addEventListener eventType, listner , false

        # regiser listner in our model
        newListners = self.listners
        newListners.push
          element:    el
          eventType:  eventType
          listner:    listner

        self.setRootProtoValue( 'listners', newListners)



  setValue: ( obj, path, value ) ->
    aPath = path.split('.')
    key = aPath.shift()
    prevKey = undefined


    while key
      if !obj[key]
        obj[key] = {}
      prevKey = key
      key = aPath.shift()
      if key
        obj = obj[prevKey]
    obj[prevKey] = value
    return

  getValue: ( obj, path, forceArray ) ->
    if typeof path == 'undefined' or !obj
      return
    aPath = path.split('.')
    value = obj
    key = aPath.shift()
    while typeof value != 'undefined' and value != null and key
      value = value[key]
      key = aPath.shift()
    value = if 0 == aPath.length then value else undefined
    if !$.isArray(value) and typeof value != 'undefined' and forceArray
      value = [ value ]
    value

  ###
    @description Search through Blaze prerendered template structure for data-model attributes
    Requires the render result of a templateInstance.
    Example:  this.view.templateInstance().view._render()  //-> results in Array of object(s),
              where this is a Blaze template instance
    @param object | Blaze TemplateInstance View | Required
    @param array | collections of retrieved model elements | optional

    @returns array of model elements
  ###
  deepSearch: ( obj, modelFields ) ->
    self = @

    # our collection of model fieldnames
    if !(modelFields instanceof Array)
      modelFields = []

    if obj instanceof Array
      _.forEach obj, ( node, key ) ->
        return self.deepSearch( node, modelFields )

    else

      if obj
         # HTMLTag
        if obj.tagName
          # check attributes
          if obj.attrs and obj.attrs[ 'data-model' ]
            # find data-model attributes
            modelFields.push( obj.attrs[ 'data-model' ] )

          # check children
          if obj.children
            return self.deepSearch( obj.children, modelFields )
        # Blaze View?
        else
          if typeof obj is 'object'
            if obj.name
              # Lookup is a Spacebar evaluation. Skip this
              if obj.name.match( /^lookup/ )
                return modelFields
              # when we find an IF statement we have to execute 2 searches: one for a TRUE condition and one for a false
              # NOTE: currently supporting IF ELSE only
              else if obj.name is 'if'
                #true condition
                obj.__conditionVar.set( true )
                trueElements = obj._render()

                if !(trueElements instanceof Array)
                  trueElements = [ trueElements ]

                obj.__conditionVar.set( false )
                falseElements = obj._render()

                if !(falseElements instanceof Array)
                  falseElements = [ falseElements ]

                elements = trueElements.concat falseElements
                return self.deepSearch( elements, modelFields )
              # assume there is a _render function
              else
                elements = obj._render()
                return self.deepSearch( elements, modelFields )
            else
              return modelFields
          else
            return modelFields
      else
        return modelFields
    return modelFields

  destroy: ( templateInstance ) ->
    self = @

    if !(templateInstance instanceof Blaze.TemplateInstance)
      throw new Meteor.Error( 'Polymodel destroy requires the Blaze TemplateInstance it\'s related to, passed in as argument' )

    # unbind all events
    self.listners.forEach ( listner, idx ) ->
      listner.element.removeEventListener( listner.eventType, listner.listner )
    self.setRootProtoValue( 'listners', [] )

    # remove polymodel object
    delete templateInstance.polymodel

    return true

  setRootProtoValue: ( name, value) ->
    this.__proto__[ name ] = value


  setProtoValue: ( source, name, value) ->
    source.__proto__[ name ] = value



  get: ( path ) ->
    # remove __trigger value when we export
    result = this.getValue this, path
    result = JSON.stringify( result )
    result = result.replace( /"__trigger":"[^"]*",/g, '' )

    # replace the value key and place its value directly under key name
    regex = /({"value":")([^"]*)("})/g
    result = result.replace( regex, '"$2"')
    result = JSON.parse( result )

