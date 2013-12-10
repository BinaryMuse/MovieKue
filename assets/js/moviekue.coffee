app = angular.module "moviekue", []

app.value 'firebaseUrl', 'https://moviekue.firebaseio.com/'

app.config ($routeProvider, $locationProvider) ->
  $locationProvider.html5Mode(true)
  $routeProvider.when "/",
    controller: "IndexController"
    templateUrl: "/home.htm"
  $routeProvider.when "/movie/:id",
    controller: "MovieController"
    templateUrl: "/movie.htm"
    resolve:
      movie: ($route, MovieDB) ->
        MovieDB.get("/movie/#{$route.current.params.id}?append_to_response=trailers,similar_movies,casts")
  $routeProvider.when "/collection/:id",
    controller: "CollectionController"
    templateUrl: "/collection.htm"
    resolve:
      collection: ($route, MovieDB) ->
        MovieDB.get("/collection/#{$route.current.params.id}")
  $routeProvider.when "/profile/:id",
    controller: "ProfileController"
    templateUrl: "/profile.htm"
    resolve:
      profile: ($route, MovieDB) ->
        MovieDB.get("/person/#{$route.current.params.id}?append_to_response=credits")
  $routeProvider.when "/search/*query",
    controller: "SearchResultsController"
    templateUrl: "/search.htm"
    resolve:
      movieSearch: ($route, MovieDB) ->
        MovieDB.get("/search/movie?query=#{$route.current.params.query}")
      collectionSearch: ($route, MovieDB) ->
        MovieDB.get("/search/collection?query=#{$route.current.params.query}")
      personSearch: ($route, MovieDB) ->
        MovieDB.get("/search/person?query=#{$route.current.params.query}")
  $routeProvider.when "/kue",
    controller: "KueController"
    templateUrl: "/kue.htm"
  $routeProvider.otherwise
    controller: "RoutingController"
    templateUrl: "/error.htm"

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

app.controller "RoutingController", ($scope) ->
  $scope.$on '$routeChangeStart', ->
    $scope.routingProgress = true

  $scope.$on '$routeChangeError', ->
    $scope.routingError = true
    $scope.routingProgress = false

  $scope.$on '$routeChangeSuccess', ->
    $scope.routingError = false
    $scope.routingProgress = false

app.controller "AuthController", ($scope, currentUser) ->
  $scope.user = currentUser

  $scope.login = -> currentUser.loginGithub()
  $scope.logout = -> currentUser.logout()

app.controller "IndexController", ($scope, homepageSections) ->
  $scope.sections = homepageSections

app.controller "AddController", ($scope, movieList) ->
  $scope.movieList = movieList

app.controller "MovieController", ($scope, $rootScope, movie, MovieDB) ->
  $scope.movie = movie.data

  $rootScope.$broadcast 'setFullPageImage', MovieDB.backdropImage($scope.movie.backdrop_path)
  $scope.$on '$destroy', ->
    $rootScope.$broadcast 'removeFullPageImage'

app.controller "CollectionController", ($scope, $rootScope, collection, MovieDB) ->
  $scope.collection = collection.data

  if $scope.collection.backdrop_path
    $rootScope.$broadcast 'setFullPageImage', MovieDB.backdropImage($scope.collection.backdrop_path)
  $scope.$on '$destroy', ->
    $rootScope.$broadcast 'removeFullPageImage'

app.controller "ProfileController", ($scope, $rootScope, profile) ->
  $scope.profile = profile.data

  $rootScope.$broadcast 'setFullPageImage', null
  $scope.$on '$destroy', ->
    $rootScope.$broadcast 'removeFullPageImage'

app.controller "FullPageController", ($scope) ->
  $scope.$on 'setFullPageImage', (evt, value) ->
    $scope.image = value
  $scope.$on 'removeFullPageImage', ->
    $scope.image = null

app.controller "SearchController", ($scope, $location) ->
  $scope.search = ->
    $location.url("/search/#{$scope.query}")

app.controller "SearchResultsController", ($scope, $routeParams, movieSearch, collectionSearch, personSearch) ->
  $scope.query = $routeParams.query
  $scope.movieSearch = movieSearch.data
  $scope.collectionSearch = collectionSearch.data
  $scope.personSearch = personSearch.data

  $scope.noResults = ->
    $scope.movieSearch.results.length == 0 &&
      $scope.collectionSearch.results.length == 0 &&
      $scope.personSearch.results.length == 0

app.controller "KueController", ($scope, currentUser) ->
  $scope.user = currentUser

  $scope.remove = (item) ->
    index = currentUser.list.indexOf(item)
    if index != -1
      currentUser.list.splice(index, 1)
      currentUser.flush()
      return

  $scope.clearList = ->
    currentUser.list = []
    currentUser.flush()

app.directive 'mkBackgroundImage', ($route, $rootScope) ->
  link: (scope, elem, attrs) ->
    handler = ->
      firstRoute = true
      value = scope[attrs.mkBackgroundImage]

      if $route.current == undefined && firstRoute
        elem.css('background-image': "none")
      else if value
        elem.css('background-image': "url(#{value})")
        firstRoute = false
      else
        elem.css('background-image': 'url(/img/curtain-bg.jpg)')
        firstRoute = false

    scope.$watch attrs.mkBackgroundImage, handler
    scope.$on '$routeChangeSuccess', handler

app.directive 'mkCutoff', ->
  scope:
    max: '=mkCutoff'
    text: '=mkCutoffText'
  template: "<span ng-bind-html-unsafe='truncatedText()'></span> <a class='small' ng-click='more()' ng-hide='!truncated'>show more</a>"
  link: (scope, elem, attrs) ->
    scope.truncated = true

    scope.truncatedText = ->
      if scope.truncated && scope.text
        scope.text.substr(0, scope.max) + "..."
      else if scope.text
        scope.text
      else
        ""

    scope.more = ->
      scope.truncated = false

    scope.$watch 'text', (value) ->
      return unless value?
      if value.length < scope.max
        scope.truncated = false

app.directive 'mkAddButton', ->
  template: "<img src='/img/add.png'>"
  link: (scope, elem, attrs) ->
    elem.addClass('add-button')

for type in ['posterImage', 'profileImage', 'backdropImage']
  do (type) ->
    app.filter type, (MovieDB) ->
      (img) -> MovieDB[type](img)

app.filter 'nl2br', ->
  (str) ->
    str?.replace(/\n/g, "<br>\n")

app.filter 'slugify', ->
  (str) ->
    return str unless str
    str = str.replace(/^\s+|\s+$/g, "").toLowerCase()
    from = "àáäâèéëêìíïîòóöôùúüûñç·/_,:;"
    to   = "aaaaeeeeiiiioooouuuunc------"
    for i in [i..from.length]
      str = str.replace(new RegExp(from.charAt(i), "g"), to.charAt(i))
    str.replace(/[^a-z0-9 -]/g, "").replace(/\s+/g, "-").replace(/-+/g, "-")
