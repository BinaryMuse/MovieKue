app = angular.module "moviekue", ['moviekue.db', 'moviekue.list', 'moviekue.user']


# Set your Firebase URL here
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
        MovieDB.getMovie($route.current.params.id)

  $routeProvider.when "/collection/:id",
    controller: "CollectionController"
    templateUrl: "/collection.htm"
    resolve:
      collection: ($route, MovieDB) ->
        MovieDB.getCollection($route.current.params.id)

  $routeProvider.when "/profile/:id",
    controller: "ProfileController"
    templateUrl: "/profile.htm"
    resolve:
      profile: ($route, MovieDB) ->
        MovieDB.getPerson($route.current.params.id)

  $routeProvider.when "/search/*query",
    controller: "SearchResultsController"
    templateUrl: "/search.htm"
    resolve:
      movieSearch: ($route, MovieDB) ->
        MovieDB.getSearch 'movie', $route.current.params.query
      collectionSearch: ($route, MovieDB) ->
        MovieDB.getSearch 'collection', $route.current.params.query
      personSearch: ($route, MovieDB) ->
        MovieDB.getSearch 'person', $route.current.params.query

  $routeProvider.when "/kue",
    controller: "KueController"
    templateUrl: "/kue.htm"

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


app.controller "FullPageController", ($scope, backgroundImage) ->
  $scope.backgroundImage = backgroundImage


app.controller "SearchController", ($scope, $location) ->
  $scope.search = ->
    $location.url("/search/#{$scope.query}")


app.factory 'backgroundImage', ->
  class BackgroundImage
    constructor: ->
      @url = null

    set: (img) =>
      @url = img

    remove: =>
      @set(null)

  new BackgroundImage


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


app.directive 'mkBackgroundImage', ($route) ->
  link: (scope, elem, attrs) ->
    firstLoad = true
    handler = ->
      value = scope.$eval(attrs.mkBackgroundImage)

      # Avoid showing the curtain image and then immediately
      # switching to another image on the first route change
      if $route.current == undefined && firstLoad
        console.log '1'
        elem.css('background-image': "none")
      else if value
        console.log '2'
        elem.css('background-image': "url(#{value})")
        firstLoad = false
      else
        console.log '3'
        elem.css('background-image': 'url(/img/curtain-bg.jpg)')
        firstLoad = false

    scope.$watch attrs.mkBackgroundImage, handler
    scope.$on '$routeChangeSuccess', handler
    scope.$on '$routeChangeError', handler


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
