# AJAX Twitter (Phase 2)

[Live Demo]

[Live Demo]: https://aa-twitter-ajax.herokuapp.com/

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

- _Feed:_ Defined within **app/controllers/tweets_controller.rb** as `@tweets`,
  which is then passed along to the `infinite_tweets` partial in
  **app/views/tweets/feed.html.erb**
- _User Show:_ Defined in-line while rendering the `infinite_tweets` partial in
  **app/views/users/show.html.erb**

Take a look yourself. In both cases, the tweets come from a call to
`User#page_of_tweets`. Head to **app/models/user.rb** to investigate this
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

Head to **app/javascript/util/api.js**, and export a function `fetchTweets` that
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
use the **app/views/tweets/index.json.jbuilder** view that has been written for
you. This view constructs a JSON array. For each tweet in `@tweets`, it
constructs an object within this outer array, the contents of which are
determined by the __app/views/tweets/\_tweet.json.jbuilder__ Jbuilder partial.

Go ahead and change your `tweets#index` action to `render :index` instead of
`render json: @tweets`. Since your AJAX requests include an `Accept` header of
`application/json`, Rails will automatically look for a **index.json.jbuilder**
file before looking for an **index.html.erb** file.

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
**app/views/tweets/feed.html.erb** and **app/views/users/show.html.erb**, and
pass the appropriate `type`--either `feed` or `profile`.

### Frontend: `InfiniteTweets`

Now it's time to fill out the `InfiniteTweets` component on your frontend.

First, head to **app/javascript/application.js** and supply an appropriate
selector to `infiniteTweetsSelector`. You're targeting the outermost `div` in
the __\_infinite_tweets.html.erb__ partial.

Then head to **app/javascript/infinite_tweets.js** and fill out the following
functions. Feel free to create additional helper functions as you see fit to
keep your code DRY and readable.

- `constructor`
  - Save the root element (the container `div` with a class of
    `infinite-tweets`) as a property of `this`.
  - Save the `Fetch more tweets!` button and the `ul` with a class of `tweets`
    as instance properties. (You may need to use DOM querying methods to grab
    them.)
  - Attach `handleFetchTweets` as a click handler on the `Fetch more tweets!`
    button; don't forget to bind `this`!

- `handleFetchTweets`
  - Call `event.preventDefault()`.
  - Call and `await` the response to `API.fetchTweets`, passing in `type` and
    `offset` options:
    - `type` should be set to the value of the the root element's `type` data
      attribute
    - `offset` should be set the number of tweets (i.e., `li`s) that are
      currently contained within the `ul.tweets` element.
  - Save the response data to a variable and `console.log` it. Then, test
    what you have written so far by clicking the `Fetch more tweets!` button
    in your browser. You should see an array of 10 tweet objects logged in
    the console.
  - Pass each tweet object from the response data to `appendTweet`.
  - At the end of this function, check if the number of tweets returned from the
    backend is less than 10. If so, this implies you've run out of additional
    tweets to fetch--create a `p` element with the text `No more tweets!` and
    replace the `Fetch more tweets!` button in the DOM with the `noMoreTweets`
    `p` element that has been created for you. (Hint: Check out the
    [`replaceWith`] method.)

- `appendTweet`
  - The provided tweet data is already being passed to `createTweet`, which
    returns a tweet `li`. Append this `li` to the tweets `ul`.

- `createTweet`
  - Right now, this function is just returning an empty `li`. Instead, you want
    to construct an `li` containing a `div.tweet` element that has the structure
    of the `div.tweet` element in __app/views/tweets/\_tweet.html.erb__.
  - Using `document.createElement` and DOM manipulation methods, recreate
    this structure. All of the data you need should be included in the
    `tweetData` argument.
    - You may  want to define helper methods that construct individual pieces of
      the whole structure. For instance, you could write a `createMention`
      helper method which creates and returns the mention `div`.
    - Don't forget to set attributes like `class` and `href`.
    - To render a properly formatted, readable date inside the `span.created-at`
      element, you should first create a new [`Date`] instance, passing in the
      `createdAt` datetime string to the  constructor. Then, call
      [`toLocaleDateString`] on this `Date` instance. This method takes in a
      locale, e.g. `en-US`, as its first argument, and an options object for
      formatting the readable date as its second argument. Pass in `en-US` or
      the locale of your choice as the first argument, and `{ dateStyle: "long"
      }` as the options argument.
  - Once you have successfully implemented `createTweet`, inspect the new tweet
    elements in your browser that are being appended by `appendTweet`. Make sure
    they look like the tweets rendered by your backend.

If you've got your tweets rendering correctly, that is quite the
accomplishment--you're a DOM wizard! There is just one more step: creating a
pending UI. After clicking the `Fetch more tweets!` button, but before
submitting an AJAX request, disable the button and change its text to
`Fetching...`; after receiving a response from the backend, reset the text to
`Fetch more tweets!` and set `disabled` to `false`.

Test your work once more in the browser. Well done!

**Now is a good time to commit and ask for a code review.** Then on to Phase 3:
`UsersSearch`!

[kwargs]: https://docs.ruby-lang.org/en/master/doc/syntax/calling_methods_rdoc.html#label-Keyword+Arguments
[`URLSearchParams`]: https://developer.mozilla.org/en-US/docs/Web/API/URLSearchParams
[jbuilder]: https://github.com/rails/jbuilder/blob/master/README.md
[`replaceWith`]: https://developer.mozilla.org/en-US/docs/Web/API/Element/replaceWith
[`Date`]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Date
[`toLocaleDateString`]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Date/toLocaleDateString