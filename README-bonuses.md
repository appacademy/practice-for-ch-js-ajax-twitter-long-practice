# AJAX Twitter (Bonuses)

[Live Demo]

[Live Demo]: https://aa-twitter-ajax.herokuapp.com/

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
`tweets#create` action in **app/controllers/tweets_controller.rb**.

Update the frontend entry file with a selector for the tweet composition `form`.
Then, in **app/javascript/tweet_compose.js**, examine the existing
`TweetCompose` component until you have a solid understanding of what's
happening in the following functions:

- `constructor`
- `handleInput`
- `validate`
- `setErrors`
- `clear`
- `setLoading`
- `get tweetData`

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

In the `create` action of **app/controllers/tweets_controller.rb**, add a
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

- A new `tweet` is created (check your server log)
- When on the `feed` page, you are successfully redirected to your profile
- When on your profile, you receive tweet data as JSON (check your browser
  console for the `console.log`ed tweet)

Nice! There's just one step left: when on your profile page, you'll need to
prepend the newly created tweet to the tweets `ul`.

#### Prepending the new tweet

The `InfiniteTweets` component currently manages the tweets `ul` to which your
new tweet should be prepended. `InfiniteTweets` already includes a method
`appendTweet`, which takes in tweet data, creates a tweet element, and appends
it to the tweets `ul`. Define a corresponding method in `InfiniteTweets`,
`prependTweet`. This method should differ from `appendTweet` in just one way: it
should add the new tweet element to the _top_ of the tweets `ul` via the
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
you in **app/javascript/util/index.js**. It takes in a string `eventType` and
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

Head to **app/views/users/show.html.erb** and look for the `ul` with a `class`
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

[stringify]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/JSON/stringify
[`prepend`]: https://developer.mozilla.org/en-US/docs/Web/API/Element/prepend
[tight coupling]: https://en.wikipedia.org/wiki/Coupling_(computer_programming)
[`CustomEvent`]: https://developer.mozilla.org/en-US/docs/Web/API/CustomEvent/CustomEvent
[dispatch-event]: https://developer.mozilla.org/en-US/docs/Web/API/EventTarget/dispatchEvent