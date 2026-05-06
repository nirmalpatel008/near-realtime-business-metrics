-- ACT 1: prove we are on RDS MySQL and that binlog is correctly configured.
-- Run against SOURCE.

SELECT @@version AS mysql_version, @@hostname AS host;

-- The four settings DMS CDC depends on:
SHOW VARIABLES WHERE Variable_name IN (
  'log_bin',             -- must be ON
  'binlog_format',       -- must be ROW
  'binlog_row_image',    -- must be Full
  'binlog_checksum'      -- must be NONE
);

-- Aurora/RDS-specific: binlog retention should be >= 24h. Set via stored proc.
-- (Safe to run; idempotent.)
CALL mysql.rds_set_configuration('binlog retention hours', 24);
CALL mysql.rds_show_configuration;
