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
        MovieDB("/movie/#{$route.current.params.id}?append_to_response=trailers,similar_movies,casts")
  $routeProvider.otherwise
    controller: "RoutingController"
    templateUrl: "/error.htm"

app.controller "RoutingController", ($scope) ->
  $scope.$on '$routeChangeError', ->
    $scope.routingError = true
  $scope.$on '$routeChangeSuccess', ->
    $scope.routingError = false

app.factory 'MovieDB', ($http) ->
  cache = {}
  (url) ->
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
      MovieDB(section.url).success (data) ->
        angular.copy(data.results, section.movies)

  sections

app.controller "IndexController", ($scope, homepageSections) ->
  $scope.sections = homepageSections

  $scope.posterImage = (record) ->
    "http://d3gtl9l2a4fn1j.cloudfront.net/t/p/w154#{record.poster_path}"

app.controller "MovieController", ($scope, $rootScope, movie) ->
  $scope.movie = movie.data

  $scope.posterImage = (record) ->
    "http://d3gtl9l2a4fn1j.cloudfront.net/t/p/w154#{record.poster_path}"

  $scope.backdropImage = (record) ->
    "http://d3gtl9l2a4fn1j.cloudfront.net/t/p/w1280#{record.backdrop_path}"

  $scope.profileImage = (record) ->
    if record.profile_path
      "http://d3gtl9l2a4fn1j.cloudfront.net/t/p/w185#{record.profile_path}"
    else
      "/img/anon.png"

  $rootScope.$broadcast 'setFullPageImage', $scope.backdropImage($scope.movie)

  $scope.$on '$destroy', ->
    $rootScope.$broadcast 'removeFullPageImage'

app.controller "FullPageController", ($scope) ->
  $scope.$on 'setFullPageImage', (evt, value) ->
    $scope.image = value
  $scope.$on 'removeFullPageImage', ->
    $scope.image = null

app.directive 'mkBackgroundImage', ->
  link: (scope, elem, attrs) ->
    scope.$watch attrs.mkBackgroundImage, (value) ->
      if value
        elem.css('background-image': "url(#{value})")
        elem.addClass('full-page-background')
      else
        elem.css('background-image': 'none')
        elem.removeClass('full-page-background')

app.filter 'slugify', ->
  (str) ->
    return str unless str
    str = str.replace(/^\s+|\s+$/g, "").toLowerCase() # trim and force lowercase
    from = "àáäâèéëêìíïîòóöôùúüûñç·/_,:;"
    to   = "aaaaeeeeiiiioooouuuunc------"
    for i in [i..from.length]
      str = str.replace(new RegExp(from.charAt(i), "g"), to.charAt(i))
    # remove accents, swap ñ for n, etc
    str = str.replace(/[^a-z0-9 -]/g, "").replace(/\s+/g, "-").replace(/-+/g, "-")
    # remove invalid chars, collapse whitespace and replace by -, collapse dashes
    str # unnecessary line, but for clarity
