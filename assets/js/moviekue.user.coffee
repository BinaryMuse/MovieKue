mod = angular.module 'moviekue.user', []


mod.controller "AuthController", ($scope, currentUser) ->
  $scope.user = currentUser

  $scope.login = -> currentUser.loginGithub()
  $scope.logout = -> currentUser.logout()


mod.factory 'currentUser', ($timeout, firebaseUrl) ->
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
