app = angular.module "moviekue"

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
