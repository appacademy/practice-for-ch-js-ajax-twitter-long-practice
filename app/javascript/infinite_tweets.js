import { API } from "./util";

export default class InfiniteTweets {
  constructor(rootEl) {
    // Your code here
  }

  async handleFetchTweets(event) {
    // Your code here
    // Remove fetch tweets button if you've run out of tweets to fetch
    if (false /* REPLACE */) {
      const noMoreTweets = document.createElement("p");
      noMoreTweets.innerText = "No more tweets!";
      // Your code here
    }
  }

  appendTweet(tweetData) {
    const tweetEl = this.createTweet(tweetData);
    // Your code here
  }

  createTweet(tweetData) {
    const li = document.createElement("li");
    // Your code here
    return li;
  }

  // Helper methods...
}