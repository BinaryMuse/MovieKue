app = angular.module "moviekue"

for type in ['posterImage', 'profileImage', 'backdropImage']
  do (type) ->
    app.filter type, (MovieDB) ->
      (img) -> MovieDB[type](img)

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
