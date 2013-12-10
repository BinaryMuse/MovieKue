app = angular.module "moviekue"

app.factory 'MovieDB', ($http) ->
  cache = {}
  posterImage: (img) ->
    if img
      "http://d3gtl9l2a4fn1j.cloudfront.net/t/p/w154#{img}"
    else
      "/img/anon-movie.jpg"

  backdropImage: (img) ->
    if img
      "http://d3gtl9l2a4fn1j.cloudfront.net/t/p/w1280#{img}"
    else
      ""

  profileImage: (img) ->
    if img
      "http://d3gtl9l2a4fn1j.cloudfront.net/t/p/w185#{img}"
    else
      "/img/anon.png"

  get: (url) ->
    url = "/moviedb#{url}"
    if cache[url]
      cache[url]
    else
      cache[url] = $http.get(url)

app.factory 'MovieDBPager', (MovieDB, $q) ->
  class MovieDBPager
    constructor: (@url, @perPage, @maxPages = 20) ->
      throw new Error("You must specify a perPage option") unless @perPage?

      @ready = false
      @_requests =
        1: @_makeRequest(1)
      @_pages = {}
      @_items = {}

      @currentPageNum = 1
      @totalPages = null
      @eachPage = null

      @_init()

    page: (page) =>
      return @_pages[page] if @_pages[page]?
      @_pages[page] = []

      @_metadata().then (metadata) =>
        itemStartIndex = @perPage * (page - 1)
        itemEndIndex = itemStartIndex + @perPage - 1

        requestStartIndex = Math.floor(itemStartIndex / metadata.perRequest) + 1
        requestEndIndex = Math.floor(itemEndIndex / metadata.perRequest) + 1
        requests = (@_request(i) for i in [requestStartIndex..requestEndIndex])
        $q.all(requests).then =>
          items = (@_item(i) for i in [itemStartIndex..itemEndIndex])
          angular.copy(items, @_pages[page])

      @_pages[page]

    currentPage: =>
      @page(@currentPageNum)

    nextPage: =>
      return if @currentPageNum == @totalPages
      @changePage(@currentPageNum + 1)

    previousPage: =>
      return if @currentPageNum == 1
      @changePage(@currentPageNum - 1)

    changePage: (page) =>
      @currentPageNum = page

    _init: =>
      @_metadata().then (metadata) =>
        totalPages = Math.floor(metadata.totalItems / @perPage)
        @totalPages = Math.min(totalPages, @maxPages)
        @eachPage = [1..@totalPages]
        @ready = true

    _request: (num) =>
      @_requests[num] ?= @_makeRequest(num)

    _makeRequest: (num) =>
      MovieDB.get(@url.replace("PAGENUM", num))

    _item: (index) =>
      return @_items[index] if @_items[index]
      d = $q.defer()
      @_metadata().then (metadata) =>
        request = Math.floor(index / metadata.perRequest)
        position = index % metadata.perRequest
        @_request(request + 1).success (data) =>
          d.resolve(data.results[position])
      @_items[index] = d.promise

    _metadata: =>
      return @_metadataPromise if @_metadataPromise?
      d = $q.defer()
      @_request(1).success (data) ->
        result =
          perRequest: data.results.length
          totalRequests: data.total_pages
          totalItems: data.total_results
        d.resolve(result)
      @_request(1).error (data) -> d.reject(data)
      @_metadataPromise = d.promise

app.factory 'homepageSections', (MovieDBPager) ->
  sections =
    popular:
      title: "Popular Now"
      url: "/movie/popular?page=PAGENUM"
    top_rated:
      title: "Top Rated"
      url: "/movie/top_rated?page=PAGENUM"
    now_playing:
      title: "In Theaters"
      url: "/movie/now_playing?page=PAGENUM"

  for key, section of sections
    section.pager = new MovieDBPager(section.url, 6)

  sections

app.factory 'currentUser', ($timeout, firebaseUrl) ->
  class User
    constructor: ->
      @ref = new Firebase(firebaseUrl)
      @auth = new FirebaseSimpleLogin(@ref, @_handleLoginStateChange)
      @myRef = null
      @loggedIn = undefined
      @userData = null
      @list = null

    _handleLoginStateChange: (error, user) =>
      $timeout (=>
        if user
          @_onLogin(user)
        else if error
          @_onLogout()
        else
          @_onLogout()
      ), 0

    loginGithub: =>
      @auth.login('github')

    logout: =>
      @auth.logout()

    flush: =>
      return unless @loggedIn
      @myRef.update(data: JSON.stringify(@list))

    _onLogout: =>
      @loggedIn = false
      @userData = null
      @myRef?.child('data')?.off('value', @_onDataChange)
      @myRef = null
      @list = []
      @username = ""

    _onLogin: (user) =>
      @loggedIn = true
      @userData = user
      @username = user.displayName || user.username || user.email

      myKey = "lists/#{@userData.provider}-#{@userData.id}"
      @myRef = @ref.child(myKey)
      @myRef.update(login_provider: @userData.provider, login_id: @userData.id)
      @myRef.child('data').on('value', @_onDataChange)

    _onDataChange: (snapshot) =>
      $timeout (=>
        json = snapshot.val()
        if json?
          @list = JSON.parse(json) || [] # in case of persisted "null"
        else
          @list = []
          @myRef.update(data: '[]')
      ), 0

  new User()

app.factory 'movieList', (currentUser) ->
  add: (type, item, $event) ->
    return unless currentUser.loggedIn
    if $event?
      $event.cancelBubble = true
      $event.stopPropagation() if $event.stopPropagation
    itemDetails =
      backdrop_path: item.backdrop_path
      id: item.id
      imdb_id: item.imdb_id
      poster_path: item.poster_path
      title: item.title || item.name # movie = title, collection = name
      tagline: item.tagline
    currentUser.list.push(key: "#{type}-#{item.id}", type: type, item: itemDetails)
    currentUser.flush()

  inList: (type, item) ->
    list = currentUser.list || []
    for listItem in list
      return true if listItem.type == type && listItem.item.id == item.id
    false

  canAdd: (type, item) ->
    currentUser.list != null && !@inList(type, item)

app.factory 'backgroundImage', ->
  class BackgroundImage
    constructor: ->
      @url = null

    set: (img) =>
      @url = img

    remove: =>
      @set(null)

  new BackgroundImage
