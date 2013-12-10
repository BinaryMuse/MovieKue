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
