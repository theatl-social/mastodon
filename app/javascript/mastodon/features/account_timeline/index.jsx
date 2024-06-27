import PropTypes from 'prop-types';
import { FormattedMessage } from 'react-intl';
import { List as ImmutableList } from 'immutable';
import { Set as ImmutableSet } from 'immutable';
import ImmutablePropTypes from 'react-immutable-proptypes';
import ImmutablePureComponent from 'react-immutable-pure-component';
import { connect } from 'react-redux';
import { TimelineHint } from 'mastodon/components/timeline_hint';
import BundleColumnError from 'mastodon/features/ui/components/bundle_column_error';
import { me } from 'mastodon/initial_state';
import { normalizeForLookup } from 'mastodon/reducers/accounts_map';
import { getAccountHidden } from 'mastodon/selectors';
import { lookupAccount, fetchAccount, lookupAccountAsync } from '../../actions/accounts';
import { fetchFeaturedTags } from '../../actions/featured_tags';
import { expandAccountFeaturedTimeline, expandAccountTimeline, connectTimeline, disconnectTimeline } from '../../actions/timelines';
//import { fetchExternalPosts } from '../../actions/external_posts'; // New action import
import ColumnBackButton from '../../components/column_back_button';
import { LoadingIndicator } from '../../components/loading_indicator';
import StatusList from '../../components/status_list';
import Column from '../ui/components/column';
import LimitedAccountHint from './components/limited_account_hint';
import HeaderContainer from './containers/header_container';
import {createRef} from 'react';
const emptyList = ImmutableList();
import { useState } from 'react';

const mapStateToProps = (state, { params: { acct, id, tagged }, withReplies = false }) => {
  const accountId = id || state.getIn(['accounts_map', normalizeForLookup(acct)]);

  if (accountId === null) {
    return {
      isLoading: false,
      isAccount: false,
      statusIds: emptyList,
    };
  } else if (!accountId) {
    return {
      isLoading: true,
      statusIds: emptyList,
    };
  }

  const path = withReplies ? `${accountId}:with_replies` : `${accountId}${tagged ? `:${tagged}` : ''}`;

  return {
    accountId,
    remote: !!(state.getIn(['accounts', accountId, 'acct']) !== state.getIn(['accounts', accountId, 'username'])),
    remoteUrl: state.getIn(['accounts', accountId, 'url']),
    isAccount: !!state.getIn(['accounts', accountId]),
    statusIds: state.getIn(['timelines', `account:${path}`, 'items'], emptyList),
    featuredStatusIds: withReplies ? ImmutableList() : state.getIn(['timelines', `account:${accountId}:pinned${tagged ? `:${tagged}` : ''}`, 'items'], emptyList),
    isLoading: state.getIn(['timelines', `account:${path}`, 'isLoading']),
    hasMore: state.getIn(['timelines', `account:${path}`, 'hasMore']),
    suspended: state.getIn(['accounts', accountId, 'suspended'], false),
    hidden: getAccountHidden(state, accountId),
    blockedBy: state.getIn(['relationships', accountId, 'blocked_by'], false),
    withReplies: withReplies,
    tagged: tagged
  };
};



// if the user is on a remote profile and additional posts are available, this component will be displayed
const RemoteHint = ({ statusIds, handleLoadMore, reloadHandler }) => {
  const [isDisabled, setIsDisabled] = useState(false);
  const [buttonText, setButtonText] = useState('Request more posts');

  const handleClick = () => {
    setIsDisabled(true);
    setButtonText('Loading...');
    reloadHandler();

    const maxId = Math.max(...statusIds);

    handleLoadMore(maxId);

    setTimeout(() => {
      setIsDisabled(false);
      setButtonText('Request more posts');
    }, 10000);
  };

  return (
    <div style={{ display: 'flex', justifyContent: 'center', padding: '10px', margin: '10px' }}>
      <button
        className='button'
        onClick={handleClick}
        disabled={isDisabled}
      >
        {buttonText}
      </button>
    </div>
  );
};

RemoteHint.propTypes = {
  statusIds: PropTypes.arrayOf(PropTypes.number).isRequired,
  handleLoadMore: PropTypes.func.isRequired,
  reloadHandler: PropTypes.func.isRequired,
};

RemoteHint.propTypes = {
  reloadTimeline: PropTypes.func.isRequired,
};

class AccountTimeline extends ImmutablePureComponent {

  static propTypes = {
    params: PropTypes.shape({
      acct: PropTypes.string,
      id: PropTypes.string,
      tagged: PropTypes.string,
    }).isRequired,
    accountId: PropTypes.string,
    dispatch: PropTypes.func.isRequired,
    statusIds: ImmutablePropTypes.list,
    featuredStatusIds: ImmutablePropTypes.list,
    isLoading: PropTypes.bool,
    hasMore: PropTypes.bool,
    withReplies: PropTypes.bool,
    blockedBy: PropTypes.bool,
    isAccount: PropTypes.bool,
    suspended: PropTypes.bool,
    hidden: PropTypes.bool,
    remote: PropTypes.bool,
    remoteUrl: PropTypes.string,
    multiColumn: PropTypes.bool,
  };
  
