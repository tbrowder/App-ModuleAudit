use v6;

unit module App::ModuleAudit::DB;

use DBIish;

#sub connect-db(Str:D $db-path --> DBIish::Database:D) is export {
sub connect-db(Str:D $db-path) is export {
    return DBIish.connect('SQLite', :database($db-path));
}

#sub init-schema(DBIish::Database:D $dbh --> Nil) is export {
sub init-schema($dbh) is export {
    $dbh.do(q:to/SQL/);
CREATE TABLE IF NOT EXISTS module_identities (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    auth TEXT,
    api TEXT
)
SQL

    $dbh.do(q:to/SQL/);
CREATE UNIQUE INDEX IF NOT EXISTS idx_module_identities
ON module_identities (name, auth, api)
SQL

    $dbh.do(q:to/SQL/);
CREATE TABLE IF NOT EXISTS module_installations (
    id INTEGER PRIMARY KEY,
    module_id INTEGER NOT NULL,
    ver TEXT,
    dist TEXT,
    source TEXT,
    install_path TEXT,
    seen_at TEXT NOT NULL,
    installed INTEGER NOT NULL DEFAULT 1,
    latest_known_ver TEXT,
    upgrade_available INTEGER NOT NULL DEFAULT 0,
    FOREIGN KEY (module_id) REFERENCES module_identities(id)
)
SQL

    $dbh.do(q:to/SQL/);
CREATE INDEX IF NOT EXISTS idx_module_installations_module_id
ON module_installations (module_id)
SQL

    $dbh.do(q:to/SQL/);
CREATE INDEX IF NOT EXISTS idx_module_installations_seen_at
ON module_installations (seen_at)
SQL
}

sub find-or-create-module-id(
    #DBIish::Database:D $dbh,
    $dbh,
    Str:D $name,
    Str $auth = '',
    Str $api = ''
    --> Int:D
) is export {
    my $select-sth = $dbh.prepare(q:to/SQL/);
SELECT id
FROM module_identities
WHERE name = ? AND auth IS ? AND api IS ?
SQL

    $select-sth.execute($name, $auth, $api);
    my @row = $select-sth.row;

    if @row {
        return @row[0].Int;
    }

    my $insert-sth = $dbh.prepare(q:to/SQL/);
INSERT INTO module_identities (name, auth, api)
VALUES (?, ?, ?)
SQL

    $insert-sth.execute($name, $auth, $api);

    $select-sth.execute($name, $auth, $api);
    my @id-row = $select-sth.row;

    return @id-row[0].Int;
}

sub insert-installation(
    $dbh,
    Int:D $module-id,
    Str:D $ver,
    Str:D $dist,
    Str:D $source,
    Str:D $install-path,
    Str:D $seen-at,
    Bool:D :$installed = True,
    Str:D :$latest-known-ver = '',
    Bool:D :$upgrade-available = False,
) is export {
    my $sth = $dbh.prepare(q:to/SQL/);
INSERT INTO module_installations (
    module_id,
    ver,
    dist,
    source,
    install_path,
    seen_at,
    installed,
    latest_known_ver,
    upgrade_available
)
VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
SQL

    $sth.execute(
        $module-id,
        $ver,
        $dist,
        $source,
        $install-path,
        $seen-at,
        $installed ?? 1 !! 0,
        $latest-known-ver,
        $upgrade-available ?? 1 !! 0,
    );
}

sub load-current-installations(
    #DBIish::Database:D $dbh
    $dbh
    --> Array
) is export {
    my $sth = $dbh.prepare(q:to/SQL/);
SELECT
    mi.name,
    mi.auth,
    mi.api,
    ins.ver,
    ins.dist,
    ins.source,
    ins.install_path,
    ins.installed,
    ins.latest_known_ver,
    ins.upgrade_available,
    ins.seen_at
FROM module_installations ins
JOIN module_identities mi
    ON mi.id = ins.module_id
WHERE ins.id IN (
    SELECT MAX(ins2.id)
    FROM module_installations ins2
    JOIN module_identities mi2
        ON mi2.id = ins2.module_id
    WHERE ins2.installed = 1
    GROUP BY mi2.name, mi2.auth, mi2.api
)
AND ins.installed = 1
ORDER BY mi.name, mi.auth, mi.api
SQL

    $sth.execute();

    my Hash:D @rows;

    loop {
        my @row = $sth.row;
        last if not @row;

        @rows.push(
            {
                name               => @row[0],
                auth               => @row[1],
                api                => @row[2],
                ver                => @row[3],
                dist               => @row[4],
                source             => @row[5],
                install-path       => @row[6],
                installed          => @row[7] ?? True !! False,
                latest-known-ver   => @row[8],
                upgrade-available  => @row[9] ?? True !! False,
                seen-at            => @row[10],
            }
        );
    }

    return @rows.Array;
}
