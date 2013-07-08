class @Viewporter
  
  constructor: (@element_id, @params = {}) ->
    window.viewporter = @
    @initialized = false
    @element = null
    
    @loggingLevel = 0
    
    @isAndroid = navigator.userAgent.match(/Android/i)
    @isIphone = navigator.userAgent.match(/iPhone/i) || navigator.userAgent.match(/iPod/i)
    @isIpad = navigator.userAgent.match(/iPad/i)
    @isChrome = navigator.userAgent.match(/Chrome/i) || navigator.userAgent.match(/CriOS/i)
    @isFirefox = navigator.userAgent.match(/Firefox/i)
    
    @pixelRatio = 1
    if window.devicePixelRatio
      @pixelRatio = window.devicePixelRatio
    
    @previousScreenSize = width: 0, height: 0
    @viewportChanged = false
    @viewportWidth = 320
    @viewportHeight = 480
    @lastViewportWidth = @viewportWidth
    @lastViewportHeight = @viewportHeight
    @lastLandscape = @isLandscape = true
    @lastAnnounce =
      viewportWidth: -1
      viewportHeight: -1
      isLandscape: -1
    
    @fullWidthLandscape = true
    @fullHeightLandscape = true
    @fullWidthPortrait = true
    @fullHeightPortrait = true
    
    @interval = 200
    
    ww = @windowWidth()
    wh = @windowHeight()
    
    if ww < wh
      @windowInnerWidth = ww/@pixelRatio
      @windowInnerHeight = wh/@pixelRatio
    else
      @windowInnerWidth = wh/@pixelRatio
      @windowInnerHeight = ww/@pixelRatio
    
    @resolutionsSeen = []
    
    window.addEventListener "ondeviceorientation", @orientationChanged
    window.addEventListener "deviceorientation", @orientationChanged
    window.addEventListener "orientationchange", @orientationChanged
    window.addEventListener "visibilitychange", @orientationChanged
    
    window.addEventListener "resize", (event) =>
      @trace "resize " + @windowHeight(), 2
      if @isIphone or @isAndroid or @isIpad
        @resetViewportIfChanged()
      else
        @trace "not iphone or android, so just resize", 2
        @calculateWindowSize()
        @setupViewport()
    
    if @params? and typeof @params == "object"
      for prop, val of @params
        @[prop] = val
    
    window.addEventListener "load", =>
      @trace "ON LOAD! ", 2
      @init()
      @lastAnnounce.viewportWidth = -1
      @announceChange()
    
    @hideAddressBar()
    window.addEventListener "load", () =>
      setTimeout =>
        @hideAddressBar()
      , 0
      setTimeout =>
        @hideAddressBar()
      , 10
    
    @init()
    @calculateWindowSize()
    @setupViewport()
    @announceChange()
    setTimeout () =>
      @init()
    , 1
  
  init: =>
    if @element_id? and document.getElementById(@element_id)?
      @element = document.getElementById(@element_id)
    
    @trace "Initializing?", 2
    unless @initialized or (@element_id? and !@element?)
      @trace "INITIALIZING", 2
      @hideAddressBar()
      if @isIphone
        setTimeout () =>
          @monitorSize()
        , @interval
    
      setTimeout () =>
        @calculateWindowSize()
        @setupViewport()
        setTimeout @hideAddressBar, 1
      , 10
      
      @initialized = true
      @calculateWindowSize()
      @setupViewport()
      @announceChange()
  
  monitorSize: (event) =>
    @trace "monitorSize", 2
    @resetViewportIfChanged()
    setTimeout () =>
      @monitorSize()
    , @interval
  
  orientationChanged: (event) =>
    if window.orientation?
      lnd = if Math.abs(window.orientation) == 90 then true else false
      if lnd == @isLandscape
        return
    _type = if event?.type? and event.type then event.type else ""
    @trace "orientationchange #{_type}: ", 2
    if @isFirefox
      return @resetViewportIfChanged()
    if @element?.style?
      @element.style.display = "block"
    @calculateWindowSize()
    @setupViewport()
    @announceChange()
  
  resetViewportIfChanged: () =>
    @trace "resetViewportIfChanged", 2
    if @isLandscape
      @calculateWindowSize()
      if @actualScreenWidth != @previousScreenSize.width or @actualScreenHeight != @previousScreenSize.height
        @trace "RESIZE detected.. " + @previousScreenSize.height + " => " + @actualScreenHeight, 2
        @setupViewport()
        @previousScreenSize.width = @actualScreenWidth
        @previousScreenSize.height = @actualScreenHeight
        setTimeout () =>
          @setupViewport()
        , 300
  
  calculateWindowSize: () ->
    #@viewportWidth = 320
    #@viewportHeight = 480
    #@viewportScale = 1
    wasLandscape = @isLandscape
    
    @isLandscape = true
    if window.orientation?
      @isLandscape = if Math.abs(window.orientation) == 90 then true else false
      #@trace "Orientation: #{window.orientation}", 2
    else
      @isLandscape = window.innerWidth > window.innerHeight
    
    @actualScreenWidth = @orientedWidth()
    @actualScreenHeight = @orientedHeight()
    
    #@trace "@oriented : "+@orientedWidth()+"x"+@orientedHeight()+" @ "+@pixelRatio, 2
    #@trace "window.inner : "+window.innerWidth+"x"+window.innerHeight, 2
    
    sw = @screenWidth()
    sh = @screenHeight()
    
    statusBarHeight = 10
    navBarHeight = 44
    addressBarHeight = 60
    
    if @isIphone
      lowerHeight = if @isChrome then 256 else 268
      upperHeight = 320
      upperHeightWithBar = 260
      
      if @isLandscape
        if @actualScreenHeight <= lowerHeight && @actualScreenHeight != upperHeightWithBar
          #@trace "BUMP " + @actualScreenHeight + " -> 268", 2
          @actualScreenHeight = lowerHeight
      else
        if @actualScreenHeight == 444
          @actualScreenHeight += addressBarHeight
      
      if @actualScreenHeight >= upperHeightWithBar && @actualScreenHeight != lowerHeight && @actualScreenHeight < upperHeight
        #@trace "BUMP " + @actualScreenHeight + " -> 320", 2
        @actualScreenHeight = upperHeight
    
    found = false
    for i in [0..@resolutionsSeen.length]
      if i < @resolutionsSeen.length
        if @resolutionsSeen[i]?.width == @actualScreenWidth && @resolutionsSeen[i].height == @actualScreenHeight
          found = true
    
    if !@isLandscape
      #@viewportScale = 1
      if @isIphone
        @actualScreenHeight += 0 #statusBarHeight + navBarHeight
    
    if !found
      @resolutionsSeen.push {width: @actualScreenWidth, height: @actualScreenHeight}
    
    if typeof window.orientation == "undefined" and !@isIphone and !@isAndroid
      @actualScreenWidth = @windowWidth()
      @actualScreenHeight = @windowHeight()
    if @isFirefox
      @actualScreenWidth = @windowWidth()
      @actualScreenHeight = @windowHeight()
    
    #document.getElementById("tmp").innerHTML = "#{@actualScreenWidth}x#{@actualScreenHeight} / #{Date.now()}"
    
    if !@isFirefox
      @actualScreenHeight += 1
    
    @viewportChanged = false
    if @viewportWidth != @actualScreenWidth or @viewportHeight != @actualScreenHeight or wasLandscape != @isLandscape
      @viewportChanged = true
    
    @viewportWidth = @actualScreenWidth
    @viewportHeight = @actualScreenHeight
    #@viewportScale = @actualScreenWidth/@viewportWidth
    
    #@trace "Calculated: #{@actualScreenWidth} x #{@actualScreenHeight}", 2
  
  setupViewport: () =>
    if !@initialized and @element
      @init()
    viewport = document.querySelector "meta[name=viewport]"
    
    #@viewportHeight = 3000
    #@trace(@viewportWidth+"x"+@viewportHeight+" @ "+@viewportScale), 2
    @trace "#{screen.width}x#{screen.height} / #{@viewportWidth}x#{@viewportHeight}", 2
    h = (@viewportHeight - Math.random()*.0001)
    w = @viewportWidth
    s = 1 - Math.random()*.00001
    if @isAndroid and @isChrome
      h = @viewportHeight + 0
      w = @viewportWidth + 0
    
    viewportProperties = []
    viewportProperties.push "initial-scale=" + s
    viewportProperties.push "minimum-scale=" + s
    viewportProperties.push "maximum-scale=" + s
    viewportProperties.push "user-scalable=no"
    
    body = document.getElementsByTagName "body"
    
    setWidth = (@isLandscape and @fullWidthLandscape) or (!@isLandscape and @fullWidthPortrait)
    setHeight = (@isLandscape and @fullHeightLandscape) or (!@isLandscape and @fullHeightPortrait)
    
    if setWidth
      viewportProperties.push "width=" + w
      if @element?.style?
        @element.style.width = @viewportWidth + "px"
        @element.style["overflow-x"] = "hidden"
      if body?[0]?.style?
        body[0].style.width = @viewportWidth + "px"
    else
      if @element?.style?
        @element.style.width = ""
        @element.style["overflow-x"] = "auto"
      if body?[0]?.style?
        body[0].style.width = ""
    
    if setHeight
      viewportProperties.push "height=" + h
      if @element?.style?
        @element.style.height = @viewportHeight + "px"
        @element.style["overflow-y"] = "hidden"
      if body?[0]?.style?
        body[0].style.height = @viewportHeight + "px"
    else
      if @element?.style?
        @element.style.height = ""
        @element.style["overflow-y"] = "auto"
      if body?[0]?.style?
        body[0].style.height = "inherit"
    
    viewportContent = viewportProperties.join ", "
    
    if @element?.style?
      setTimeout () =>
        @element.style.display = "block"
      , 100
    
    if body?.getAttribute?
      classString = body.getAttribute("class") or ""
      classes = classString.split " "
      newClasses = []
    
      for className in classes
        if className != "portrait-mode" and className != "landscape-mode"
          newClasses.push className
    
      if @isLandscape
        newClasses.push "landscape-mode"
      else
        newClasses.push "portrait-mode"
      body.setAttribute "class", newClasses.join(" ")
    
    #@trace viewportContent, 2
    
    ###
    if !@isAndroid or !@isChrome
      if !@isIphone
        viewport.setAttribute "content", "width = device-width, height = device-height, initial-scale = 1, minimum-scale = 1, maximum-scale = 1, user-scalable = no"
    ###
    
    setTimeout () =>
      if @isFirefox
        #viewport.setAttribute "content", "width = device-width, height = device-height, initial-scale = 1, minimum-scale = 1, maximum-scale = 1, user-scalable = no"
        #document.getElementById("tmp").innerHTML = document.body.clientWidth
        
        viewport.setAttribute "content", viewportContent
      else
        viewport.setAttribute "content", viewportContent
    , 10
    
    if @viewportChanged and @lastViewportWidth == @viewportWidth and @lastViewportHeight == @viewportHeight and @lastLandscape == @isLandscape
      @viewportChanged = false
    
    if @viewportChanged
      setTimeout @hideAddressBar, 1
      @announceChange()
  
  announceChange: =>
    @trace "announceChange: #{window.innerWidth}", 2
    if @lastAnnounce.viewportWidth == @viewportWidth and @lastAnnounce.viewportHeight == @viewportHeight and @lastAnnounce.isLandscape == @isLandscape
      @trace "NO REPEAT", 2
    else
      @trace "now: #{@viewportWidth}x#{@viewportHeight} / #{@isLandscape}", 2
      event = document.createEvent "Event"
      event.initEvent "viewportchanged", true, true
      event.width = @viewportWidth
      event.height = @viewportHeight
      event.isLandscape = @isLandscape
      @lastViewportWidth = @viewportWidth
      @lastViewportHeight = @viewportHeight
      @lastLandscape = @isLandscape
      window.dispatchEvent event
      @lastAnnounce = 
        viewportWidth: @viewportWidth
        viewportHeight: @viewportHeight
        isLandscape: @isLandscape
  
  option: (key, val) ->
    sizeRestrictions = ["fullWidthLandscape", "fullHeightLandscape", "fullWidthPortrait", "fullHeightPortrait"]
    if sizeRestrictions.indexOf key > -1
      @[key] = if val == true then true else false
    
    @lastViewportWidth = 0
    @lastViewportHeight = 0
    @viewportChanged = true
    @setupViewport()
  
  screenRatio: () ->
    ratio = 1
    if @pixelRatio > 1
      sw = screen.width
      sh = screen.height
      ww = @windowWidth()
      wh = @windowHeight()
      if ww * @pixelRatio == sw or wh * @pixelRatio == sw or ww * @pixelRatio == sh or wh * @pixelRatio == sh
        ratio = @pixelRatio
    ratio
  
  orientedWidth: () ->
    w = if @isLandscape then @screenHeight() else @screenWidth()
    Math.round w
  
  orientedHeight: () ->
    if @isIphone or @isChrome or @isIpad
      windowRatio = if @windowWidth() > @windowHeight() then @windowWidth() / @windowHeight() else @windowHeight() / @windowWidth()
      h = @orientedWidth() * (if @isLandscape then 1 / windowRatio else windowRatio)
    else
      h = if @isLandscape then @screenWidth() else @screenHeight()
    Math.round h
  
  screenWidth: () ->
    sw = if screen.width < screen.height then screen.width else screen.height
    sw/@screenRatio()
  
  screenHeight: () ->
    sh = if screen.width < screen.height then screen.height else screen.width
    sh/@screenRatio()
  
  windowWidth: () ->
    s = 1
    if @isFirefox and document.documentElement
      s = window.innerWidth / document.documentElement.clientWidth
    window.innerWidth / s
  
  windowHeight: () ->
    s = 1
    if @isFirefox and document.documentElement
      s = window.innerWidth / document.documentElement.clientWidth
    window.innerHeight / s
  
  hideAddressBar: () ->
    window.scrollTo 0, 0
    setTimeout () ->
      window.scrollTo 0, 1
    , 100
  
  trace: (str, level) =>
    if !@backlog
      @backlog = []
    
    log = document.getElementById "log"
    
    if @loggingLevel > 0
      if console?.log?
        console.log str
      if level <= @loggingLevel
        if log?
          log.innerHTML = str + "<br />\n" + log.innerHTML
          if log.innerHTML.length > 2000
            log.innerHTML = log.innerHTML.substring 0, 2000
    
    if log?.innerHTML?
      while @backlog.length > 0
        
        @trace @backlog.shift(), level
    else
      @backlog.push str