  constructor(props) {
    super(props);
    this.statusListRef = createRef();
  }

  _load () {
    const { accountId, withReplies, params: { tagged }, dispatch } = this.props;

    dispatch(fetchAccount(accountId));

    if (!withReplies) {
      dispatch(expandAccountFeaturedTimeline(accountId, { tagged }));
    }

    dispatch(fetchFeaturedTags(accountId));
    dispatch(expandAccountTimeline(accountId, { withReplies, tagged }));

    if (accountId === me) {
      dispatch(connectTimeline(`account:${me}`));
    }
  }



  componentDidMount () {
    const { params: { acct }, accountId, statusIds, dispatch, remote, withReplies } = this.props;
    if (accountId) {
      this._load();
      if (remote && statusIds.isEmpty()) {
        this.handleLoadMore();
      }
    } else {

      // this is triggered if the account is brand new and we haven't seen it before

      dispatch(lookupAccount(acct));

    }
  }

  componentDidUpdate (prevProps) {
    const { params: { acct, tagged }, accountId, withReplies, dispatch } = this.props;

    if (prevProps.accountId !== accountId && accountId) {
      this._load();
    } else if (prevProps.params.acct !== acct) {
      dispatch(lookupAccount(acct));
    } else if (prevProps.params.tagged !== tagged) {
      if (!withReplies) {
        dispatch(expandAccountFeaturedTimeline(accountId, { tagged }));
      }
      dispatch(expandAccountTimeline(accountId, { withReplies, tagged }));
    }

    if (prevProps.accountId === me && accountId !== me) {
      dispatch(disconnectTimeline(`account:${me}`));
    }
  }

  componentWillUnmount () {
    const { dispatch, accountId } = this.props;

    if (accountId === me) {
      dispatch(disconnectTimeline(`account:${me}`));
    }
  }


  handleLoadMore = maxId => {
    this.props.dispatch(expandAccountTimeline(this.props.accountId, { maxId, withReplies: this.props.withReplies, tagged: this.props.params.tagged }));
  };

  reloadTimeline = () => {
    if (this.statusListRef.current) {
      this.statusListRef.current.reload();
    }
  }

  render () {
    const { accountId, statusIds, featuredStatusIds, isLoading, hasMore, blockedBy, suspended, isAccount, hidden, multiColumn, remote, remoteUrl, withReplies } = this.props;

    if (isLoading && statusIds.isEmpty()) {
      return (
        <Column>
          <LoadingIndicator />
        </Column>
      );
    } else if (!isLoading && !isAccount) {
      return (
        <BundleColumnError multiColumn={multiColumn} errorType='routing' />
      );
    }

    let emptyMessage;

    const forceEmptyState = suspended || blockedBy || hidden;

    if (suspended) {
      emptyMessage = <FormattedMessage id='empty_column.account_suspended' defaultMessage='Account suspended' />;
    } else if (hidden) {
      emptyMessage = <LimitedAccountHint accountId={accountId} />;
    } else if (blockedBy) {
      emptyMessage = <FormattedMessage id='empty_column.account_unavailable' defaultMessage='Profile unavailable' />;
    } else if (remote && statusIds.isEmpty()) {
      <></>
      // this is displayed if the account is remote and we have no posts from them yet
      //emptyMessage = <RemoteHint handleLoadMore={this.handleLoadMore} statusIds={this.props.statusIds} reloadHandler={this.reloadTimeline} />;
    } else {
      emptyMessage = <FormattedMessage id='empty_column.account_timeline' defaultMessage='No posts found' />;
    }

    const remoteMessage = <RemoteHint handleLoadMore={this.handleLoadMore} statusIds={this.props.statusIds} reloadHandler={this.reloadTimeline} />;;
    
    
    return (
      <Column>
        <ColumnBackButton multiColumn={multiColumn} />

        <StatusList
          ref={this.statusListRef}
          prepend={<HeaderContainer accountId={this.props.accountId} hideTabs={forceEmptyState} tagged={this.props.params.tagged} />}
          alwaysPrepend
          append={remoteMessage}
          scrollKey='account_timeline'
          statusIds={forceEmptyState ? emptyList : statusIds}
          featuredStatusIds={featuredStatusIds}
          isLoading={isLoading}
          hasMore={!forceEmptyState && hasMore}
          onLoadMore={this.handleLoadMore}
          emptyMessage={emptyMessage}
          bindToDocument={!multiColumn}
          timelineId='account'
          remote={remote}
          accountId={accountId} // Add the accountId prop here
          withReplies={withReplies}
          tagged={this.props.params.tagged}
        />
      </Column>
    );
  }

}

export default connect(mapStateToProps)(AccountTimeline);