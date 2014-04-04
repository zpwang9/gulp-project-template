path       = require 'path'
gulp       = require 'gulp'
gutil      = require 'gulp-util'
jade       = require 'gulp-jade'
stylus     = require 'gulp-stylus'
CSSmin     = require 'gulp-minify-css'
browserify = require 'browserify'
watchify   = require 'watchify'
source     = require 'vinyl-source-stream'
streamify  = require 'gulp-streamify'
rename     = require 'gulp-rename'
uglify     = require 'gulp-uglify'
coffeeify  = require 'coffeeify'
nodeStatic = require 'node-static'
lr         = require 'tiny-lr'
livereload = require 'gulp-livereload'
plumber    = require 'gulp-plumber'
prefix     = require 'gulp-autoprefixer'
reloadServer = lr()

compileCoffee = (debug = false) ->

  bundle = watchify('./src/coffee/main.coffee')

  rebundle = ->

    build = bundle.bundle(debug: debug)
      .pipe(source('bundle.js'))

    build.pipe(streamify(uglify())) unless debug

    build
      .pipe(gulp.dest('./public/js/'))
      .pipe(livereload(reloadServer))

  bundle.on 'update', rebundle

  rebundle()

compileJade = (debug = false) ->
  gulp
    .src('src/jade/*.jade')
    .pipe(jade(pretty: debug))
    .pipe(gulp.dest('public/'))
    .pipe livereload(reloadServer)

compileStylus = (debug = false) ->
  styles = gulp
    .src('src/stylus/style.styl')
    .pipe(stylus({set: ['include css']}))
    .pipe(prefix("last 1 version", "> 1%", "ie 8"))

  styles.pipe(CSSmin()) unless debug

  styles.pipe(gulp.dest('public/css/'))
    .pipe livereload reloadServer

copyAssets = (debug = false) ->
  gulp
    .src('src/assets/**/*.*')
    .pipe gulp.dest 'public/'

# Build tasks
gulp.task "jade-production", -> compileJade()
gulp.task 'stylus-production', ->compileStylus()
gulp.task 'coffee-production', -> compileCoffee()
gulp.task 'assets-production', -> copyAssets()

# Development tasks
gulp.task "jade", -> compileJade(true)
gulp.task 'stylus', -> compileStylus(true)
gulp.task 'coffee', -> compileCoffee(true)
gulp.task 'assets', -> copyAssets(true)

gulp.task "server", ->
  staticFiles = new nodeStatic.Server './public'
  require('http').createServer (req, res) ->
    req.addListener 'end', ->
      staticFiles.serve req, res
    req.resume()
  .listen 9001

gulp.task "watch", ->
  reloadServer.listen 35729, (err) ->
    console.error err if err?

    gulp.watch "src/jade/*.jade", ["jade"]
    gulp.watch "src/stylus/*.styl", ["stylus"]
    gulp.watch "src/assets/**/*.*", ["assets"]

gulp.task "build", ["coffee-production", "jade-production", "stylus-production", "assets-production"]
gulp.task "default", ["coffee", "jade", "stylus", "assets", "watch", "server"]
