import PropTypes from 'prop-types';
import ImmutablePropTypes from 'react-immutable-proptypes';
import ImmutablePureComponent from 'react-immutable-pure-component';
import { debounce } from 'lodash';
import RegenerationIndicator from 'mastodon/components/regeneration_indicator';
import StatusContainer from '../containers/status_container';
import { LoadGap } from './load_gap';
import ScrollableList from './scrollable_list';
import * as Immutable from 'immutable';



export default class StatusList extends ImmutablePureComponent {

  static propTypes = {
    scrollKey: PropTypes.string.isRequired,
    statusIds: ImmutablePropTypes.list.isRequired,
    featuredStatusIds: ImmutablePropTypes.list,
    onLoadMore: PropTypes.func,
    onScrollToTop: PropTypes.func,
    onScroll: PropTypes.func,
    trackScroll: PropTypes.bool,
    isLoading: PropTypes.bool,
    isPartial: PropTypes.bool,
    hasMore: PropTypes.bool,
    prepend: PropTypes.node,
    emptyMessage: PropTypes.node,
    alwaysPrepend: PropTypes.bool,
    withCounters: PropTypes.bool,
    timelineId: PropTypes.string,
    lastId: PropTypes.string,
  };

  static defaultProps = {
    trackScroll: true,
  };

  constructor(props) {
    super(props);
    this.state = {
      orderedStatusIds: this.combineAndSortStatusIds(props.statusIds, props.featuredStatusIds),
    };
  }

  componentDidUpdate(prevProps) {
    if (
      this.props.statusIds !== prevProps.statusIds ||
      this.props.featuredStatusIds !== prevProps.featuredStatusIds
    ) {
      this.setState({
        orderedStatusIds: this.combineAndSortStatusIds(this.props.statusIds, this.props.featuredStatusIds),
      });
    }
  }

  combineAndSortStatusIds(statusIds = Immutable.List(), featuredStatusIds = Immutable.List()) {
    const filteredStatusIds = statusIds.filter(statusId => !featuredStatusIds.includes(statusId));
    //const sortedStatusIds = filteredStatusIds.sort((a, b) => a - b);
    const sortedStatusIds = filteredStatusIds;
    return featuredStatusIds.concat(sortedStatusIds);
  }

  getFeaturedStatusCount = () => {
    return this.props.featuredStatusIds ? this.props.featuredStatusIds.size : 0;
  };

  getCurrentStatusIndex = (id, featured) => {
    if (featured) {
      return this.props.featuredStatusIds.indexOf(id);
    } else {
      return this.props.statusIds.indexOf(id) + this.getFeaturedStatusCount();
    }
  };

  handleMoveUp = (id, featured) => {
    const elementIndex = this.getCurrentStatusIndex(id, featured) - 1;
    this._selectChild(elementIndex, true);
  };

  handleMoveDown = (id, featured) => {
    const elementIndex = this.getCurrentStatusIndex(id, featured) + 1;
    this._selectChild(elementIndex, false);
  };

  // handleLoadOlder = debounce(() => {
  //   const { statusIds, onLoadMore } = this.props;
  //   const maxId = statusIds.size > 0 ? Math.max(...statusIds.toArray()) : undefined;
  //   onLoadMore(maxId);
  // }, 300, { leading: true });

  handleLoadOlder = debounce(() => {
    const { statusIds, lastId, onLoadMore } = this.props;
    onLoadMore(lastId || (statusIds.size > 0 ? statusIds.last() : undefined));
  }, 300, { leading: true });

  reload = () => {
    console.log("Reloading...", this.props);
    const { statusIds, lastId, onLoadMore, accountId, accountUri, additionalPostsToCollect, authToken } = this.props;
    this.initialStatusCount = statusIds.size;

    // Define the endpoint and payload
    const endpoint = '/api/v1/external_feeds/fetch_posts';
    const payload = {
      account_id: accountId,
      account_uri: accountUri,
      additional_posts_to_collect: 25,
    };

    // Make the API call
    fetch(endpoint, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${authToken}`,
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content, // Assuming you're using Rails CSRF protection
      },
      body: JSON.stringify(payload),
    })
      .then(response => {
        if (response.ok) {
          console.log("Fetch initiated successfully.");
          return response.json();
        }
        throw new Error('Network response was not ok.');
      })
      .then(data => {
        console.log(data.message);
        this.startLoadingInterval();
      })
      .catch(error => {
        console.error("There was a problem with the fetch operation:", error);
      });
  };

  startLoadingInterval = () => {
    const { statusIds, onLoadMore } = this.props;

    this.loadInterval = setInterval(() => {
      console.log("Checking for new posts...", "Initial status count:", this.initialStatusCount, "Current status count:", statusIds.size);
      if (this.initialStatusCount !== this.props.statusIds.size) {
        clearInterval(this.loadInterval);
      } else {
        onLoadMore();
      }
    }, 5000);
  };

  // Make sure to clear the interval when the component unmounts
  componentWillUnmount() {
    if (this.loadInterval) {
      clearInterval(this.loadInterval);
    }
  }

  _selectChild(index, align_top) {
    const container = this.node.node;
    const element = container.querySelector(`article:nth-of-type(${index + 1}) .focusable`);

    if (element) {
      if (align_top && container.scrollTop > element.offsetTop) {
        element.scrollIntoView(true);
      } else if (!align_top && container.scrollTop + container.clientHeight < element.offsetTop + element.offsetHeight) {
        element.scrollIntoView(false);
      }
      element.focus();
    }
  }

  setRef = c => {
    this.node = c;
  };

  render() {
    const { statusIds, featuredStatusIds, onLoadMore, timelineId, ...other } = this.props;
    const { isLoading, isPartial } = other;

    console.log("StatusList props:", this.props);
    console.log("status state:", this.props.statusIds);

    if (isPartial) {
      return <RegenerationIndicator />;
    }

    let scrollableContent = (isLoading || statusIds.size > 0) ? (
      this.state.orderedStatusIds.map((statusId, index) => statusId === null ? (
        <LoadGap
          key={'gap:' + statusIds.get(index + 1)}
          disabled={isLoading}
          maxId={index > 0 ? statusIds.get(index - 1) : null}
          onClick={onLoadMore}
        />
      ) : (
        <StatusContainer
          key={statusId}
          id={statusId}
          onMoveUp={this.handleMoveUp}
          onMoveDown={this.handleMoveDown}
          contextType={timelineId}
          scrollKey={this.props.scrollKey}
          showThread
          withCounters={this.props.withCounters}
        />
      ))
    ) : null;

    if (scrollableContent && featuredStatusIds) {
      scrollableContent = featuredStatusIds.map(statusId => (
        <StatusContainer
          key={`f-${statusId}`}
          id={statusId}
          featured
          onMoveUp={this.handleMoveUp}
          onMoveDown={this.handleMoveDown}
          contextType={timelineId}
          showThread
          withCounters={this.props.withCounters}
        />
      )).concat(scrollableContent);
    }

    return (
      <ScrollableList {...other} fetchMoreRemote={this.reload} showLoading={isLoading && statusIds.size === 0} onLoadMore={onLoadMore && this.handleLoadOlder} ref={this.setRef}>
        {scrollableContent}
      </ScrollableList>
    );
  }
}