
import { injectIntl, defineMessages } from 'react-intl';

import { connect } from 'react-redux';

import React, { useState } from 'react';

import { changeComposeIsFederated } from '../../../actions/compose';

const messages = defineMessages({
  federated: { id: 'status.federated', defaultMessage: 'Federate this post' },
  not_federated: { id: 'status.not_federated', defaultMessage: 'Local only' },
});


const IsFederatedSVG = () => {

  return (
    <svg xmlns="http://www.w3.org/2000/svg" width="22px" height="22px" viewBox="0 0 196.52 196.52">
      <path fill="#a730b8" d="M47.9242 72.7966a18.2278 18.2278 0 0 1-7.7959 7.7597l42.7984 42.9653 10.3182-5.2291zm56.4524 56.6704-10.3182 5.2291 21.686 21.7708a18.2278 18.2278 0 0 1 7.7975-7.7608z" />
      <path fill="#5496be" d="M129.6645 102.0765l1.7865 11.4272 27.4149-13.8942a18.2278 18.2278 0 0 1-4.9719-9.8124zm-14.0658 7.1282-57.2891 29.0339a18.2278 18.2278 0 0 1 4.9728 9.8133l54.1027-27.4194z" />
      <path fill="#ce3d1a" d="M69.5312 91.6539l8.1618 8.1933 29.269-57.1387a18.2278 18.2278 0 0 1-9.787-5.0219zm-7.1897 14.0363-14.0022 27.3353a18.2278 18.2278 0 0 1 9.786 5.0214l12.3775-24.1639z" />
      <path fill="#d0188f" d="M39.8906 80.6763a18.2278 18.2278 0 0 1-10.8655 1.7198l8.1762 52.2981a18.2278 18.2278 0 0 1 10.8645-1.7198z" />
      <path fill="#5b36e9" d="M63.3259 148.3109a18.2278 18.2278 0 0 1-1.7322 10.8629l52.2893 8.3907a18.2278 18.2278 0 0 1 1.7322-10.8629z" />
      <path fill="#30b873" d="M134.9148 146.9182a18.2278 18.2278 0 0 1 9.788 5.0224l24.1345-47.117a18.2278 18.2278 0 0 1-9.7875-5.0229z" />
      <path fill="#ebe305" d="M126.1329 33.1603a18.2278 18.2278 0 0 1-7.7975 7.7608l37.3765 37.5207a18.2278 18.2278 0 0 1 7.7969-7.7608z" />
      <path fill="#f47601" d="M44.7704 51.6279a18.2278 18.2278 0 0 1 4.9723 9.8123l47.2478-23.9453a18.2278 18.2278 0 0 1-4.9718-9.8113z" />
      <path fill="#57c115" d="M118.2491 40.9645a18.2278 18.2278 0 0 1-10.8511 1.8123l4.1853 26.8 11.42 1.8324zm-4.2333 44.1927 9.8955 63.3631a18.2278 18.2278 0 0 1 10.88-1.6278l-9.355-59.9035z" />
      <path fill="#dbb210" d="M49.7763 61.6412a18.2278 18.2278 0 0 1-1.694 10.8686l26.8206 4.3077 5.2715-10.2945zm45.9677 7.382-5.272 10.2955 63.3713 10.1777a18.2278 18.2278 0 0 1 1.7606-10.8593z" />
      <path fill="#ffca00" d="M93.4385 23.8419a1 1 0 1 0 33.0924 1.8025 1 1 0 1 0-33.0924-1.8025" />
      <path fill="#64ff00" d="M155.314 85.957a1 1 0 1 0 33.0923 1.8025 1 1 0 1 0-33.0923-1.8025" />
      <path fill="#00a3ff" d="M115.3466 163.9824a1 1 0 1 0 33.0923 1.8025 1 1 0 1 0-33.0923-1.8025" />
      <path fill="#9500ff" d="M28.7698 150.0898a1 1 0 1 0 33.0923 1.8025 1 1 0 1 0-33.0923-1.8025" />
      <path fill="#ff0000" d="M15.2298 63.4781a1 1 0 1 0 33.0923 1.8025 1 1 0 1 0-33.0923-1.8025" />
    </svg>
  )

}

