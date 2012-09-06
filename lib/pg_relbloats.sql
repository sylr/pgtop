-- vim: set tabstop=4 expandtab autoindent smartindent:
-- author: Greg Sabino Mullane <greg@endpoint.com>
-- date: 23/03/2011
-- copyright: BSD

-- THIS SOFTWARE IS PROVIDED BY THE AUTHOR "AS IS" AND ANY EXPRESS OR IMPLIED
-- WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
-- MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
-- EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
-- EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
-- OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
-- INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
-- CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
-- IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY
-- OF SUCH DAMAGE.

SELECT
    schemaname,
    tablename,
    reltuples::bigint,
    relpages::bigint,
    otta,
    ROUND(CASE WHEN otta = 0 THEN 0.0 ELSE sml.relpages / otta::numeric END, 1) AS tbloat,
    relpages::bigint - otta AS wastedpages,
    bs * (sml.relpages - otta)::bigint AS wastedbytes,
    pg_size_pretty((bs * (relpages - otta))::bigint) AS wastedsize,
    iname,
    ituples::bigint,
    ipages::bigint,
    iotta,
    ROUND(CASE WHEN iotta = 0 OR ipages = 0 THEN 0.0 ELSE ipages / iotta::numeric END, 1) AS ibloat,
    CASE WHEN ipages < iotta THEN 0 ELSE ipages::bigint - iotta END AS wastedipages,
    CASE WHEN ipages < iotta THEN 0 ELSE bs * (ipages - iotta) END AS wastedibytes,
    CASE WHEN ipages < iotta THEN pg_size_pretty(0) ELSE pg_size_pretty((bs * (ipages - iotta))::bigint) END AS wastedisize
FROM (
    SELECT
        schemaname,
        tablename,
        cc.reltuples,
        cc.relpages,
        bs,
        CEIL((cc.reltuples * ((datahdr + ma - (CASE WHEN datahdr % ma = 0 THEN ma ELSE datahdr % ma END)) + nullhdr2 + 4)) / (bs - 20::float)) AS otta,
        COALESCE(c2.relname, '?') AS iname,
        COALESCE(c2.reltuples, 0) AS ituples,
        COALESCE(c2.relpages, 0) AS ipages,
        COALESCE(CEIL((c2.reltuples * (datahdr - 12)) / (bs - 20::float)), 0) AS iotta -- very rough approximation, assumes all cols
    FROM (
        SELECT
            ma,
            bs,
            schemaname,
            tablename,
            (datawidth + (hdr + ma - (CASE WHEN hdr % ma=0 THEN ma ELSE hdr % ma END)))::numeric AS datahdr,
            (maxfracsum*(nullhdr+ma-(CASE WHEN nullhdr % ma=0 THEN ma ELSE nullhdr % ma END))) AS nullhdr2
        FROM (
            SELECT
                schemaname, tablename, hdr, ma, bs,
                SUM((1 - null_frac) * avg_width) AS datawidth,
                MAX(null_frac) AS maxfracsum,
                hdr + (SELECT 1 + count(*) / 8 FROM pg_stats s2 WHERE null_frac <> 0 AND s2.schemaname = s.schemaname AND s2.tablename = s.tablename) AS nullhdr
            FROM
                pg_stats s,
                (
                    SELECT
                    current_setting('block_size')::numeric AS bs,
                    CASE WHEN substring(v, 12, 3) IN ('8.0', '8.1', '8.2') THEN 27 ELSE 23 END AS hdr,
                    CASE WHEN v ~ 'mingw32' THEN 8 ELSE 4 END AS ma
                    FROM (SELECT version() AS v) AS foo
                ) AS constants
            GROUP BY 1,2,3,4,5
        ) AS foo
    ) AS rs
    JOIN pg_class cc ON cc.relname = rs.tablename
    JOIN pg_namespace nn ON cc.relnamespace = nn.oid AND nn.nspname = rs.schemaname
    LEFT JOIN pg_index i ON indrelid = cc.oid
    LEFT JOIN pg_class c2 ON c2.oid = i.indexrelid
    WHERE
        nn.nspname = 'public'
) AS sml
WHERE
    sml.relpages - otta > 0 OR ipages - iotta > 10
ORDER BY wastedbytes DESC, wastedibytes DESC;
