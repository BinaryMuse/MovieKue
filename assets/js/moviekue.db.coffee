mod = angular.module 'moviekue.db', []


mod.controller "IndexController", ($scope, homepageSections) ->
  $scope.sections = homepageSections


mod.controller "MovieController", ($scope, backgroundImage, movie, MovieDB) ->
  $scope.movie = movie.data

  backgroundImage.set MovieDB.backdropImage($scope.movie.backdrop_path)
  $scope.$on '$destroy', ->
    backgroundImage.remove()


mod.controller "CollectionController", ($scope, backgroundImage, collection, MovieDB) ->
  $scope.collection = collection.data

  if $scope.collection.backdrop_path
    backgroundImage.set MovieDB.backdropImage($scope.collection.backdrop_path)
  $scope.$on '$destroy', ->
    backgroundImage.remove()


mod.controller "ProfileController", ($scope, backgroundImage, profile) ->
  $scope.profile = profile.data
  backgroundImage.remove()


mod.controller "SearchResultsController", ($scope, $routeParams, movieSearch, collectionSearch, personSearch) ->
  $scope.query = $routeParams.query
  $scope.movieSearch = movieSearch.data
  $scope.collectionSearch = collectionSearch.data
  $scope.personSearch = personSearch.data

  $scope.noResults = ->
    $scope.movieSearch.results.length == 0 &&
      $scope.collectionSearch.results.length == 0 &&
      $scope.personSearch.results.length == 0


mod.factory 'MovieDB', ($http) ->
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

  getMovie: (movie) ->
    @get "/movie/#{movie}?append_to_response=trailers,similar_movies,casts"

  getCollection: (collection) ->
    @get "/collection/#{collection}"

  getPerson: (person) ->
    @get "/person/#{person}?append_to_response=credits"

  getSearch: (type, query) ->
    @get "/search/#{type}?query=#{query}"


mod.factory 'MovieDBPager', (MovieDB, $q) ->
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


mod.factory 'homepageSections', (MovieDBPager) ->
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


for type in ['posterImage', 'profileImage', 'backdropImage']
  do (type) ->
    mod.filter type, (MovieDB) ->
      (img) -> MovieDB[type](img)