const NotFederatedSVG = () => {
  return (
    <svg xmlns="http://www.w3.org/2000/svg" width="22px" height="22px" viewBox="0 0 196.52 196.52">
      <path fill="#000000" d="M47.9242 72.7966a18.2278 18.2278 0 0 1-7.7959 7.7597l42.7984 42.9653 10.3182-5.2291zm56.4524 56.6704-10.3182 5.2291 21.686 21.7708a18.2278 18.2278 0 0 1 7.7975-7.7608z" />
      <path fill="#A9A9A9" d="M129.6645 102.0765l1.7865 11.4272 27.4149-13.8942a18.2278 18.2278 0 0 1-4.9719-9.8124zm-14.0658 7.1282-57.2891 29.0339a18.2278 18.2278 0 0 1 4.9728 9.8133l54.1027-27.4194z" />
      <path fill="#B0B0B0" d="M69.5312 91.6539l8.1618 8.1933 29.269-57.1387a18.2278 18.2278 0 0 1-9.787-5.0219zm-7.1897 14.0363-14.0022 27.3353a18.2278 18.2278 0 0 1 9.786 5.0214l12.3775-24.1639z" />
      <path fill="#C0C0C0" d="M39.8906 80.6763a18.2278 18.2278 0 0 1-10.8655 1.7198l8.1762 52.2981a18.2278 18.2278 0 0 1 10.8645-1.7198z" />
      <path fill="#D3D3D3" d="M63.3259 148.3109a18.2278 18.2278 0 0 1-1.7322 10.8629l52.2893 8.3907a18.2278 18.2278 0 0 1 1.7322-10.8629z" />
      <path fill="#DCDCDC" d="M134.9148 146.9182a18.2278 18.2278 0 0 1 9.788 5.0224l24.1345-47.117a18.2278 18.2278 0 0 1-9.7875-5.0229z" />
      <path fill="#E8E8E8" d="M126.1329 33.1603a18.2278 18.2278 0 0 1-7.7975 7.7608l37.3765 37.5207a18.2278 18.2278 0 0 1 7.7969-7.7608z" />
      <path fill="#F5F5F5" d="M44.7704 51.6279a18.2278 18.2278 0 0 1 4.9723 9.8123l47.2478-23.9453a18.2278 18.2278 0 0 1-4.9718-9.8113z" />
      <path fill="#D3D3D3" d="M118.2491 40.9645a18.2278 18.2278 0 0 1-10.8511 1.8123l4.1853 26.8 11.42 1.8324zm-4.2333 44.1927 9.8955 63.3631a18.2278 18.2278 0 0 1 10.88-1.6278l-9.355-59.9035z" />
      <path fill="#E0E0E0" d="M49.7763 61.6412a18.2278 18.2278 0 0 1-1.694 10.8686l26.8206 4.3077 5.2715-10.2945zm45.9677 7.382-5.272 10.2955 63.3713 10.1777a18.2278 18.2278 0 0 1 1.7606-10.8593z" />
      <path fill="#E8E8E8" d="M93.4385 23.8419a1 1 0 1 0 33.0924 1.8025 1 1 0 1 0-33.0924-1.8025" />
      <path fill="#D8D8D8" d="M155.314 85.957a1 1 0 1 0 33.0923 1.8025 1 1 0 1 0-33.0923-1.8025" />
      <path fill="#C0C0C0" d="M115.3466 163.9824a1 1 0 1 0 33.0923 1.8025 1 1 0 1 0-33.0923-1.8025" />
      <path fill="#A9A9A9" d="M28.7698 150.0898a1 1 0 1 0 33.0923 1.8025 1 1 0 1 0-33.0923-1.8025" />
      <path fill="#808080" d="M15.2298 63.4781a1 1 0 1 0 33.0923 1.8025 1 1 0 1 0-33.0923-1.8025" />

      {/* Red X */}
      <circle cx="98.26" cy="98.26" r="90" fill="none" stroke="red" strokeWidth="20" />
      <line x1="40" y1="40" x2="156.52" y2="156.52" stroke="red" strokeWidth="20" />
    </svg>
  );
};



// const messages = defineMessages({
//   marked: { id: 'compose_form.spoiler.marked', defaultMessage: 'Text is hidden behind warning' },
//   unmarked: { id: 'compose_form.spoiler.unmarked', defaultMessage: 'Text is not hidden' },
// });


// create a new component that will render the SVG based on the state of the compose form
// 1. If the form is federated, render the federated SVG
// 2. If the form is not federated, render the not federated SVGconst IsFederatedSelection = ({ isFederated, onClick, title }) => {
  const IsFederatedSelection = ({ isFederated, onClick, title }) => {
  const [isHovered, setIsHovered] = useState(false);

  return (
    <div
      onClick={onClick}
      title={title}
      aria-label={title}
      onMouseEnter={() => setIsHovered(true)}
      onMouseLeave={() => setIsHovered(false)}
      style={{
        display: 'inline-block',
        padding: '1px',
        marginLeft: '2px',
        borderRadius: '5px',
        cursor: 'pointer',
        backgroundColor: isHovered ? 'rgba(17, 17, 17, 0.3)' : 'transparent',
        transition: 'background-color 0.3s'
      }}
    >
      {isFederated ? <IsFederatedSVG /> : <NotFederatedSVG />}
    </div>
  );
};

const mapStateToProps = (state, { intl }) => ({
  isFederated: state.getIn(['compose', 'is_federated']),
  title: intl.formatMessage(state.getIn(['compose', 'is_federated']) ? messages.federated : messages.not_federated),
});

const mapDispatchToProps = (dispatch) => ({
  onClick: () => dispatch(changeComposeIsFederated()),
});

export default injectIntl(connect(mapStateToProps, mapDispatchToProps)(IsFederatedSelection));