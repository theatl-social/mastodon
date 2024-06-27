// actions/external_posts.js
import { FETCH_EXTERNAL_POSTS_SUCCESS } from './timelines';

export const fetchExternalPosts = (accountId, { maxId, withReplies, tagged }) => async dispatch => {
  
  console.log("fetchExternalPosts triggered", accountId, {withReplies});
  
  try {

    const newWithReplies = withReplies ?? false;
    const newTagged = tagged ?? false;

    const uriInput = maxId ? `/api/v1/fetch_external_posts?account_id=${accountId}&max_id=${maxId}&with_replies=${newWithReplies}&tagged=${newTagged}` : `/api/v1/fetch_external_posts?account_id=${accountId}&with_replies=${newWithReplies}&tagged=${newTagged}`

    const response = await fetch(uriInput, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
      },
    });

    if (!response.ok) {
      throw new Error('Network response was not ok');
    }

    const data = await response.json();

    dispatch({
      type: FETCH_EXTERNAL_POSTS_SUCCESS,
      payload: {
        accountId,
        posts: data.posts,
        hasMore: data.hasMore,
      },
    });
  } catch (error) {
    console.error('Failed to fetch external posts:', error);
  }
};