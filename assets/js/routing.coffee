app = angular.module "moviekue"

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
