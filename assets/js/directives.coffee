app = angular.module "moviekue"

app.directive 'mkBackgroundImage', ($route) ->
  link: (scope, elem, attrs) ->
    handler = ->
      firstRoute = true
      value = scope.$eval(attrs.mkBackgroundImage)

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
