# AJAX Twitter (Phase 3)

[Live Demo]

[Live Demo]: https://aa-twitter-ajax.herokuapp.com/

## Phase 3: `UsersSearch`

Now it's time to bring some AJAX magic to the user search! Right now, to search
for users, you must hit `Enter` or click the `Search` button, which causes a
full-page refresh. In this phase, you'll submit search requests via AJAX as the
user types, showing live search results.

### Backend: Overview

First, head to **app/controllers/users_controller.rb** and check out the
`search` action. Here you find a list of users, `@users`, whose usernames begin
with the value at the key of `query` in the query string. You may want to
refresh yourself on [`iLIKE`].

Once you understand what's happening in this action, head to the HTML view for
`users#search`, **app/views/users/search.html.erb**. There are two main parts of
the page:

- A `form` with a search box, a submit button, and a span which you'll soon use
  as a loading indicator.
- A `ul` where you render the `@users` retrieved from the search, with a link to
  their profile and a button to follow / unfollow them.

Since search requests will be triggered automatically just by typing, you'll
want to remove the search button from the form. However, you only want to remove
it if JavaScript is enabled by the user. To do so, wrap the search button in
[`noscript`] tags. Elements contained within `noscript` tags are only rendered
if your browser has JavaScript disabled.

Next, head to the Jbuilder view for `users#search`
**app/views/users/search.json.jbuilder**, which will be rendered when you make
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
the outer `div` with a class of `users-search` from **search.html.erb**.

Next, head to **app/javascript/users_search.js**.

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
**app/views/users/search.html.erb**. It then replaces the existing `li`s within
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
**app/views/users/search.html.erb**. Once you have added the missing attribute,
test that clicking each username brings you to that user's show page.

#### `createFollowButton`

Right now, the follow / unfollow button is empty. You'll need to set the
`data-*` attributes it needs to be brought to life by `FollowToggle`, and then
create a new instance of `FollowToggle`, passing in the button element.

Test that you are able to follow / unfollow users in the search results. Isn't
the search experience so much nicer with results as you type? Nice work!

**Now is a good time to commit and ask for a code review.**

Next up: Bonuses!

[`iLIKE`]: https://www.postgresql.org/docs/8.3/functions-matching.html
[`noscript`]: https://developer.mozilla.org/en-US/docs/Web/HTML/Element/noscript
[debouncing]: https://css-tricks.com/debouncing-throttling-explained-examples/
[debounce-diagram]: https://i0.wp.com/css-tricks.com/wp-content/uploads/2016/04/debounce.png