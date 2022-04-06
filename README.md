# AJAX Twitter

Today you will be creating a clone of Twitter called AJAX Twitter. You will
start with a static Twitter clone without JavaScript. Step by step, you'll
replace traditional form submissions with AJAX requests that do not cause a full
page refresh, sprinkling in some extra JavaScript interactivity while you're at
it!

## Learning goals

By the end of today's practice, you should be able to:

- Explain how AJAX requests allow the frontend and backend to communicate
- Submit valid AJAX requests from the frontend in response to user actions
- Respond to AJAX requests with JSON from the backend
- Manipulate the DOM on the frontend after receiving JSON data from the backend
- Implement loading state UI while the server is responding to AJAX requests

## Phase 0: Setup

Clone the project starter. (You can access the starter repo by clicking the
`Download Project` button at the bottom of this page.)

Start by running `bundle install`. To set up the database, run `rails db:setup`,
which creates the database, loads the schema, and runs your seeds file. Finally,
run `npm install` to install `webpack`, `sass`, and related packages for
building your frontend assets.

Run `./bin/dev` in your terminal (if you get an error regarding permissions, run
`chmod +x ./bin/*`). This uses [`foreman`] to run multiple processes in a single
terminal, with output from each accompanied by color-coded labels. The processes
it will run are determined by the file passed to `foreman` in __bin/dev__, which
in this case is __Procfile.dev__:

```text
web: bin/rails server -p 3000
js: npm run build -- --watch
css: npm run build:css -- --watch
```

Here you can see three processes will run: the Rails server and the `build`
(webpack) and `build:css` (sass) scripts defined in `package.json`. Hit `^c`
(CTRL-c) to end all three processes and exit `foreman`.

### Debugging

A drawback of `foreman` is that you cannot use the same terminal to debug with
`debug` or `byebug`. Instead, you'll need to create a remote debugging session;
you can then connect to this remote session from a different terminal, where
you'll get your typical `debug`/`byebug` console / REPL.

Below are instructions to set this up for `debug` and `byebug`--pick whichever
you prefer.

#### Option A: `debug`

Change the first line of __Procfile.dev__ from:

```text
web: bin/rails server -p 3000
```

to:

```text
web: rdbg --open --nonstop -c -- bin/rails server -p 3000
```

Let's break this down:

- `rdbg -c -- <cmd>` -- run `<cmd>` in debugging mode (lets you hit `debugger`s)
- `--open` -- make debugging session remote (accessible from another terminal)
- `--nonstop` -- don't stop at the beginning of code execution (i.e., wait for a
  `debugger`)

Now if you ever want to hit any backend `debugger`s, first open a new terminal
and run `rdbg -A`. Then when your codes halts at a `debugger`, you'll see your
debugging console there!

#### Option B: `byebug`

If you haven't already, head to your __Gemfile__ and change the `debug` gem to
`byebug` inside `group :development, :test`. Then `bundle install`.

```rb
# Gemfile

group :development, :test do
  gem "byebug", platforms: %i[ mri mingw x64_mingw ]
end
```

Next, head to __config/environments/development.rb__ and add the following at
the end of the configuration block:

```rb
# config/environments/development.rb

Rails.application.configure do
  # ... a bunch of configuration stuff

  require "byebug/core"
  Byebug.start_server("localhost", 3001)
end
```

This will start a debugging session at `localhost:3001` whenever you start your
server.

Now if you ever want to hit any backend `debugger`s, first open a new terminal
and run `byebug -R 3001`. (Make sure `foreman` is running first or you will get
a `Connection refused` error.) Then when your code halts at a `debugger`,
you'll see your debugging console there!

> **Note:** You must run `byebug -R 3001` **before** executing the code that
> contains a `debugger`. If you accidentally hit a `debugger` before opening the
> debugging console, your code will still halt, you just won't see a debugging
> console. To continue, simply type `c` and hit `Enter` in your `foreman`
> terminal. Then try again after running `byebug -R 3001`.

### Entry file

Take a quick look at the __webpack.config.js__. Note that your entry file is
__app/javascript/application.js__. Webpack will transpile and bundle all the
files your entry file depends on (files it imports, files those files import,
etc.), creating the file __app/assets/builds/application.js__. This file is then
loaded by __app/views/layouts/application.html.erb__:

```rb
<%= javascript_include_tag "application", defer: true %>
```

Notice this tag includes `defer: true` by default. This tells the browser to run
the script after the page has loaded. Because of this, you do not need to use a
`DOMContentLoaded` callback in your entry file.

If you look at your entry file, __app/javascript/application.js__, you'll notice
five classes have been imported:

```js
import FollowToggle from "./follow_toggle";
import InfiniteTweets from "./infinite_tweets";
import TweetCompose from "./tweet_compose";
import UsersSearch from "./users_search";
import Followers from "./followers";
```

Each one expects a DOM element as an argument to its constructor, and its job is
to bring that element to life via JavaScript by adding event listeners which
trigger DOM changes, AJAX requests, or both.

> *Note*: To make referring to these classes easier throughout this project,
> these instructions will call them _components_.

For each component, there is a corresponding call to
`document.querySelectorAll`. For each element matching the provided CSS
selector, a new instance of the component is created. For example, the code
below will select every `p` element with a class of `cool` and pass it to the
`CoolParagraph` component constructor. What interactivity does it bring to any
`p.cool` elements on the page?

