app = angular.module "moviekue", []

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
  $routeProvider.otherwise
    controller: "RoutingController"
    templateUrl: "/error.htm"

app.controller "RoutingController", ($scope) ->
  $scope.$on '$routeChangeStart', ->
    $scope.routingProgress = true

  $scope.$on '$routeChangeError', ->
    $scope.routingError = true
    $scope.routingProgress = false

  $scope.$on '$routeChangeSuccess', ->
    $scope.routingError = false
    $scope.routingProgress = false

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

app.factory 'homepageSections', (MovieDB) ->
  sections =
    popular:
      title: "Popular Now"
      url: "/movie/popular"
    top_rated:
      title: "Top Rated"
      url: "/movie/top_rated"
    now_playing:
      title: "In Theaters"
      url: "/movie/now_playing"

  for key, section of sections
    do (section) ->
      section.movies = []
      MovieDB.get(section.url).success (data) ->
        angular.copy(data.results, section.movies)

  sections

app.controller "IndexController", ($scope, homepageSections) ->
  $scope.sections = homepageSections

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

app.controller "SearchResultsController", ($scope, movieSearch, collectionSearch, personSearch) ->
  $scope.movieSearch = movieSearch.data
  $scope.collectionSearch = collectionSearch.data
  $scope.personSearch = personSearch.data

  $scope.noResults = ->
    $scope.movieSearch.results.length == 0 &&
      $scope.collectionSearch.results.length == 0 &&
      $scope.personSearch.results.length == 0

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
  template: "<span>{{truncatedText()}}<a class='small' ng-click='more()' ng-hide='!truncated'>show more</a></span>"
  link: (scope, elem, attrs) ->
    scope.truncated = true

    scope.truncatedText = ->
      if scope.truncated && scope.text
        scope.text.substr(0, scope.max) + "... "
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

for type in ['posterImage', 'profileImage', 'backdropImage']
  do (type) ->
    app.filter type, (MovieDB) ->
      (img) -> MovieDB[type](img)

app.filter 'slugify', ->
  (str) ->
    return str unless str
    str = str.replace(/^\s+|\s+$/g, "").toLowerCase()
    from = "àáäâèéëêìíïîòóöôùúüûñç·/_,:;"
    to   = "aaaaeeeeiiiioooouuuunc------"
    for i in [i..from.length]
      str = str.replace(new RegExp(from.charAt(i), "g"), to.charAt(i))
    str.replace(/[^a-z0-9 -]/g, "").replace(/\s+/g, "-").replace(/-+/g, "-")
