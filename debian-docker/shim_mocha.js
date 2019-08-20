#!/usr/bin/env node

// Runnable shims on the normal filesystem to get around noexec
// limitation on /dev/shm.

require("../node_modules/mocha/bin/mocha");