```js
class CoolParagraph {
  constructor(paragraphEl) {
    paragraphEl.addEventListener("click", () => alert("I'm a cool paragraph!"));
  }
}

let coolParagraphSelector = "p.cool";

document.querySelectorAll(coolParagraphSelector).forEach((el) => {
  new CoolParagraph(el);
});
```

It's your job to provide the selectors and fill out the functionality of each
component.

Before writing any code, though, open [localhost:3000] and familiarize yourself
with the application; also look through the source code, including the routes,
views, and database schema!

## Phase 1: `FollowToggle`

You will start by filling out the `FollowToggle` component, which takes a
provided follow/unfollow toggle button. When you click the button, the
`FollowToggle` will send the corresponding follow or unfollow AJAX request--no
page refresh!--and appropriately update the button's text. Between sending a
request and receiving the backend's response, the button's UI will reflect its
pending state: it will be disabled and display `Following...` or
`Unfollowing...`.

### Backend: `follow_toggle` partial

First, you'll modify the Rails partial for the follow/unfollow button to
accommodate frontend manipulation. Specifically, your frontend needs to know
which user to follow/unfollow and whether or not they start out followed or
unfollowed.

Head to __app/views/users/_follow_toggle.html.erb__. Notice that there are two
branches of logic differentiated by whether or not the `current_user` is
following the `user` associated with the toggle (represented by the
`is_following` variable):

1. If `current_user` is following `user`:
   1. Form `method`: `DELETE` (default `POST` method overwritten by hidden
      `input`)
   2. Button text: `Unfollow!`
2. If `current_user` is not following `user`:
   1. Form `method`: `POST` (default method)
   2. Button text: `Follow!`

Now, your frontend **could** figure out the user associated with this button via
the `form`'s `action` (a URL with the user's `id` at the end). You also
**could** figure out the follow state by checking for the presence/absence of a
hidden `input`. However, to make things a bit easier on yourself, you should
attach some [`data-*`] attributes to the button:

- `data-user-id` (`id` of `user`)
- `data-follow-state` (`"followed"` or `"unfollowed"`)

Fill these in, then head to any user's `show` page in your browser. Inspect the
follow/unfollow button in your browser's DevTools. Do you see the data
attributes attached? Does the `id` match the `id` of the user in the URL? If the
`data-follow-state` is `"followed"`, do you see the current user in the
`Followers` list on the right side of the page?

### Frontend: Entry file

Head to __app/javascript/application.js__. Now that you know what the `button`
elements look like that you need to select and pass to the `FollowToggle`
constructor, change the `followToggleSelector` variable from an empty string to
a CSS selector which selects these buttons. You can make sure the selector is
working by adding `console.log(el)` to the `forEach` callback.

### Frontend: `FollowToggle`

Open __app/javascript/follow_toggle.js__. In the constructor, save the
`toggleButton` element--provided as an argument--to a property
`this.toggleButton`.

Take a look at the rest of the `FollowToggle` skeleton. Two helper methods
have been provided: `get followState()` and `set followState(newState)`. These
define `followState` getter and setter methods, which, like getters and setters
in Ruby, allow you to use the syntax of accessing or assigning a property to
in fact call methods:

```js
// calls `get followState()`
// > returns `this.toggleButton.dataset.followState`
this.followState; 

// calls `set followState("banana")`
// > sets `this.toggleButton.dataset.followState` to "banana"
// > calls `this.render()`
this.followState = "banana"; 
```

Follow these MDN links to learn more: [`get`] and [`set`].

By using a getter and setter, you can easily access and change the value of the
`followState` data attribute stored on the follow toggle button as if it were an
instance property of the `FollowToggle` component. As a bonus, whenever you
change a button's `followState`, `this.render()` runs, which will eventually
update the button in accordance with the new `followState`.

Next, head back to the constructor and attach the `handleClick` method
to`toggleButton` as a `click` event handler. Don't forget to bind `this`! Inside
`handleClick`, start by calling `event.preventDefault()`. This is to prevent the
surrounding `form` from submitting; you'll be replacing this form submission
with an AJAX request shortly. Then, simply `console.log(this.followState)`.

Once you've done this, test that it's working by opening a user show page in the
browser and clicking on a follow toggle button. Do you see `followed` or
`unfollowed` logged in the browser console? Pretty cool!

> Ignore the invalid selector errors in the console; you will fill in the
> remaining selectors as you go through the practice.

Next, fill out the logic of `handleClick`:

- If `followState` is `"followed"`, call the `unfollow` method
- If `followState` is `"unfollowed"`, call the `follow` method

The next step is to submit requests to the backend in these methods to actually
follow or unfollow the user associated with the button.

### Frontend: API util

To separate the code for talking to your backend from the code related to
manipulating the DOM, a separate file, __app/javascript/util/api.js__, has been
included where you can define functions that generate AJAX requests to
particular endpoints (routes) in your backend. If you look at
__app/javascript/util/index.js__, you'll see the following line:

```js
export * as API from "./api";
```

This takes every named export from __api.js__ and re-exports them as properties
of an object called `API`.

Meanwhile, Node allows you to import from any __index.js__ file using the name
of its parent directory. Thus, you can import `API` in your top level files from
`./util` instead of `./util/index`. In fact, it is already imported in your
entry file, __app/javascript/application.js__, and assigned as a property of the
`window` so you can access and test your `API` functions from your browser
console.

Try adding the following to __app/javascript/util/api.js__:

```js
// ...

export const foo = "bar";
```

Refresh your browser and look at `API` in the console to see how you can access
named exports--such as `foo`--from __api.js__. After this, you can remove the
`foo` export.

