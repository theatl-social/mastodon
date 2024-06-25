import PropTypes from 'prop-types';
import ImmutablePropTypes from 'react-immutable-proptypes';
import ImmutablePureComponent from 'react-immutable-pure-component';
import { Set as ImmutableSet } from 'immutable';
import { connect } from 'react-redux'; // Import connect for Redux
import { debounce } from 'lodash';
import RegenerationIndicator from 'mastodon/components/regeneration_indicator';
import { fetchExternalPosts } from '../actions/external_posts'; // Ensure the action is imported
import StatusContainer from '../containers/status_container';
import { LoadGap } from './load_gap';
import ScrollableList from './scrollable_list';

class StatusList extends ImmutablePureComponent {

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
    dispatch: PropTypes.func.isRequired, // Add dispatch to props
    accountId: PropTypes.string.isRequired, // Add accountId to props
    withReplies: PropTypes.bool,
    tagged: PropTypes.string,
    remote: PropTypes.bool, // Add remote to props
  };


  constructor(props) {
    super(props);
    this.fetchCache = ImmutableSet(); // Initialize fetchCache as an ImmutableSet
  }

  addToCache = (cacheKey) => {
    this.fetchCache = this.fetchCache.add(cacheKey);
  }

  checkInCache = (cacheKey) => {
    return this.fetchCache.has(cacheKey);
  }

  static defaultProps = {
    trackScroll: true,
  };

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
    console.log("handle move up triggered")
    const elementIndex = this.getCurrentStatusIndex(id, featured) - 1;
    this._selectChild(elementIndex, true);
  };

  handleMoveDown = (id, featured) => {
    console.log("handleMoveDown Triggered")
    const elementIndex = this.getCurrentStatusIndex(id, featured) + 1;
    this._selectChild(elementIndex, false);
  };

  fetchMoreExternalPosts = async (maxId) => {

    const cacheKey = `${accountId}-${maxId}`;
    if (this.checkInCache(cacheKey)) {
      return;
    }

    this.addToCache(cacheKey);

    const { accountId, withReplies, tagged, dispatch } = this.props;
    console.log("props", this.props);
    console.log("fetch external posts triggered", accountId, maxId, withReplies, tagged);
    try {
      dispatch(fetchExternalPosts(accountId, { maxId, withReplies, tagged }));
    } catch (error) {
      console.error('Failed to fetch external posts:', error);
    }
  };

  handleLoadOlder = debounce(() => {
    const { statusIds,  onLoadMore, hasMore, remote } = this.props;
    console.log("handle load older triggered");
    
    const lastId = statusIds.size > 0 ? statusIds.last() : null; 

    console.log("last id is", lastId);
    
    if (!hasMore && remote) {
      this.fetchMoreExternalPosts(lastId);
    } else {
      onLoadMore(lastId || (statusIds.size > 0 ? statusIds.last() : undefined));
    }
  }, 300, { leading: true });

  _selectChild = (index, alignTop) => {
    const container = this.node.node;
    const element = container.querySelector(`article:nth-of-type(${index + 1}) .focusable`);

    if (element) {
      if (alignTop && container.scrollTop > element.offsetTop) {
        element.scrollIntoView(true);
      } else if (!alignTop && container.scrollTop + container.clientHeight < element.offsetTop + element.offsetHeight) {
        element.scrollIntoView(false);
      }
      element.focus();
    }
  };

  setRef = c => {
    this.node = c;
  };

  render() {
    const { statusIds, featuredStatusIds, onLoadMore, timelineId, ...other } = this.props;
    const { isLoading, isPartial } = other;

    if (isPartial) {
      return <RegenerationIndicator />;
    }

    let scrollableContent = (isLoading || statusIds.size > 0) ? (
      statusIds.map((statusId, index) => statusId === null ? (
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
      <ScrollableList {...other} showLoading={isLoading && statusIds.size === 0} onLoadMore={onLoadMore && this.handleLoadOlder} ref={this.setRef}>
        {scrollableContent}
      </ScrollableList>
    );
  }

}

export default connect()(StatusList); // Ensure the component is connected to Redux