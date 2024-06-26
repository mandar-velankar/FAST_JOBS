/*
  This model controls what gets deployed to the database.
*/
namespace com.bayer.SXTENDER;

// 1) The persistence data model
using from './MasterData';
using from './MasterDataLatestValues';
using from './MasterDataViews';
using from './AdminData';
using from './AdminDataViews';
using from './TransactionalData';
using from './TransactionalDataViews';
using from './IntegrationData';
using from './SAP';

// 2) In addition, generic service providers need views for exposed entities

// using from '../srv/cat-service';