If you look at the top of __api.js__, you will see a function `customFetch`
defined. Just like [`fetch`], it takes in a `url` string and `options` object as
arguments. For now, it starts by simply cloning `options.headers` using
JavaScript's [spread syntax][spread]. This structure is set up to allow you to
easily add default header properties to be merged with the provided
`options.headers`, something that you will be tasked with doing shortly.

After making any necessary adjustments to `options.headers`, the function
passes along the `url` and `options` to the real `fetch`, returning the result.
Eventually, you will modify this behavior as well; for now, `customFetch`
behaves just like `fetch`.

Below `customFetch`, define and export two functions from __api.js__:
`followUser(id)` and `unfollowUser(id)`. The `id` argument for each is the `id`
of the user to follow or unfollow. Inside each, return a call to
`customFetch`, supplying the appropriate relative URL and HTTP method to hit the
`follows#create` and `follows#destroy` backend routes. Run `rails routes` in
your terminal to determine the path and method combinations you need.

> **Note**: While you could make `followUser` and `unfollowUser` `async`
> functions that `await` their return values, doing so would not serve any
> useful purpose. Remember that `await` only pauses the **internal** execution
> of an `async` function until the specified promise resolves. These two
> functions do nothing but return the result of a call to `customFetch`. With no
> other asynchronous calls to sequence and no need to use or manipulate the
> value returned by `customFetch`, these functions have no need for `await`.
> What's more, since these functions have no need for `await`, they really don't
> need the `async` either.
>
> (Potential exception: you should still use `async` if you want synchronous
> exceptions rendered as rejected promises, but don't worry about that now.)

Test that your functions are hitting the right backend routes by calling
`API.followUser(<some-id>)` and `API.unfollowUser(<some-id>)` in your browser
console. Check your **server log** to ensure you're hitting the right controller
actions. You should see `Processing by FollowsController#create` and `Processing
by FollowsController#destroy` in your server log for follow and unfollow
requests, respectively. And you should see a `user_id` parameter pointing to the
`id` argument you supplied.

If you do--great, you got the right URL and HTTP method! However, you'll also
see an error:

```text
ActionController::InvalidAuthenticityToken - Can't verify CSRF token authenticity
```

This is because you haven't supplied an authenticity token in your headers.
Thankfully, Rails includes an authenticity token in each HTML response within a
`meta` tag in the page's `head` element. This value has been retrieved already
and saved to the variable `csrfToken` at the top of __api.js__. You must simply
add a header of `X-CSRF-Token` in `customFetch` whose value is this retrieved
token. This is where the aforementioned ability to add default header values in
`customFetch` comes in handy!

After adding this header, refresh your browser and test your `API` functions in
the browser console again. (Be sure to submit requests to follow users you
currently don't, and vice versa!) The requests should now be valid and the
`create` and `destroy` actions executed--nice! If you refresh a user's show page
after following/unfollowing them, you should see the text content of the follow
toggle button change!

However, if you look in your server log, you'll see that the server's response
in `create` and `destroy` is to redirect to the page from which the request was
sent (effectively forcing a refresh). This is good for a regular form
submission, where a refresh will update the contents of the page. However,
you'll be updating the contents of the page via JavaScript to avoid a full page
refresh (otherwise, why use AJAX?). Your backend is doing unnecessary work.

It'd be easier in this case if the backend simply responded with JSON data
containing details about the follow that was created or destroyed. Is there some
way to tell your backend to provide a different response for AJAX requests? Yes,
via the `Accept` header!

### Frontend and backend: `Accept` header

When you make an HTTP request to a server, you can request a specific format--or
rank a list of acceptable formats--that you'd like the server to respond with.
Examples includes `text/html` if you want an HTML response or `application/json`
if you want a JSON response.

By default, browser-generated requests, such as those created by clicking a
link, refreshing the page, or submitting a form, rank `text/html` as their top
preference in the `Accept` header. Meanwhile, `fetch` defaults to a value of
`*/*` for `Accept`, indicating it will take any kind of response from the
server. If, however, you supply a value of `application/json` in your `fetch`
request, the server will then know to treat the request differently than a
browser-generated request. Go ahead and add such a header to `customFetch`.

In Rails, you can create customs responses for different requested formats using
the [`respond_to`] method, which looks at the `Accept` header under the hood.
Right now, you only have a response set for requests that will accept an HTML
response. Add the following to your `create` action:

```rb
# app/controllers/follows_controller.rb

def create
  # ...
  respond_to do |format|
    # ...html response
    format.json { render json: current_user.slice(:id, :username) }
  end
end
```

> Note that this uses the Ruby [`slice`][ruby-slice] method, not the JavaScript
> version!

Do the same in `destroy`, but send back only the `id` of the `current_user`:

```rb
# app/controllers/follows_controller.rb

def destroy
  # ...
  respond_to do |format|
    # ...html response
    format.json { render json: current_user.slice(:id) }
  end
end
```

Supposing you are not already following the user with the `id` of 5, test
`followUser` in your browser console:

```js
res = await API.followUser(5)
await res.json()
```

You should see an object with the properties of the newly created `follow`! And
if you look in your server log, you should see `Processing by
FollowsController#create as JSON`.

Now you can make your final changes (for now) to `customFetch` in
__app/javascript/util/api.js__. First, instead of returning `await fetch(url,
options)`, save the response to a variable (`response`), and then return
`response.json()`.

However, you only want to return JSON data if the request was successful. Thus,
only return `response.json()` when `response.ok` is true--i.e., when
`response.status` is 200-level. If `response.ok` is not true, then `throw` the
`response` object (thereby rejecting the Promise returned from `customFetch`).

> `response.json()` is an asynchronous function call, so you could `await` the
> result. Once again, however, doing so would not serve any purpose here. In
> contrast, you **do** need to `await` the result of `fetch(url, options)` when
> assigning it to `response` because the function's subsequent logic depends on
> the value of `response`. (Question: Was the `await` necessary in the original
> `return await fetch(url, options)`?)

Go ahead and test `await API.followUser(<id>)` and `await
API.unfollowUser(<id>)` in your browser console. You should see a JSON response
when making a valid request and an `Uncaught (in promise)` error when making an
invalid request.

[ruby-slice]: https://ruby-doc.org/core-3.1.1/Hash.html#method-i-slice

### Frontend: Completing `FollowToggle`

Your API functions are now complete! Time to call them from `follow` and
`unfollow` in `FollowToggle` (__app/javascript/follow_toggle.js__). In each,
call and `await` the appropriate `API` function, supplying the user id stored in
the button's data attributes. Before making the request, set `followState` to
`following` or `unfollowing`, as appropriate. After the request is
completed, set `followState` to `unfollowed` or `followed`, as appropriate.

Since your `followState` setter calls `this.render`, you can update the UI
appropriately there to reflect the current `followState`. For now, just
`console.log(this.followState)`, and then test in the browser by visiting a
user's show page and clicking the follow toggle. Supposing you start out not
following a given user, you should see `following` logged, and then about a
second later (due to some artificial latency on the backend), `followed`. Nice!

Finally, fill out the `case` statements in `render`. In each, you will set the
`disabled` property of `this.toggleButton`, as well as its `innerText`, like so:

- `"followed"`:
  - not disabled
  - text: `"Unfollow!"`
- `"unfollowed"`:
  - not disabled
  - text: `"Follow!"`
- `"following"`:
  - disabled
  - text: `"Following..."`
- `"unfollowing"`:
  - disabled
  - text: `"Unfollowing..."`

Some CSS has already been defined which greys out a button when it has the
`disabled` property. Go ahead and test your pending UI in the browser! Pretty
cool, huh?

**Now is a good time to commit and ask for a code review.**

## Note on upcoming phases

In the upcoming phases, you will follow a similar pattern to that of
`FollowToggle`:

1. Investigate the existing backend implementation of a feature.
2. Adjust the backend as needed to accommodate new frontend functionality (such
   as by adding data attributes to elements or by adding custom `format.json`
   responses in controllers).
3. Select the right elements in your entry file to pass to the constructor of
   the corresponding component.
4. Write a `constructor` that, among other things, attaches event listener(s) to
   the provided element and/or its children.
5. In these event handlers, make AJAX requests, implement a pending UI where
   warranted, and update the DOM after the request is complete.

You might add additional JavaScript interactivity on top of the basic structure
outlined here. But you will follow this general course for each phase.

## Phase 2: `InfiniteTweets`

Both the feed and user show pages render a list of tweets. When you scroll to
the end of the tweets, there is a button to fetch more. This causes a full page
refresh; your backend must re-render the page, loading all the tweets you saw
before plus 10 additional ones.

This is not a great user experience, nor is it efficient. In this phase, you'll
request more tweets using AJAX, fetching only the 10 additional tweets you need
as JSON and then appending them to the existing tweets list.

### Backend: Tweet index route and action

Start by creating a new `tweets#index` backend route--the action is already
created--which will render requested tweets as JSON data.

Which tweets should you render from this action, and what data should you
include with each tweet? Let's look at how you're already retrieving tweets for
the feed and user show pages.

First, take a look at __app/views/tweets/\_infinite_tweets.html.erb__. This
partial is rendered by both the feed and user show pages. It expects as an
argument a list of `tweets` to iterate over and render as `li`s inside the
`ul.tweets` element, via the __\_tweet.html.erb__ partial.

Where does this list of `tweets` comes from?

- *Feed:* Defined within __app/controllers/tweets_controller.rb__ as `@tweets`,
  which is then passed along to the `infinite_tweets` partial in
  __app/views/tweets/feed.html.erb__
- *User Show:* Defined in-line while rendering the `infinite_tweets` partial in
  __app/views/users/show.html.erb__

Take a look yourself. In both cases, the tweets come from a call to
`User#page_of_tweets`. Head to __app/models/user.rb__ to investigate this
method. As you can see, this method takes three [keyword arguments][kwargs]:

1. `type:` -- which association to use as a source for the tweets
2. `limit:` -- how many tweets to retrieve (default: 10)
3. `offset:` -- how many tweets to skip (default: 0)

You can use this same method in your `tweets#index` action, again calling it on
the `current_user`. This time, though, you'll actually make use of the optional
`offset:` argument, since you should skip the tweets already rendered on the
page. And since you will always be fetching 10 tweets in your requests to
`tweets#index`, you no longer need to set a custom `limit:`.

Go ahead and call `User#page_of_tweets` within `tweet#index`, passing in a
`type:` and `offset:` whose values come from `params` of the same name. Save the
result to `@tweets`.

For now, render `@tweets` as JSON. Soon, you'll see this needs to be changed (do
you have any ideas for why?). First, though, you'll write an API utility
function that makes a request to the new `tweets#index` endpoint.

### Frontend: `fetchTweets` API function

Head to __app/javascript/util/api.js__, and export a function `fetchTweets` that
takes in an `options` argument, with a default value of `{}`. This `options`
argument will contain `type` and `offset` properties to use as request
parameters in the query string.

To easily convert a JavaScript object into a URL query string with the right
syntax and character escaping, you can use the [`URLSearchParams`] class built
into the browser. Create a new instance of `URLSearchParams`, passing in
`options` as an argument. Save the result to a variable `queryParams`.

You can then call `queryParams.toString()` to get a valid query string.
Alternatively, you can interpolate `queryParams` within a string, in which case
JavaScript will call `toString` on it under the hood.

Complete `fetchTweets` by making a request to the `tweets#index` endpoint,
appending the query string produced by `queryParams` to the URL (don't forget to
separate the query string from the path with a `?`). Return the result.

Finally, test your `tweets#index` endpoint in your browser console:

```js
await API.fetchTweets({ type: 'profile' })
```

You should see an array of 10 tweets. Nice! There's just one problem. If you
look at the data included in any given tweet object, you're missing associated
data--such as the author's username or a mentioned user--that you'll need when
rendering those tweets.

### Backend: Jbuilder response

To easily construct a JSON response that includes just the data you need for
each tweet, you can use [Jbuilder][jbuilder]. Jbuilder is a library that allows
you to construct JSON responses in `<view_name>.json.jbuilder` view files, which
are written in Ruby using Jbuilder's _Domain Specific Language_ (DSL).

You will learn much more Jbuilder later in the curriculum. For now, you can just
use the __app/views/tweets/index.json.jbuilder__ view that has been written for
you. This view constructs a JSON array. For each tweet in `@tweets`, it
constructs an object within this outer array, the contents of which are
determined by the __app/views/tweets/\_tweet.json.jbuilder__ Jbuilder partial.

Go ahead and change your `tweets#index` action to `render :index` instead of
`render json: @tweets`. Since your AJAX requests include an `Accept` header of
`application/json`, Rails will automatically look for a __index.json.jbuilder__
file before looking for an __index.html.erb__ file.

After making this change, send another `fetchTweets` request from your browser
console. Look at the data included within each tweet object. Do you see the
relationship between this data and what you see in
__app/views/tweets/\_tweet.json.jbuilder__?

### Backend: Adding a `type` data attribute

Now that your frontend can make AJAX requests to request additional tweets with
the right data, there's only one more adjustment to make to the backend. For any
given infinite-tweets element, you'll need to know whether it should fetch
additional `profile` or `feed` tweets.

You could derive this information from the current URL, but it would be more
straightforward to add a `data-*` attribute to each infinite tweets element
specifying its type.

Head to __app/views/tweets/\_infinite_tweets.html.erb__ and add a `data-type`
attribute to the `div.infinite-tweets` element, pointing to a `type` variable
that you'll pass to the partial.

Then, head to the two places where you render this partial,
__app/views/tweets/feed.html.erb__ and __app/views/users/show.html.erb__, and
pass the appropriate `type`--either `feed` or `profile`.

### Frontend: `InfiniteTweets`

Now it's time to fill out the `InfiniteTweets` component on your frontend.

First, head to __app/javascript/application.js__ and supply an appropriate
selector to `infiniteTweetsSelector`. You're targeting the outermost `div` in
the __\_infinite_tweets.html.erb__ partial.

Then head to __app/javascript/infinite_tweets.js__ and fill out the following
functions. Feel free to create additional helper functions as you see fit to
keep your code DRY and readable.

* `constructor`
  * Save the root element (the container `div` with a class of
    `infinite-tweets`) as a property of `this`.
  * Save the `Fetch more tweets!` button and the `ul` with a class of `tweets`
    as instance properties. (You may need to use DOM querying methods to grab
    them.)
  * Attach `handleFetchTweets` as a click handler on the `Fetch more tweets!`
    button; don't forget to bind `this`!

* `handleFetchTweets`
  * Call `event.preventDefault()`.
  * Call and `await` the response to `API.fetchTweets`, passing in `type` and
    `offset` options:
    * `type` should be set to the value of the the root element's `type` data
      attribute
    * `offset` should be set the number of tweets (i.e., `li`s) that are
      currently contained within the `ul.tweets` element.
  * Save the response data to a variable and `console.log` it. Then, test
    what you have written so far by clicking the `Fetch more tweets!` button
    in your browser. You should see an array of 10 tweet objects logged in
    the console.
  * Pass each tweet object from the response data to `appendTweet`.
  * At the end of this function, check if the number of tweets returned from the
    backend is less than 10. If so, this implies you've run out of additional
    tweets to fetch--create a `p` element with the text `No more tweets!` and
    replace the `Fetch more tweets!` button in the DOM with the `noMoreTweets`
    `p` element that has been created for you. (Hint: Check out the
    [`replaceWith`] method.)

* `appendTweet`
  * The provided tweet data is already being passed to `createTweet`, which
    returns a tweet `li`. Append this `li` to the tweets `ul`.

* `createTweet`
  * Right now, this function is just returning an empty `li`. Instead, you want
    to construct an `li` containing a `div.tweet` element that has the structure
    of the `div.tweet` element in __app/views/tweets/\_tweet.html.erb__.
  * Using `document.createElement` and DOM manipulation methods, recreate
    this structure. All of the data you need should be included in the
    `tweetData` argument.
    * You may  want to define helper methods that construct individual pieces of
      the whole structure. For instance, you could write a `createMention`
      helper method which creates and returns the mention `div`.
    * Don't forget to set attributes like `class` and `href`.
    * To render a properly formatted, readable date inside the `span.created-at`
      element, you should first create a new [`Date`] instance, passing in the
      `createdAt` datetime string to the  constructor. Then, call
      [`toLocaleDateString`] on this `Date` instance. This method takes in a
      locale, e.g. `en-US`, as its first argument, and an options object for
      formatting the readable date as its second argument. Pass in `en-US` or
      the locale of your choice as the first argument, and `{ dateStyle: "long"
      }` as the options argument.
  * Once you have successfully implemented `createTweet`, inspect the new tweet
    elements in your browser that are being appended by `appendTweet`. Make sure
    they look like the tweets rendered by your backend.

If you've got your tweets rendering correctly, that is quite the
accomplishment--you're a DOM wizard! There is just one more step: creating a
pending UI. After clicking the `Fetch more tweets!` button, but before
submitting an AJAX request, disable the button and change its text to
`Fetching...`; after receiving a response from the backend, reset the text to
`Fetch more tweets!` and set `disabled` to `false`.

Test your work once more in the browser. Well done!

**Now is a good time to commit and ask for a code review.**

## Phase 3: `UsersSearch`

Now it's time to bring some AJAX magic to the user search! Right now, to search
for users, you must hit `Enter` or click the `Search` button, which causes a
full-page refresh. In this phase, you'll submit search requests via AJAX as the
user types, showing live search results.

### Backend: Overview

First, head to __app/controllers/users_controller.rb__ and check out the
`search` action. Here you find a list of users, `@users`, whose usernames begin
with the value at the key of `query` in the query string. You may want to
refresh yourself on [`iLIKE`].

Once you understand what's happening in this action, head to the HTML view for
`users#search`, __app/views/users/search.html.erb__. There are two main parts of
the page:

* A `form` with a search box, a submit button, and a span which you'll soon use
  as a loading indicator.
* A `ul` where you render the `@users` retrieved from the search, with a link to
  their profile and a button to follow / unfollow them.

Since search requests will be triggered automatically just by typing, you'll
want to remove the search button from the form. However, you only want to remove
it if JavaScript is enabled by the user. To do so, wrap the search button in
[`noscript`] tags. Elements contained within `noscript` tags are only rendered
if your browser has JavaScript disabled.

Next, head to the Jbuilder view for `users#search`
__app/views/users/search.json.jbuilder__, which will be rendered when you make
an AJAX request to `users#search` with an `"Accept": "application/json"` header.
This Jbuilder view renders an array of objects corresponding to each user in
`@users` (the users retrieved from the search). Each user object contains the
user's `id` and `username`, as well as a boolean, `following`, representing
whether or not they are followed by the `current_user`.

Now that you see how JSON responses are generated for `users#search` AJAX
requests, you can define an API function that will hit that endpoint.

### Frontend: `searchUsers` API function

Start by going to your API util file. From there, define and export a
`searchUsers` function. This should take in a `query` argument and hit the
backend route corresponding to the `users#search` action, passing in the
provided `query` as a parameter. Return the result.

Be sure to test `API.searchUsers` in your browser console, paying careful
attention to the data contained within the response.

### Frontend: `UsersSearch`

First, head to the entry file and supply the appropriate selector to retrieve
the outer `div` with a class of `users-search` from __search.html.erb__.

Next, head to __app/javascript/users_search.js__.

Much of the `UsersSearch` component is already implemented. You'll notice the
`constructor` follows the same pattern found in earlier components: saving
relevant DOM elements as instance properties and attaching event listeners. One
listener handles `input` events in the search box, and one prevents form
submission from triggering an HTTP request / full page refresh.

However, you'll also see this line:

```js
this.debouncedSearch = debounce(this.search.bind(this), 300);
```

`debounce` here returns a function which itself calls `this.search`. However,
instead of calling `this.search` immediately when you call
`this.debouncedSearch`, it waits a set amount of time--here, 300ms. If another
call is made to `this.debouncedSearch` before the 300ms is up, it cancels the
previously planned call to `this.search` and starts a new 300ms timer.

The net effect: if a number of calls to `this.debouncedSearch` occur in close
succession, only one call to `this.search` is made, 300ms after the last call to
`this.debouncedSearch`. In the diagram below from [this excellent CSS Tricks
article on debouncing and throttling][debouncing], the top row corresponds to
calls to `this.debouncedSearch`, and the bottom row corresponds to calls to
`this.search`:

![debounce diagram][debounce-diagram]

Why `debounce` the search function? To be more efficient! Without debouncing,
you'd be sending an AJAX request to the backend after every single character you
type in the search box; with debouncing, a request is sent only after you have
paused typing for 300ms.

The `constructor` and several helper methods having already been implemented,
but there are four sections of `UsersSearch` that are left for you to implement.

#### `handleInput`

Take the current value of the search input and save it as a variable `query`.
Unless the `query` is empty, set the text of the loading indicator to
`Searching...`. Then, pass the `query` to `this.debouncedSearch`.

#### `search`

Here is where you'll make an AJAX request to your backend.

Within the condition where the `query` is truthy (i.e., not an empty string),
`await` a call to `API.searchUsers`. Pass the response data to
`this.renderResults` and reset the loading indicator text to an empty string.

Examine `renderResults` if you haven't already: it expects an array of objects
with data about each user retrieved from the search. It maps these data objects
to `li`s which match the structure of the search result `li`s in
__app/views/users/search.html.erb__. It then replaces the existing `li`s within
the search results `ul` with the newly created `li`s.

In the `else` condition--which you hit when `query` is an empty string--pass an
empty array to `this.renderResults`, effectively clearing out the search results
`ul`.

At this point, your core search functionality is complete! Test that your search
is working in the browser; you should see search results appear after some delay
whenever you type in the search box.

#### `createUserAnchor`

Each username that appears in the search results should be a link that brings
you to the user's show page. However, something is missing. Compare the anchor
tags that are created by your JavaScript with the anchor tags in
__app/views/users/search.html.erb__. Once you have added the missing attribute,
test that clicking each username brings you to that user's show page.

#### `createFollowButton`

Right now, the follow / unfollow button is empty. You'll need to set the
`data-*` attributes it needs to be brought to life by `FollowToggle`, and then
create a new instance of `FollowToggle`, passing in the button element.

Test that you are able to follow / unfollow users in the search results. Isn't
the search experience so much nicer with results as you type? Nice work!

**Now is a good time to commit and ask for a code review.**

## Bonus phase 1: `TweetCompose`

In this phase, you will make two improvements to the experience of composing a
tweet:

1. Show the number of characters remaining (out of a max of 280) in the tweet
   `textarea` and prevent submission if this number is below 0.
2. Prevent a full page refresh when creating a tweet on your profile and instead
   prepend the new tweet to the existing tweets `ul`.

### Chars remaining

To accomplish the first improvement, no changes to the backend are necessary.
But before moving on, look over the partial that renders the tweet composition
`form` at __app/views/tweets/_form.html.erb__ and examine the existing
`tweets#create` action in __app/controllers/tweets_controller.rb__.

Update the frontend entry file with a selector for the tweet composition `form`.
Then, in __app/javascript/tweet_compose.js__, examine the existing
`TweetCompose` component until you have a solid understanding of what's
happening in the following functions:

* `constructor`
* `handleInput`
* `validate`
* `setErrors`
* `clear`
* `setLoading`
* `get tweetData`

Update `handleInput`, which is triggered whenever you type in the tweet
`textarea`, so that it updates the `span-chars-remaining` element. It should
display the number of characters remaining (out of a max of 280 characters) and
have a `class` of `invalid` if and only if this number is below 0.

### Prevent full page refresh

Right now, whenever you submit a tweet, you are redirected to your profile page.
If you are already on your profile page, this is essentially a page refresh. In
this case, the only change to the page is that your newly created tweet now
appears at the top of the tweets `ul`; you can accomplish this change with
JavaScript instead.

#### Creating a tweet via AJAX

In the `create` action of __app/controllers/tweets_controller.rb__, add a
`format.json` response for both the success and error cases.

In the `format.json` block where the tweet is invalid, render the `errors` as
JSON with a status of `422`.

In the `format.json` block where the tweet successfully saves, check if the URL
from which the request was sent (i.e., `request.referrer`) corresponds to the
current user's profile. If so, render the `show` Jbuilder view; if not, redirect
to the current user's profile.

By default, if a `fetch` request has a redirect response, the request to the
redirected page will be conducted as another AJAX request; the browser will not
navigate to the new URL. You'll need to update `customFetch` to manually
navigate to the redirected URL. In `customFetch`, after checking if
`response.ok`, add an `else if` condition checking if `response.redirected`. In
that case, simply set the `window.location` to the redirected URL, available at
`response.url`.

While you are in your API util file, define and export a `createTweet` function
which takes in a `tweetData` object and hits the `tweets#create` endpoint. Your
request body should consist of a [JSON-stringified][stringify] object with a
top-level key of `tweet` pointing to the `tweetData` object. (Where does your
backend expect a top-level key of `tweet`?) Include a `Content-Type` header of
`application/json` to let your server know that the request body is formatted as
JSON. Go ahead and test `API.createTweet` in your browser console before
continuing.

Finally, within the `TweetCompose` component, you'll need to update
`handleSubmit`. As you proceed, be sure to review the helper methods that have
already been defined for you; you will need them to implement `handleSubmit`,
and the following instructions will not reference them by name.

> Why is there a `try/catch` statement in `handleSubmit`? Because this is the
> first AJAX request in your application so far to which your backend might
> respond with a 400-level status code. When your backend serves a 400-level
> response to a request, `customFetch` will `throw` the response. Since
> `customFetch` is an `async` function, this has the effect of rejecting the
> returned promise. And if you `await` a promise that rejects, an error is
> raised. Thus, you should `await` your AJAX request in the `try` clause; the
> `catch` clause, which handles a 400-level response, has been implemented for
> you.

Before the `try` clause, first validate the form; if the form is invalid,
`return` from `handleSubmit` early.

Within the `try` clause, set the UI to a loading state. Make a request to
`API.createTweet` with the tweet data from the form, and save the response to a
variable, `tweet`; for now, simply `console.log(tweet)`. Then, clear the form.

After the `try/catch` statement, or within an added `finally` clause, remove the
loading UI.

Go ahead and test that after submitting the tweet-compose form:

* A new `tweet` is created (check your server log)
* When on the `feed` page, you are successfully redirected to your profile
* When on your profile, you receive tweet data as JSON (check your browser
  console for the `console.log`ed tweet)

Nice! There's just one step left: when on your profile page, you'll need to
prepend the newly created tweet to the tweets `ul`.

#### Prepending the new tweet

The `InfiniteTweets` component currently manages the tweets `ul` to which your
new tweet should be prepended. `InfiniteTweets` already includes a method
`appendTweet`, which takes in tweet data, creates a tweet element, and appends
it to the tweets `ul`. Define a corresponding method in `InfiniteTweets`,
`prependTweet`. This method should differ from `appendTweet` in just one way: it
should add the new tweet element to the *top* of the tweets `ul` via the
[`prepend`] method.

Great! But how do you call `prependTweet` from your `TweetCompose` instance? One
strategy would be to store references to each of your component instances in a
global object (either saved to the window or passed as an argument to each
component's constructor). You could then call `prependTweets` on your
`InfiniteTweets` instance directly within `TweetCompose`'s `handleSubmit`.

However, there are drawbacks to this approach. One of the most significant: your
`TweetCompose` component would then need to know (1) where the relevant
`InfiniteTweets` instance is stored in the global components object and (2) the
appropriate `InfiniteTweets` method to call. This is an example of [tight
coupling]: the code in `TweetCompose` cannot be reasoned about in isolation, and
changes elsewhere in your codebase could easily break `TweetCompose`.

Instead, what if you could fire a custom DOM event on the `window` signaling a
new tweet was created? This event could contain the new tweet's data; any other
components in your application that care about new tweets can then listen for
this event.

Thankfully, the DOM API supports both creating custom events--via the
[`CustomEvent`] constructor--and manually firing events--via
[`EventTarget.dispatchEvent()`][dispatch-event]. You can add whatever data you
want to a `CustomEvent` by providing it a `detail` property.

A utility function for firing custom events, `broadcast`, has been defined for
you in __app/javascript/util/index.js__. It takes in a string `eventType` and
arbitrary `data`, creates a `CustomEvent` of the provided `eventType` containing
`data` under the `detail` property, and then fires the event on the `window`.

Within the `try` clause of `handleSubmit` in `TweetCompose`, replace
`console.log(tweet)` with `broadcast("tweet", tweet)`. Then, head to
the `constructor` of `InfiniteTweets`, and add the following event listener:

```js
// app/javascript/util/infinite_tweets.js

// ... 
export default class InfiniteTweets {
  constructor(rootEl) {
    // ...
    window.addEventListener("tweet", (event) => {
      console.log("In listener for custom `tweet` event");
      console.log(event.detail);
    });
  }
  // ...
}
```

Now, whenever you create a new tweet on your profile page, you should see the
tweet data logged in your browser console. Nice!

The final step is to remove the `console.log`s and instead prepend the new tweet
within the event handler. You should also wrap the entire event handler within a
condition checking that the `type` of the `InfiniteTweets` instance is
`profile`. Test that your tweet is successfully being prepended. Pretty neat!

## Bonus phase 2: `Followers`

When you follow or unfollow another user on their show page, you'll notice your
own username doesn't get added / removed from the `Followers` list in the
sidebar. Time to change that! This time, though, you're pretty much on your own.

Head to __app/views/users/show.html.erb__ and look for the `ul` with a `class`
of `users followers`. Target this element as the root of the `Followers`
component in your JavaScript.

From your `FollowToggle` class, `broadcast` events for `follow` and `unfollow`.
Within the `Followers` component, listen for these events, adding or removing an
`li` for the current user for the `follow` and `unfollow` events, respectively.

Provide whatever data in these events you'll need to create a new follower `li`
or identify the follower `li` to remove. Feel free to adjust the backend as
necessary to supply this data: for instance, you might change the JSON response
for `follows#create` / `follows#destroy` and/or add `data-*` attributes to the
follower `li`s in the user `show` view.

## Summary

Congratulations! In this project, you learned how to send `fetch` AJAX requests
from the frontend, respond to requests with JSON, and use the data from the
response to manipulate the DOM. You learned how to use `data-*` attributes to
provide data in the DOM for your JavaScript to use, and you learned how to
implement a pending UI. If you got to the Bonus phases, you learned about
handling redirects with `fetch` and how you can use `CustomEvent`s to decouple
component functionality. Well done!

[`foreman`]: https://github.com/ddollar/foreman
[`data-*`]: https://developer.mozilla.org/en-US/docs/Web/HTML/Global_attributes/data-*
[`get`]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Functions/get
[`set`]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Functions/set
[`fetch`]: https://developer.mozilla.org/en-US/docs/Web/API/fetch
[spread]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/Spread_syntax#spread_in_object_literals
[`Accept`]: https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Accept
[`respond_to`]: https://api.rubyonrails.org/classes/ActionController/MimeResponds.html#method-i-respond_to
[kwargs]: https://docs.ruby-lang.org/en/master/doc/syntax/calling_methods_rdoc.html#label-Keyword+Arguments
[jbuilder]: https://github.com/rails/jbuilder/blob/master/README.md
[`URLSearchParams`]: https://developer.mozilla.org/en-US/docs/Web/API/URLSearchParams
[`replaceWith`]: https://developer.mozilla.org/en-US/docs/Web/API/Element/replaceWith
[`Date`]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Date
[`toLocaleDateString`]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Date/toLocaleDateString
[`iLIKE`]: https://www.postgresql.org/docs/8.3/functions-matching.html
[`noscript`]: https://developer.mozilla.org/en-US/docs/Web/HTML/Element/noscript
[debouncing]: https://css-tricks.com/debouncing-throttling-explained-examples/
[debounce-diagram]: https://i0.wp.com/css-tricks.com/wp-content/uploads/2016/04/debounce.png
[stringify]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/JSON/stringify
[`prepend`]: https://developer.mozilla.org/en-US/docs/Web/API/Element/prepend
[tight coupling]: https://en.wikipedia.org/wiki/Coupling_(computer_programming)
[`CustomEvent`]: https://developer.mozilla.org/en-US/docs/Web/API/CustomEvent/CustomEvent
[dispatch-event]: https://developer.mozilla.org/en-US/docs/Web/API/EventTarget/dispatchEvent