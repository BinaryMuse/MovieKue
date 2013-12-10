MovieKue
========

MovieKue is an AngularJS web application designed to teach AngularJS application design and programming. Eventually a screencast series will cover building the site.

![MovieKue](media/moviekue-ss-dev-place.png)

Installing
----------

 * `npm install`
 * `cp config/config.json.example config/config.json`
 * Edit `config/config.json` to include your [TMDb API key](http://www.themoviedb.org/faq/api)
 * Edit `assets/js/moviekue.coffee` to include your own [Firebase URL](https://www.firebase.com/)
 * (Optional) Load the data from `firebase-rules.json` into your Firebase Security Rules
 * Start the server with `npm start`
