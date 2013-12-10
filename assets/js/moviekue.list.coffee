mod = angular.module 'moviekue.list', ['moviekue.user']


mod.controller "AddController", ($scope, movieList) ->
  $scope.movieList = movieList


mod.controller "KueController", ($scope, currentUser, movieList) ->
  $scope.user = currentUser
  $scope.movieList = movieList


mod.factory 'movieList', (currentUser) ->
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

  remove: (item) ->
    index = currentUser.list.indexOf(item)
    if index != -1
      currentUser.list.splice(index, 1)
      currentUser.flush()

  clearList: ->
    currentUser.list = []
    currentUser.flush()

  inList: (type, item) ->
    list = currentUser.list || []
    for listItem in list
      return true if listItem.type == type && listItem.item.id == item.id
    false

  canAdd: (type, item) ->
    currentUser.list != null && !@inList(type, item)
