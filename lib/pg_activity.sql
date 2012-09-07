-- vim: set tabstop=4 expandtab autoindent smartindent:
-- author: Sylvain Rabot <sylvain@abstraction.fr>
-- date: 08/06/2011
-- copyright: All rights reserved

SELECT
    datname,
    procpid,
    usename,
    client_addr,
    waiting AS wait,
    date_trunc('second', now() - query_start) AS duration,
    current_query
FROM
    pg_stat_activity
WHERE
    procpid != pg_backend_pid()
ORDER BY
    duration DESC;
