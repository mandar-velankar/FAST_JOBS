const cds = require('@sap/cds')
const jobManager = require("./jobs/JobManager");

cds.on('served', async (services) => {
    jobManager.registerJobs();
});