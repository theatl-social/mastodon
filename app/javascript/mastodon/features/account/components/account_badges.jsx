import PropTypes from 'prop-types';
import React from 'react';

const AccountBadges = ({ account }) => {


    return (
        <div className='account-member'>
            {/* Existing badges rendering logic */}

            {/* Add membership level badge */}
            {account.get('membership_level') === 10 && (
                <span className='badge membership-badge'>
                    <i className='fa fa-star' style={{ color: 'yellow' }} />
                    {" "}
                    {"Member"}
                </span>
            )}
            {account.get('membership_level') === 20 && (
                <span className='badge membership-badge'>
                    <i className='fa fa-star' style={{ color: 'yellow' }} />
                    {" "}
                    {"Patron"}
                </span>
            )}
            {account.get('membership_level') === 40 && (
                <span className='badge membership-badge'>
                    <i className='fa fa-star' style={{ color: 'yellow' }} />
                    {" "}
                    {"Sponsor"}
                </span>
            )}
            {account.get('membership_level') > 40 && (
                <span className='badge membership-badge'>
                    <i className='fa fa-star' style={{ color: 'yellow' }} />
                    {" "}
                    {"SuperAdmin"}
                </span>
            )}

            {!account.get('membership_level') && (
                <span className='badge membership-badge'>
                    test
                </span>
            )}
        </div>
    );
};

AccountBadges.propTypes = {
    account: PropTypes.object.isRequired,
};

export default AccountBadges;