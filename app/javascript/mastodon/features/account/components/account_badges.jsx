import PropTypes from 'prop-types';
import React from 'react';

const AccountBadges = ({ account }) => {

    // get the user id from the account object
    // const userId = account.get('id');

    const membershipLevel = account.get('membership_level');



    return (
        <div className='account-member'>
            {/* Existing badges rendering logic */}

            {/* Add membership level badge */}
            {membershipLevel === 10 && (
                <span className='badge membership-badge'>
                    <i className='fa fa-star' style={{ color: 'yellow' }} />
                    {" "}
                    {"Member"}
                </span>
            )}
            {membershipLevel === 20 && (
                <span className='badge membership-badge'>
                    <i className='fa fa-star' style={{ color: 'yellow' }} />
                    {" "}
                    {"Patron"}
                </span>
            )}
            {membershipLevel === 40 && (
                <span className='badge membership-badge'>
                    <i className='fa fa-star' style={{ color: 'yellow' }} />
                    {" "}
                    {"Sponsor"}
                </span>
            )}
            {membershipLevel > 40 && (
                <span className='badge membership-badge'>
                    <i className='fa fa-star' style={{ color: 'yellow' }} />
                    {" "}
                    {"SuperAdmin"}
                </span>
            )}

            {!membershipLevel && (
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