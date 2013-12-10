app = angular.module "moviekue"

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

app.controller "MovieController", ($scope, backgroundImage, movie, MovieDB) ->
  $scope.movie = movie.data

  backgroundImage.set MovieDB.backdropImage($scope.movie.backdrop_path)
  $scope.$on '$destroy', ->
    backgroundImage.remove()

app.controller "CollectionController", ($scope, backgroundImage, collection, MovieDB) ->
  $scope.collection = collection.data

  if $scope.collection.backdrop_path
    backgroundImage.set MovieDB.backdropImage($scope.collection.backdrop_path)
  $scope.$on '$destroy', ->
    backgroundImage.remove()

app.controller "ProfileController", ($scope, backgroundImage, profile) ->
  $scope.profile = profile.data
  backgroundImage.remove()

app.controller "FullPageController", ($scope, backgroundImage) ->
  $scope.backgroundImage = backgroundImage

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
