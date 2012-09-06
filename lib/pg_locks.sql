-- vim: set tabstop=4 expandtab autoindent smartindent:
-- author: Sylvain Rabot <sylvain@abstraction.fr>
-- date: 23/03/2011
-- copyright: All rights reserved

SELECT
    pg_database.datname,
    pg_class.relname,
    pg_locks.locktype,
    pg_locks.mode,
    pg_locks.granted,
    pg_locks.pid,
    pg_locks.transactionid
FROM
    pg_locks
LEFT JOIN
    pg_class ON (pg_locks.relation = pg_class.oid)
LEFT JOIN
    pg_database ON (pg_locks.database = pg_database.oid)
WHERE
    datname IS NULL OR
    datname =  current_database()
ORDER BY
    datname,
    mode,
    relname,
    pid;
